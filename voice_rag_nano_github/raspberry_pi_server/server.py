#!/usr/bin/env python3
"""
🖥️ Raspberry Pi 5 Voice RAG Server

ESP32에서 음성을 받아 AI 답변을 생성하고 음성으로 반환합니다.

구성:
- Flask: HTTP 서버
- Whisper: 음성 인식 (STT)
- Ollama + RAG: AI 답변 생성
- Edge-TTS: 음성 합성 (TTS)

실행:
    python server.py

테스트:
    curl http://localhost:5000/health
"""

import os
import io
import wave
import time
import logging
import tempfile
import asyncio
from pathlib import Path
from flask import Flask, request, jsonify, send_file
import numpy as np

# =====================================
# 📝 로깅 설정
# =====================================
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%H:%M:%S'
)
logger = logging.getLogger(__name__)

# =====================================
# ⚙️ 설정
# =====================================
class Config:
    # 서버
    HOST = '0.0.0.0'
    PORT = 5000
    
    # 오디오 (ESP32와 일치)
    SAMPLE_RATE = 16000
    SAMPLE_WIDTH = 2  # 16-bit
    CHANNELS = 1
    
    # 경로
    DOCUMENTS_DIR = Path('./documents')
    
    # Ollama
    OLLAMA_MODEL = 'llama3.2'
    OLLAMA_URL = 'http://localhost:11434'
    
    # Whisper
    WHISPER_MODEL = 'base'  # tiny, base, small, medium, large
    
    # TTS
    TTS_VOICE_KO = 'ko-KR-SunHiNeural'   # 한국어 여성
    TTS_VOICE_EN = 'en-US-JennyNeural'    # 영어 여성
    TTS_LANGUAGE = 'ko'  # 기본 언어

# =====================================
# 🌐 Flask 앱
# =====================================
app = Flask(__name__)

# =====================================
# 🎤 음성 인식 (Whisper)
# =====================================
class SpeechRecognizer:
    def __init__(self, model_name='base'):
        logger.info(f"Loading Whisper model: {model_name}")
        import whisper
        self.model = whisper.load_model(model_name)
        logger.info("Whisper model loaded!")
    
    def transcribe(self, audio_data: bytes) -> str:
        """음성을 텍스트로 변환"""
        # 임시 파일로 저장
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
            f.write(audio_data)
            temp_path = f.name
        
        try:
            result = self.model.transcribe(
                temp_path,
                language=Config.TTS_LANGUAGE,
                fp16=False  # Raspberry Pi에서는 fp32 사용
            )
            text = result['text'].strip()
            logger.info(f"STT: '{text}'")
            return text
        finally:
            os.unlink(temp_path)

# =====================================
# 🔊 음성 합성 (Edge-TTS)
# =====================================
class SpeechSynthesizer:
    def __init__(self, language='ko'):
        self.language = language
        self.voice = Config.TTS_VOICE_KO if language == 'ko' else Config.TTS_VOICE_EN
        logger.info(f"TTS initialized: {self.voice}")
    
    async def _synthesize_async(self, text: str) -> bytes:
        """비동기 음성 합성"""
        import edge_tts
        
        communicate = edge_tts.Communicate(text, self.voice)
        audio_data = b""
        
        async for chunk in communicate.stream():
            if chunk["type"] == "audio":
                audio_data += chunk["data"]
        
        return audio_data
    
    def synthesize(self, text: str) -> bytes:
        """텍스트를 음성으로 변환 (WAV 반환)"""
        logger.info(f"TTS: '{text[:50]}...'")
        
        # 비동기 실행
        mp3_data = asyncio.run(self._synthesize_async(text))
        
        # MP3 → WAV 변환
        wav_data = self._mp3_to_wav(mp3_data)
        
        return wav_data
    
    def _mp3_to_wav(self, mp3_data: bytes) -> bytes:
        """MP3를 WAV로 변환"""
        from pydub import AudioSegment
        
        audio = AudioSegment.from_mp3(io.BytesIO(mp3_data))
        audio = audio.set_frame_rate(Config.SAMPLE_RATE)
        audio = audio.set_channels(Config.CHANNELS)
        audio = audio.set_sample_width(Config.SAMPLE_WIDTH)
        
        wav_buffer = io.BytesIO()
        audio.export(wav_buffer, format='wav')
        wav_buffer.seek(0)
        
        return wav_buffer.read()

