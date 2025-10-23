# PES (Personal Emergency Siren)

> 재난 안전 모바일 앱 - 위치 기반 실시간 재난 대피 행동카드 생성 시스템

## 📋 프로젝트 개요

**PES**는 사용자의 위치를 기반으로 재난 상황에서 **30초 내**에 개인화된 대피 행동카드를 생성하고 푸시 알림으로 전달하는 시스템입니다.

### 주요 기능

- ✅ 행정안전부 재난문자 **10초 주기 실시간 폴링**
- ✅ **PostGIS 기반 위치 교차 판정** (사용자 ↔ 재난 지역)
- ✅ **근처 대피소 자동 검색** (거리 및 도보 시간 계산)
- ✅ **Qwen3 8B 로컬 LLM**으로 3~5줄 행동카드 생성
- ✅ **Firebase FCM** 푸시 알림 발송

---

## 🏗️ 아키텍처

```
┌─────────────┐
│ Flutter App │
└──────┬──────┘
       │ REST API
┌──────▼──────────────────────────────┐
│     FastAPI Backend (Python)        │
│  ┌──────────────────────────────┐   │
│  │ 재난문자 10초 폴링 (APScheduler)│   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │ PostGIS 위치 교차 판정        │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │ Qwen3 8B LLM (Ollama)        │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │ Firebase FCM 푸시 알림        │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
         │              │
    ┌────▼───┐     ┌───▼────┐
    │PostgreSQL│   │ Redis  │
    │+ PostGIS │   │ Cache  │
    └──────────┘   └────────┘
```

---

## 🚀 시작하기

### 1. 사전 요구사항

- **Docker Desktop** (실행 중이어야 함)
- Python 3.11+
- PostgreSQL 15+ (PostGIS 포함)
- Redis 7+
- Ollama (Qwen3 8B)

### 2. 설치

```bash
# 프로젝트 클론
cd /Users/tae4an/PES

# 환경 변수 설정
cd backend
cp .env.example .env
# .env 파일 수정 (DISASTER_API_KEY 등)

# Docker Desktop 시작
open -a Docker
# 또는
docker desktop start

# 전체 스택 실행
docker-compose up -d
```

### 3. Qwen3 8B 모델 다운로드

```bash
# Ollama 컨테이너에서 모델 다운로드 (최초 1회)
docker exec pes-ollama ollama pull qwen3:8b-instruct

# 모델 확인
docker exec pes-ollama ollama list
```

### 4. 서버 실행 확인

```bash
# 헬스체크
curl http://localhost:8000/api/v1/health

# Swagger 문서
open http://localhost:8000/docs
```

---

## 📁 프로젝트 구조

```
PES/
├── backend/
│   ├── app/
│   │   ├── api/v1/
│   │   │   ├── endpoints/      # API 엔드포인트
│   │   │   │   ├── user.py
│   │   │   │   ├── shelters.py
│   │   │   │   ├── disasters.py
│   │   │   │   └── health.py
│   │   │   └── schemas/        # Pydantic 스키마
│   │   ├── services/           # 비즈니스 로직
│   │   │   ├── disaster_poller.py
│   │   │   ├── llm_service.py
│   │   │   └── shelter_finder.py
│   │   ├── models/             # SQLAlchemy 모델
│   │   ├── db/                 # 데이터베이스
│   │   ├── core/               # 설정 및 유틸리티
│   │   ├── background/         # 백그라운드 작업
│   │   └── external/           # 외부 서비스 (FCM)
│   ├── main.py
│   ├── requirements.txt
│   └── Dockerfile
├── docker-compose.yml
└── README.md
```

---

## 🔌 API 엔드포인트

### 1. 사용자 등록
```http
POST /api/v1/user/register
Content-Type: application/json

{
  "device_id": "device_12345",
  "fcm_token": "FCM_TOKEN_HERE",
  "age_group": "성인",
  "mobility": "정상"
}
```

### 2. 위치 업데이트
```http
POST /api/v1/user/location/update
Content-Type: application/json
Authorization: Bearer {token}

{
  "latitude": 37.5263,
  "longitude": 126.8962
}
```

### 3. 주변 대피소 검색
```http
GET /api/v1/shelters/nearby?lat=37.5263&lng=126.8962&radius=2&limit=3
```

