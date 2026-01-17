#!/bin/bash
# =====================================
# 🚀 Voice RAG Server 자동 설치 스크립트
# Raspberry Pi 5 용
# =====================================

set -e  # 에러 시 중단

echo "╔═══════════════════════════════════════════╗"
echo "║  Voice RAG Server Installer               ║"
echo "║  for Raspberry Pi 5                       ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

# 색상
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 현재 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# =====================================
# 1. 시스템 패키지
# =====================================
echo -e "${YELLOW}[1/5] 시스템 패키지 설치...${NC}"
sudo apt update
sudo apt install -y python3-pip python3-venv ffmpeg portaudio19-dev git curl
echo -e "${GREEN}✓ 완료${NC}\n"

# =====================================
# 2. Ollama 설치
# =====================================
echo -e "${YELLOW}[2/5] Ollama 설치...${NC}"
if command -v ollama &> /dev/null; then
    echo "Ollama가 이미 설치되어 있습니다."
else
    curl -fsSL https://ollama.com/install.sh | sh
fi
echo -e "${GREEN}✓ 완료${NC}\n"

# =====================================
# 3. LLM 모델 다운로드
# =====================================
echo -e "${YELLOW}[3/5] LLM 모델 다운로드 (시간 소요)...${NC}"
ollama pull llama3.2
echo -e "${GREEN}✓ 완료${NC}\n"

# =====================================
# 4. Python 가상환경
# =====================================
echo -e "${YELLOW}[4/5] Python 가상환경 설정...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install --upgrade pip
echo -e "${GREEN}✓ 완료${NC}\n"

# =====================================
# 5. Python 패키지
# =====================================
echo -e "${YELLOW}[5/5] Python 패키지 설치 (시간 소요)...${NC}"
pip install -r requirements.txt
echo -e "${GREEN}✓ 완료${NC}\n"

# =====================================
# 문서 폴더 생성
# =====================================
mkdir -p documents

# =====================================
# 방화벽 설정
# =====================================
if command -v ufw &> /dev/null; then
    sudo ufw allow 5000/tcp 2>/dev/null || true
fi

# =====================================
# 완료
# =====================================
echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  ✅ 설치 완료!                                        ║"
echo "╠═══════════════════════════════════════════════════════╣"
echo "║                                                       ║"
echo "║  서버 실행:                                           ║"
echo "║    source venv/bin/activate                           ║"
echo "║    python server.py                                   ║"
echo "║                                                       ║"
echo "║  백그라운드 실행:                                     ║"
echo "║    nohup python server.py > server.log 2>&1 &         ║"
echo "║                                                       ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# IP 주소 표시
IP=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}📍 Raspberry Pi IP: ${IP}${NC}"
echo -e "${YELLOW}   ESP32 config.h의 SERVER_IP에 이 주소를 입력하세요!${NC}"
echo ""
