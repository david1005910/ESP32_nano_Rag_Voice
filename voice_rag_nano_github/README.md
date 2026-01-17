# 🎤 ESP32-S3 Nano Voice RAG System

음성으로 질문하면 AI가 답변해주는 스마트 디바이스입니다.

## 📦 구성품

| 역할 | 하드웨어 |
|------|----------|
| **클라이언트** | ESP32-S3 Nano + GC9A01 LCD + INMP441 + MAX98357A |
| **서버** | Raspberry Pi 5 + Ollama (llama3.2) |

## 🎯 시스템 동작

```
[버튼 누름] → [음성 녹음] → [WiFi 전송] → [음성인식]
                                              ↓
[스피커 출력] ← [음성합성] ← [AI 답변] ← [RAG 검색]
```

## 📁 프로젝트 구조

```
voice_rag_nano/
├── esp32_client/              # ESP32 Arduino 코드
│   ├── esp32_voice_client.ino # 메인 코드
│   ├── config.h               # 설정 (WiFi, 핀)
│   └── TFT_eSPI_User_Setup.h  # LCD 라이브러리 설정
│
├── raspberry_pi_server/       # Raspberry Pi 서버
│   ├── server.py              # 메인 서버
│   ├── requirements.txt       # Python 패키지
│   ├── install.sh             # 자동 설치 스크립트
│   └── documents/             # RAG 문서 폴더
│
├── hardware/                  # 하드웨어 가이드
│   └── WIRING_GUIDE.md        # 배선 가이드
│
└── README.md                  # 이 파일
```

---

## 🚀 빠른 시작

### 1️⃣ Raspberry Pi 서버 설정

```bash
# 1. 프로젝트 폴더로 이동
cd raspberry_pi_server

# 2. 자동 설치 실행
chmod +x install.sh
./install.sh

# 3. 서버 실행
source venv/bin/activate
python server.py
```

서버 실행 후 표시되는 IP 주소를 기억하세요!

### 2️⃣ ESP32 설정

1. **Arduino IDE**에서 `esp32_client/esp32_voice_client.ino` 열기

2. **config.h** 수정:
```cpp
#define WIFI_SSID     "YourWiFiName"     // WiFi 이름
#define WIFI_PASSWORD "YourPassword"      // WiFi 비밀번호
#define SERVER_IP     "192.168.x.x"       // Raspberry Pi IP
```

3. **TFT_eSPI 설정** (중요!)
   - `TFT_eSPI_User_Setup.h` 내용을 라이브러리의 `User_Setup.h`에 복사

4. **보드 선택**: ESP32S3 Dev Module

5. **업로드**

### 3️⃣ 테스트

1. LCD에 "Ready" 표시 확인
2. BOOT 버튼 누르고 말하기
3. AI 응답이 스피커로 출력

---

## 🔌 하드웨어 연결 요약

| 모듈 | 핀 | ESP32 |
|------|-----|-------|
| **INMP441** | SD | GPIO6 |
| | SCK | GPIO4 |
| | WS | GPIO5 |
| | VDD | 3.3V |
| **MAX98357A** | DIN | GPIO16 |
| | BCLK | GPIO7 |
| | LRC | GPIO15 |
| | VIN | 5V |
| **GC9A01** | SDA | GPIO11 |
| | SCL | GPIO12 |
| | CS | GPIO10 |
| | DC | GPIO13 |
| | RST | GPIO14 |

자세한 내용: `hardware/WIRING_GUIDE.md`

---

## 📝 RAG 문서 추가

`raspberry_pi_server/documents/` 폴더에 `.txt` 또는 `.md` 파일 추가:

```bash
# 예시
echo "회사 휴가는 연 15일입니다." > documents/company_policy.txt
```

문서 추가 후 서버 재시작 또는:
```bash
curl -X POST http://localhost:5000/documents/reload
```

---

## 🔧 API 엔드포인트

| 메소드 | URL | 설명 |
|--------|-----|------|
| POST | /voice | 음성 처리 (메인) |
| POST | /text | 텍스트 처리 (테스트) |
| GET | /health | 서버 상태 |
| GET | /documents | 문서 목록 |
| POST | /documents/reload | 문서 다시 로드 |

### 테스트
```bash
# 상태 확인
curl http://localhost:5000/health

# 텍스트 질문
curl -X POST http://localhost:5000/text \
     -H "Content-Type: application/json" \
     -d '{"text": "안녕하세요"}'
```

---

## ❓ 문제 해결

### WiFi 연결 안 됨
- 2.4GHz WiFi인지 확인
- config.h의 WiFi 정보 재확인

### 서버 연결 안 됨
- `hostname -I`로 Raspberry Pi IP 확인
- 방화벽: `sudo ufw allow 5000`

### 음성 인식 안 됨
- 마이크 VDD가 3.3V인지 확인
- 조용한 환경에서 테스트

### 소리가 안 남
- MAX98357A VIN이 5V인지 확인
- 스피커 연결 확인

---

## 📄 라이선스

MIT License

---

## 🙏 감사

- [OpenAI Whisper](https://github.com/openai/whisper)
- [Ollama](https://ollama.ai/)
- [Edge-TTS](https://github.com/rany2/edge-tts)
- [TFT_eSPI](https://github.com/Bodmer/TFT_eSPI)
