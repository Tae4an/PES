# PES 빠른 시작 가이드

> 5분 안에 PES 백엔드를 실행하는 방법

## 🚀 빠른 시작

### 1단계: Docker Desktop 실행

```bash
# Docker Desktop 실행 여부 확인
docker ps

# Docker Desktop이 실행되지 않았다면
open -a Docker

# Docker 시작 대기 (30초 정도)
```

### 2단계: 환경 설정 및 실행

```bash
# 프로젝트 디렉토리로 이동
cd /Users/tae4an/PES

# 초기 설정 스크립트 실행
./scripts/setup.sh
```

이 스크립트는 자동으로:
- ✅ Docker Desktop 상태 확인
- ✅ 환경 변수 파일 생성 (.env)
- ✅ Docker Compose로 전체 스택 실행
- ✅ Qwen3 8B 모델 다운로드
- ✅ 데이터베이스 초기화
- ✅ 서버 헬스체크

### 3단계: 서비스 확인

#### API 문서 확인
```bash
open http://localhost:8000/docs
```

#### 헬스체크
```bash
curl http://localhost:8000/api/v1/health
```

#### 대피소 검색 테스트
```bash
curl "http://localhost:8000/api/v1/shelters/nearby?lat=37.5263&lng=126.8962&radius=2"
```

#### Qwen3 LLM 테스트
```bash
cd backend
python tests/test_qwen.py
```

---

## 📊 실행 중인 서비스

| 서비스 | 포트 | URL |
|--------|------|-----|
| FastAPI Backend | 8000 | http://localhost:8000 |
| PostgreSQL | 5432 | localhost:5432 |
| Redis | 6379 | localhost:6379 |
| Ollama (Qwen3) | 11434 | http://localhost:11434 |

---

## 🧪 테스트 시나리오

### 1. 사용자 등록
```bash
curl -X POST http://localhost:8000/api/v1/user/register \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "test_device_001",
    "fcm_token": "test_fcm_token",
    "age_group": "성인",
    "mobility": "정상"
  }'
```

### 2. 주변 대피소 검색
```bash
# 영등포구 기준
curl "http://localhost:8000/api/v1/shelters/nearby?lat=37.5263&lng=126.8962&radius=2&limit=3"
```

### 3. 행동카드 생성 (LLM)
```bash
curl -X POST http://localhost:8000/api/v1/disasters/action-card/generate \
  -H "Content-Type: application/json" \
  -d '{
    "disaster_type": "호우",
    "location": "서울시 영등포구",
    "user_latitude": 37.5263,
    "user_longitude": 126.8962,
    "age_group": "성인",
    "mobility": "정상"
  }'
```

---

## 🔧 수동 설정 (선택사항)

### 환경 변수 설정

`backend/.env` 파일을 열어서 다음을 설정하세요:

```bash
# 행정안전부 재난문자 API 키 (필수)
DISASTER_API_KEY=your_api_key_here

# Firebase 인증 파일 경로 (선택)
FIREBASE_CREDENTIALS_PATH=./credentials.json
```

### Qwen3 모델 수동 다운로드

```bash
docker exec pes-ollama ollama pull qwen3:8b-instruct
```

---

## 📝 로그 확인

```bash
# 전체 로그
docker-compose logs -f

# Backend만
docker logs -f pes-backend

# PostgreSQL만
docker logs -f pes-postgres

# Ollama만
docker logs -f pes-ollama
```

---

## 🛑 서비스 중지

```bash
# 모든 컨테이너 중지
docker-compose down

# 볼륨 포함 완전 삭제
docker-compose down -v
```

---

## 🚨 문제 해결

### Docker Desktop이 실행되지 않음
```bash
open -a Docker
# 30초 대기 후 다시 시도
```

### Qwen3 모델이 없음
```bash
docker exec pes-ollama ollama pull qwen3:8b-instruct
```

### PostgreSQL 연결 오류
```bash
docker-compose restart postgres
sleep 5
docker-compose restart backend
```

### 포트 충돌
이미 8000번 포트가 사용 중이라면 `docker-compose.yml`에서 포트 변경:
```yaml
backend:
  ports:
    - "8080:8000"  # 8000 대신 8080 사용
```

---

## 📚 다음 단계

1. **API 문서 확인**: http://localhost:8000/docs
2. **Flutter 앱 연동**: API 엔드포인트를 Flutter 앱에 연결
3. **Firebase 설정**: FCM 푸시 알림을 위한 Firebase 프로젝트 생성
4. **행정안전부 API 키 발급**: 실제 재난문자 폴링을 위한 API 키 신청

---

## ❓ 도움말

문제가 발생하면 다음을 확인하세요:

1. Docker Desktop이 실행 중인가?
2. 8000, 5432, 6379, 11434 포트가 사용 가능한가?
3. 환경 변수 파일(.env)이 존재하는가?
4. 로그에 에러가 있는가? (`docker-compose logs`)

더 자세한 내용은 `README.md`를 참고하세요.