# =====================================
# 🤖 RAG 엔진
# =====================================
class RAGEngine:
    def __init__(self, docs_dir: Path, model: str, ollama_url: str):
        self.docs_dir = docs_dir
        self.model = model
        self.ollama_url = ollama_url
        
        self.documents = []
        self.embeddings = None
        self.embedding_model = None
        
        self._load_embedding_model()
        self._load_documents()
        
        logger.info(f"RAG Engine ready: {len(self.documents)} documents")
    
    def _load_embedding_model(self):
        """임베딩 모델 로드"""
        from sentence_transformers import SentenceTransformer
        logger.info("Loading embedding model...")
        self.embedding_model = SentenceTransformer(
            'paraphrase-multilingual-MiniLM-L12-v2'
        )
    
    def _load_documents(self):
        """문서 로드 및 인덱싱"""
        self.docs_dir.mkdir(exist_ok=True)
        
        # 지원 확장자
        extensions = ['.txt', '.md']
        
        for ext in extensions:
            for file_path in self.docs_dir.glob(f'**/*{ext}'):
                try:
                    content = file_path.read_text(encoding='utf-8')
                    chunks = self._chunk_text(content)
                    
                    for chunk in chunks:
                        self.documents.append({
                            'content': chunk,
                            'source': file_path.name
                        })
                    
                    logger.info(f"Loaded: {file_path.name} ({len(chunks)} chunks)")
                except Exception as e:
                    logger.error(f"Failed to load {file_path}: {e}")
        
        # 샘플 문서가 없으면 생성
        if not self.documents:
            self._create_sample_doc()
        
        # 임베딩 생성
        if self.documents:
            texts = [d['content'] for d in self.documents]
            self.embeddings = self.embedding_model.encode(texts)
            logger.info(f"Created {len(self.embeddings)} embeddings")
    
    def _chunk_text(self, text: str, chunk_size: int = 500) -> list:
        """텍스트를 청크로 분할"""
        chunks = []
        start = 0
        
        while start < len(text):
            end = start + chunk_size
            chunk = text[start:end]
            
            # 문장 경계에서 자르기
            if end < len(text):
                for sep in ['. ', '.\n', '\n\n', '\n']:
                    last = chunk.rfind(sep)
                    if last > chunk_size // 2:
                        chunk = text[start:start + last + len(sep)]
                        end = start + last + len(sep)
                        break
            
            if chunk.strip():
                chunks.append(chunk.strip())
            
            start = end
        
        return chunks
    
    def _create_sample_doc(self):
        """샘플 문서 생성"""
        sample = self.docs_dir / 'guide.txt'
        sample.write_text('''# Voice RAG 시스템 가이드

이 시스템은 음성으로 질문하면 AI가 답변해주는 시스템입니다.

## 사용 방법
1. ESP32의 버튼을 누르세요
2. 마이크에 대고 질문하세요
3. 버튼을 놓으면 AI가 답변합니다

## 기능
- 음성 인식 (한국어/영어)
- 문서 기반 답변 (RAG)
- 음성 합성

## 문서 추가
documents 폴더에 .txt 또는 .md 파일을 추가하면
AI가 해당 내용을 참고하여 답변합니다.
''', encoding='utf-8')
        
        logger.info("Created sample document")
        self._load_documents()
    
    def search(self, query: str, top_k: int = 3) -> list:
        """관련 문서 검색"""
        if not self.documents or self.embeddings is None:
            return []
        
        query_emb = self.embedding_model.encode([query])[0]
        
        # 코사인 유사도
        similarities = np.dot(self.embeddings, query_emb) / (
            np.linalg.norm(self.embeddings, axis=1) * np.linalg.norm(query_emb)
        )
        
        top_idx = np.argsort(similarities)[::-1][:top_k]
        
        results = []
        for idx in top_idx:
            if similarities[idx] > 0.3:  # 임계값
                results.append({
                    'content': self.documents[idx]['content'],
                    'source': self.documents[idx]['source'],
                    'score': float(similarities[idx])
                })
        
        return results
    
    def generate_response(self, query: str) -> str:
        """질문에 대한 응답 생성"""
        import requests
        
        # 관련 문서 검색
        relevant_docs = self.search(query)
        
        # 컨텍스트 구성
        context = ""
        if relevant_docs:
            context = "\n\n".join([
                f"[{d['source']}]\n{d['content']}"
                for d in relevant_docs
            ])
            logger.info(f"Found {len(relevant_docs)} relevant documents")
        
        # 프롬프트 구성
        if context:
            prompt = f"""다음 참고자료를 바탕으로 질문에 답변해주세요.
답변은 2-3문장으로 짧고 명확하게 해주세요.

참고자료:
{context}

질문: {query}

답변:"""
        else:
            prompt = f"""질문에 2-3문장으로 짧고 명확하게 답변해주세요.

질문: {query}

답변:"""
        
        # Ollama 호출
        try:
            response = requests.post(
                f"{self.ollama_url}/api/generate",
                json={
                    "model": self.model,
                    "prompt": prompt,
                    "stream": False,
                    "options": {
                        "temperature": 0.7,
                        "num_predict": 150
                    }
                },
                timeout=60
            )
            
            if response.status_code == 200:
                answer = response.json().get('response', '').strip()
                logger.info(f"LLM Response: '{answer[:100]}...'")
                return answer
            else:
                logger.error(f"Ollama error: {response.status_code}")
                return "죄송합니다, 답변을 생성하는데 문제가 발생했습니다."
                
        except requests.exceptions.ConnectionError:
            logger.error("Cannot connect to Ollama")
            return "AI 서버에 연결할 수 없습니다. Ollama가 실행 중인지 확인해주세요."
        except Exception as e:
            logger.error(f"Ollama error: {e}")
            return "오류가 발생했습니다."

