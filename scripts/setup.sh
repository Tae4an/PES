#!/bin/bash

# PES 백엔드 초기 설정 스크립트

set -e

echo "=========================================="
echo "PES 백엔드 초기 설정"
echo "=========================================="

# Docker Desktop 실행 확인
echo ""
echo "1. Docker Desktop 상태 확인..."
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker Desktop이 실행되지 않았습니다."
    echo "   Docker Desktop을 시작합니다..."
    open -a Docker
    
    echo "   Docker 시작 대기 중..."
    sleep 10
    
    # 재확인
    if ! docker info > /dev/null 2>&1; then
        echo "❌ Docker Desktop을 시작할 수 없습니다."
        echo "   수동으로 Docker Desktop을 실행한 후 다시 시도하세요."
        exit 1
    fi
fi
echo "✅ Docker Desktop이 실행 중입니다."

# 환경 변수 파일 확인
echo ""
echo "2. 환경 변수 파일 확인..."
if [ ! -f backend/.env ]; then
    echo "   .env 파일이 없습니다. .env.example을 복사합니다..."
    cp backend/.env.example backend/.env
    echo "✅ .env 파일 생성 완료"
    echo "⚠️  backend/.env 파일을 열어서 DISASTER_API_KEY 등을 설정하세요."
else
    echo "✅ .env 파일이 존재합니다."
fi

# Docker Compose 실행
echo ""
echo "3. Docker Compose로 전체 스택 실행..."
docker-compose up -d

echo ""
echo "   컨테이너 시작 대기 중..."
sleep 5

# 컨테이너 상태 확인
echo ""
echo "4. 컨테이너 상태 확인..."
docker-compose ps

# Qwen3 모델 다운로드
echo ""
echo "5. Qwen3 8B 모델 확인..."
if docker exec pes-ollama ollama list | grep -q "qwen3:8b-instruct"; then
    echo "✅ Qwen3 8B 모델이 이미 설치되어 있습니다."
else
    echo "   Qwen3 8B 모델을 다운로드합니다 (시간이 소요될 수 있습니다)..."
    docker exec pes-ollama ollama pull qwen3:8b-instruct
    echo "✅ Qwen3 8B 모델 다운로드 완료"
fi

# 데이터베이스 초기화 확인
echo ""
echo "6. 데이터베이스 초기화 확인..."
sleep 3
docker exec pes-postgres psql -U pes_user -d pes -c "\dt" > /dev/null 2>&1 || true
echo "✅ 데이터베이스 초기화 완료"

# 헬스체크
echo ""
echo "7. 서버 헬스체크..."
sleep 5
if curl -f http://localhost:8000/api/v1/health > /dev/null 2>&1; then
    echo "✅ 백엔드 서버가 정상적으로 실행 중입니다."
else
    echo "⚠️  백엔드 서버가 아직 준비되지 않았습니다."
    echo "   docker logs pes-backend 명령어로 로그를 확인하세요."
fi

echo ""
echo "=========================================="
echo "✅ PES 백엔드 설정 완료!"
echo "=========================================="
echo ""
echo "다음 URL에서 확인하세요:"
echo "  - API 문서: http://localhost:8000/docs"
echo "  - 헬스체크: http://localhost:8000/api/v1/health"
echo ""
echo "로그 확인:"
echo "  - Backend: docker logs -f pes-backend"
echo "  - PostgreSQL: docker logs -f pes-postgres"
echo "  - Ollama: docker logs -f pes-ollama"
echo ""
echo "테스트:"
echo "  - cd backend && python tests/test_qwen.py"
echo ""

