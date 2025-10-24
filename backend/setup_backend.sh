#!/bin/bash

# PES 백엔드 초기 설정 스크립트
# 다른 팀원이 처음 백엔드를 설정할 때 사용하는 스크립트

set -e  # 에러 발생 시 스크립트 중단

echo "🚀 PES 백엔드 초기 설정을 시작합니다..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Python 버전 확인
check_python() {
    log_info "Python 버전 확인 중..."
    
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        log_success "Python3 발견: $PYTHON_VERSION"
        
        # Python 3.11 이상인지 확인
        PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
        PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)
        
        if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 11 ]; then
            log_success "Python 버전이 요구사항을 만족합니다 (3.11+)"
        else
            log_error "Python 3.11 이상이 필요합니다. 현재 버전: $PYTHON_VERSION"
            log_info "Python 3.11+ 설치 방법:"
            log_info "  macOS: brew install python@3.11"
            log_info "  Ubuntu: sudo apt install python3.11 python3.11-venv"
            exit 1
        fi
    else
        log_error "Python3가 설치되지 않았습니다."
        exit 1
    fi
}

# 가상환경 생성 및 활성화
setup_venv() {
    log_info "Python 가상환경 설정 중..."
    
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        log_success "가상환경 'venv' 생성 완료"
    else
        log_warning "가상환경 'venv'가 이미 존재합니다."
    fi
    
    # 가상환경 활성화
    source venv/bin/activate
    log_success "가상환경 활성화 완료"
    
    # pip 업그레이드
    pip install --upgrade pip
    log_success "pip 업그레이드 완료"
}

# 의존성 설치
install_dependencies() {
    log_info "Python 의존성 설치 중..."
    
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
        log_success "의존성 설치 완료"
    else
        log_error "requirements.txt 파일을 찾을 수 없습니다."
        exit 1
    fi
}

# 환경 변수 설정
setup_env() {
    log_info "환경 변수 설정 중..."
    
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            log_success ".env 파일 생성 완료 (.env.example 복사)"
            log_warning "⚠️  .env 파일을 열어서 실제 값으로 수정하세요!"
            log_info "특히 다음 항목들을 확인하세요:"
            log_info "  - DISASTER_API_KEY: 행정안전부 API 키"
            log_info "  - SECRET_KEY: JWT 시크릿 키"
            log_info "  - DATABASE_URL: PostgreSQL 연결 정보"
            log_info "  - REDIS_URL: Redis 연결 정보"
        else
            log_error ".env.example 파일을 찾을 수 없습니다."
            exit 1
        fi
    else
        log_warning ".env 파일이 이미 존재합니다."
    fi
}

# Firebase 서비스 계정 키 확인
check_firebase() {
    log_info "Firebase 설정 확인 중..."
    
    if [ -f "credentials/firebase-service-account.json" ]; then
        log_success "Firebase 서비스 계정 키 발견"
    else
        log_warning "Firebase 서비스 계정 키가 없습니다."
        log_info "FCM 푸시 알림을 사용하려면 다음 단계를 따르세요:"
        log_info "1. Firebase Console에서 서비스 계정 키 다운로드"
        log_info "2. credentials/firebase-service-account.json에 저장"
        log_info "3. .env 파일에서 FIREBASE_CREDENTIALS_PATH 설정"
    fi
}

# 외부 서비스 연결 테스트
test_connections() {
    log_info "외부 서비스 연결 테스트 중..."
    
    # Ollama 서비스 테스트
    if command -v curl &> /dev/null; then
        if curl -s http://localhost:11434/api/tags &> /dev/null; then
            log_success "Ollama 서비스 연결 성공"
        else
            log_warning "Ollama 서비스에 연결할 수 없습니다."
            log_info "Ollama 설치 및 실행 방법:"
            log_info "  macOS: brew install ollama && ollama serve"
            log_info "  Linux: curl -fsSL https://ollama.ai/install.sh | sh"
            log_info "  모델 다운로드: ollama pull qwen3:8b"
        fi
    else
        log_warning "curl이 설치되지 않았습니다. 연결 테스트를 건너뜁니다."
    fi
}

# 서버 실행 테스트
test_server() {
    log_info "백엔드 서버 실행 테스트 중..."
    
    # 백그라운드에서 서버 시작
    python main.py &
    SERVER_PID=$!
    
    # 서버 시작 대기
    sleep 3
    
    # Health check
    if curl -s http://localhost:8000/api/v1/health &> /dev/null; then
        log_success "백엔드 서버 실행 성공!"
        log_info "서버 접속: http://localhost:8000"
        log_info "API 문서: http://localhost:8000/docs"
    else
        log_error "백엔드 서버 실행 실패"
    fi
    
    # 서버 종료
    kill $SERVER_PID 2>/dev/null || true
}

# 개발 도구 설치 (선택사항)
install_dev_tools() {
    log_info "개발 도구 설치 중 (선택사항)..."
    
    # pre-commit 설치 (코드 품질 관리)
    if command -v pre-commit &> /dev/null; then
        log_success "pre-commit이 이미 설치되어 있습니다."
    else
        log_info "pre-commit 설치를 권장합니다:"
        log_info "  pip install pre-commit"
        log_info "  pre-commit install"
    fi
    
    # black 코드 포매터 설치
    if command -v black &> /dev/null; then
        log_success "black이 이미 설치되어 있습니다."
    else
        log_info "black 코드 포매터 설치를 권장합니다:"
        log_info "  pip install black"
    fi
}

# 메인 실행 함수
main() {
    echo "=========================================="
    echo "🚨 PES 백엔드 초기 설정 스크립트"
    echo "=========================================="
    echo ""
    
    # 1. Python 버전 확인
    check_python
    echo ""
    
    # 2. 가상환경 설정
    setup_venv
    echo ""
    
    # 3. 의존성 설치
    install_dependencies
    echo ""
    
    # 4. 환경 변수 설정
    setup_env
    echo ""
    
    # 5. Firebase 설정 확인
    check_firebase
    echo ""
    
    # 6. 외부 서비스 연결 테스트
    test_connections
    echo ""
    
    # 7. 개발 도구 설치
    install_dev_tools
    echo ""
    
    # 8. 서버 실행 테스트
    test_server
    echo ""
    
    echo "=========================================="
    log_success "🎉 백엔드 초기 설정이 완료되었습니다!"
    echo "=========================================="
    echo ""
    echo "다음 단계:"
    echo "1. .env 파일을 열어서 실제 값으로 수정"
    echo "2. 가상환경 활성화: source venv/bin/activate"
    echo "3. 서버 실행: python main.py"
    echo "4. API 문서 확인: http://localhost:8000/docs"
    echo ""
    echo "문제가 있으면 팀원에게 문의하세요! 🤝"
}

# 스크립트 실행
main "$@"