# =====================================
# 🔧 전역 객체
# =====================================
stt: SpeechRecognizer = None
tts: SpeechSynthesizer = None
rag: RAGEngine = None

# =====================================
# 🌐 API 엔드포인트
# =====================================

@app.route('/voice', methods=['POST'])
def process_voice():
    """음성 처리 메인 API"""
    start_time = time.time()
    
    try:
        # 1. 오디오 데이터 수신
        audio_data = request.data
        if not audio_data:
            return jsonify({'error': 'No audio data'}), 400
        
        logger.info(f"Received {len(audio_data)} bytes")
        
        # 2. WAV 형식으로 변환
        wav_data = raw_to_wav(audio_data)
        
        # 3. 음성 인식
        text = stt.transcribe(wav_data)
        if not text:
            text = "인식된 내용이 없습니다"
        
        # 4. AI 응답 생성
        response_text = rag.generate_response(text)
        
        # 5. 음성 합성
        response_audio = tts.synthesize(response_text)
        
        elapsed = time.time() - start_time
        logger.info(f"Total processing time: {elapsed:.2f}s")
        
        # 6. WAV 응답
        return send_file(
            io.BytesIO(response_audio),
            mimetype='audio/wav'
        )
        
    except Exception as e:
        logger.error(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


@app.route('/text', methods=['POST'])
def process_text():
    """텍스트 API (테스트용)"""
    try:
        data = request.json
        text = data.get('text', '')
        
        if not text:
            return jsonify({'error': 'No text'}), 400
        
        response = rag.generate_response(text)
        
        return jsonify({
            'question': text,
            'answer': response
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/health', methods=['GET'])
def health():
    """상태 확인"""
    return jsonify({
        'status': 'healthy',
        'stt': stt is not None,
        'tts': tts is not None,
        'rag': rag is not None,
        'documents': len(rag.documents) if rag else 0
    })


@app.route('/documents', methods=['GET'])
def list_documents():
    """문서 목록"""
    if not rag:
        return jsonify({'documents': []})
    
    sources = list(set(d['source'] for d in rag.documents))
    return jsonify({'documents': sources})


@app.route('/documents/reload', methods=['POST'])
def reload_documents():
    """문서 다시 로드"""
    try:
        rag._load_documents()
        return jsonify({
            'status': 'success',
            'documents': len(rag.documents)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# =====================================
# 🔧 유틸리티
# =====================================

def raw_to_wav(raw_data: bytes) -> bytes:
    """Raw PCM → WAV 변환"""
    wav_buffer = io.BytesIO()
    
    with wave.open(wav_buffer, 'wb') as wav:
        wav.setnchannels(Config.CHANNELS)
        wav.setsampwidth(Config.SAMPLE_WIDTH)
        wav.setframerate(Config.SAMPLE_RATE)
        wav.writeframes(raw_data)
    
    wav_buffer.seek(0)
    return wav_buffer.read()


def initialize():
    """서버 초기화"""
    global stt, tts, rag
    
    logger.info("="*50)
    logger.info("  Voice RAG Server Initializing...")
    logger.info("="*50)
    
    # STT
    logger.info("\n[1/3] Loading Speech Recognition...")
    stt = SpeechRecognizer(Config.WHISPER_MODEL)
    
    # TTS  
    logger.info("\n[2/3] Loading Speech Synthesis...")
    tts = SpeechSynthesizer(Config.TTS_LANGUAGE)
    
    # RAG
    logger.info("\n[3/3] Loading RAG Engine...")
    rag = RAGEngine(Config.DOCUMENTS_DIR, Config.OLLAMA_MODEL, Config.OLLAMA_URL)
    
    logger.info("\n" + "="*50)
    logger.info("  Server Ready!")
    logger.info("="*50)

# =====================================
# 🚀 메인
# =====================================
if __name__ == '__main__':
    print("""
╔═══════════════════════════════════════════╗
║     🎤 Voice RAG Server                   ║
║     for ESP32-S3 Nano                     ║
║     Raspberry Pi 5                        ║
╚═══════════════════════════════════════════╝
    """)
    
    initialize()
    
    print(f"\n🌐 Server: http://0.0.0.0:{Config.PORT}")
    print(f"📍 Set this IP in ESP32 config.h")
    print(f"🛑 Stop: Ctrl+C\n")
    
    app.run(
        host=Config.HOST,
        port=Config.PORT,
        debug=False,
        threaded=True
    )