### 4. 행동카드 생성 (테스트용)
```http
POST /api/v1/disasters/action-card/generate
Content-Type: application/json

{
  "disaster_type": "호우",
  "location": "서울시 영등포구",
  "user_latitude": 37.5263,
  "user_longitude": 126.8962,
  "age_group": "성인",
  "mobility": "정상"
}
```

---

## 🧪 테스트

### LLM 행동카드 생성 테스트

```bash
# Qwen3 8B 직접 테스트
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3:8b-instruct",
    "prompt": "호우 경보 시 즉시 행동 지침 3줄로 작성하세요.",
    "stream": false
  }'
```

### API 테스트

```bash
# 대피소 검색
curl "http://localhost:8000/api/v1/shelters/nearby?lat=37.5263&lng=126.8962&radius=2"

# 행동카드 생성
curl -X POST http://localhost:8000/api/v1/disasters/action-card/generate \
  -H "Content-Type: application/json" \
  -d '{
    "disaster_type": "호우",
    "location": "서울시 영등포구",
    "user_latitude": 37.5263,
    "user_longitude": 126.8962
  }'
```

---

## 🗄️ 데이터베이스

### PostGIS 쿼리 예시

```sql
-- 사용자로부터 2km 내 대피소 검색
SELECT 
    name,
    address,
    ST_Distance(location::geography, ST_GeogFromText('SRID=4326;POINT(126.8962 37.5263)')) / 1000 as distance_km
FROM shelters
WHERE ST_DWithin(
    location::geography,
    ST_GeogFromText('SRID=4326;POINT(126.8962 37.5263)'),
    2000
)
ORDER BY distance_km;
```

---

## ⚙️ 환경 변수

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `DATABASE_URL` | PostgreSQL 연결 URL | `postgresql+asyncpg://pes_user:pes_password@localhost:5432/pes` |
| `REDIS_URL` | Redis 연결 URL | `redis://localhost:6379` |
| `OLLAMA_ENDPOINT` | Ollama API 엔드포인트 | `http://localhost:11434` |
| `OLLAMA_MODEL` | 사용할 LLM 모델 | `qwen3:8b-instruct` |
| `DISASTER_API_KEY` | 행정안전부 API 키 | (필수) |
| `FIREBASE_CREDENTIALS_PATH` | Firebase 인증 파일 경로 | `./credentials.json` |
| `DISASTER_POLL_INTERVAL_SECONDS` | 폴링 주기 (초) | `10` |

---

## 🛠️ 개발 가이드

### 로컬 개발 환경

```bash
# 가상환경 생성
python -m venv venv
source venv/bin/activate  # macOS/Linux
# venv\Scripts\activate  # Windows

# 의존성 설치
cd backend
pip install -r requirements.txt

# 서버 실행 (개발 모드)
uvicorn main:app --reload --port 8000
```

### 데이터베이스 마이그레이션

```bash
# Alembic 초기화 (최초 1회)
alembic init alembic

# 마이그레이션 생성
alembic revision --autogenerate -m "Initial migration"

# 마이그레이션 적용
alembic upgrade head
```

---

## 📊 모니터링

### 로그 확인

```bash
# Backend 로그
docker logs -f pes-backend

# PostgreSQL 로그
docker logs -f pes-postgres

# Ollama 로그
docker logs -f pes-ollama
```

### Redis 캐시 확인

```bash
# Redis CLI 접속
docker exec -it pes-redis redis-cli

# 캐시된 재난문자 확인
KEYS disaster:*
GET disaster:TEST_20251023_001
```

---

## 🚨 트러블슈팅

### Docker Desktop이 실행되지 않음

```bash
# Docker Desktop 상태 확인
docker ps

# Docker Desktop 시작
open -a Docker
```

### Ollama 모델이 없음

```bash
# 모델 다운로드
docker exec pes-ollama ollama pull qwen3:8b-instruct

# 모델 목록 확인
docker exec pes-ollama ollama list
```

### PostgreSQL 연결 실패

```bash
# PostgreSQL 상태 확인
docker exec pes-postgres pg_isready -U pes_user -d pes

# PostgreSQL 재시작
docker-compose restart postgres
```

---

## 📝 라이선스

MIT License

---

## 👥 기여자

- [@tae4an](https://github.com/tae4an)

---

## 📞 문의

이슈 또는 PR을 통해 문의해주세요.

