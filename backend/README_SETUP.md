# 🚨 PES 백엔드 초기 설정 가이드

## 빠른 시작 (자동 설정)

```bash
# 백엔드 디렉토리로 이동
cd backend

# 초기 설정 스크립트 실행
./setup_backend.sh
```

## 📋 수동 설정 (단계별)

### 1. Python 환경 확인
```bash
# Python 3.11+ 버전 확인
python3 --version

# 가상환경 생성
python3 -m venv venv

# 가상환경 활성화
source venv/bin/activate  # macOS/Linux
# 또는
venv\Scripts\activate     # Windows
```

### 2. 의존성 설치
```bash
# pip 업그레이드
pip install --upgrade pip

# 의존성 설치
pip install -r requirements.txt
```

### 3. 환경 변수 설정
```bash
# .env 파일 생성
cp .env.example .env

# .env 파일 편집 (실제 값으로 변경)
nano .env  # 또는 vim, code 등
```

### 4. 필수 환경 변수 설정
```bash
# .env 파일에서 다음 항목들을 실제 값으로 변경:

# 행정안전부 API 키 (필수)
DISASTER_API_KEY=your_actual_service_key

# JWT 시크릿 키 (필수)
SECRET_KEY=your-secret-key-change-in-production

# 데이터베이스 연결 (PostgreSQL)
DATABASE_URL=postgresql+asyncpg://pes_user:pes_password@localhost:5432/pes

# Redis 연결
REDIS_URL=redis://localhost:6379

# Ollama LLM 서비스
OLLAMA_ENDPOINT=http://localhost:11434
```

### 5. Firebase 설정 (FCM 푸시 알림용)
```bash
# Firebase Console에서 서비스 계정 키 다운로드
# credentials/firebase-service-account.json에 저장

# .env 파일에 경로 설정
FIREBASE_CREDENTIALS_PATH=credentials/firebase-service-account.json
```

### 6. 서버 실행
```bash
# 가상환경 활성화 (아직 안 했다면)
source venv/bin/activate

# 서버 실행
python main.py
```

## 🔧 외부 서비스 설정

### Ollama (로컬 LLM)
```bash
# Ollama 설치
# macOS
brew install ollama

# Linux
curl -fsSL https://ollama.ai/install.sh | sh

# Ollama 서비스 시작
ollama serve

# Qwen3 모델 다운로드
ollama pull qwen3:8b
```

### PostgreSQL + PostGIS (선택사항)
```bash
# macOS
brew install postgresql postgis

# Ubuntu
sudo apt install postgresql postgresql-contrib postgis

# 데이터베이스 생성
createdb pes
psql pes -c "CREATE EXTENSION postgis;"
```

### Redis (선택사항)
```bash
# macOS
brew install redis

# Ubuntu
sudo apt install redis-server

# Redis 서비스 시작
redis-server
```

## 🧪 테스트

### API 테스트
```bash
# Health Check
curl http://localhost:8000/api/v1/health

# Mock 재난 데이터
curl http://localhost:8000/api/v1/disasters/active

# Action Card 생성 테스트
curl -X POST http://localhost:8000/api/v1/action-cards/generate \
  -H "Content-Type: application/json" \
  -d '{
    "disaster_id": 1,
    "latitude": 37.5665,
    "longitude": 126.9780,
    "age_group": "20~40대",
    "mobility": "normal"
  }'
```

### 스크립트 테스트
```bash
# Mock API 테스트 스크립트 실행
./test_mock_api.sh
```

## 📚 주요 엔드포인트

| 엔드포인트 | 설명 | 예시 |
|-----------|------|------|
| `GET /` | 서버 상태 | `curl http://localhost:8000/` |
| `GET /docs` | API 문서 | 브라우저에서 `http://localhost:8000/docs` |
| `GET /api/v1/health` | Health Check | `curl http://localhost:8000/api/v1/health` |
| `GET /api/v1/disasters/active` | 활성 재난 조회 | `curl http://localhost:8000/api/v1/disasters/active` |
| `POST /api/v1/action-cards/generate` | Action Card 생성 | 위의 테스트 예시 참조 |
| `POST /api/v1/fcm/token/register` | FCM 토큰 등록 | Flutter 앱에서 자동 호출 |

## 🐛 문제 해결

### 일반적인 문제들

**1. Python 버전 오류**
```bash
# Python 3.11+ 설치 필요
# macOS
brew install python@3.11

# Ubuntu
sudo apt install python3.11 python3.11-venv
```

**2. 의존성 설치 실패**
```bash
# 가상환경 재생성
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

**3. 포트 충돌 (8000번 포트 사용 중)**
```bash
# 포트 사용 중인 프로세스 확인
lsof -i :8000

# 프로세스 종료
kill -9 [PID]
```

**4. Ollama 연결 실패**
```bash
# Ollama 서비스 상태 확인
curl http://localhost:11434/api/tags

# Ollama 재시작
ollama serve
```

**5. Firebase 인증 오류**
```bash
# 서비스 계정 키 파일 확인
ls -la credentials/firebase-service-account.json

# .env 파일의 경로 확인
grep FIREBASE_CREDENTIALS_PATH .env
```

