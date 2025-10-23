# Mock API 사용 가이드

## 개요

행정안전부 재난문자 API가 점검 중일 때 사용할 수 있는 **Mock API 시스템**입니다.

- **CSV 기반**: 제주도 재난문자 발송 현황 데이터 (55건)
- **실시간 전환**: 환경 변수 또는 API로 Mock/Real 모드 즉시 전환
- **완전한 REST API**: 필터링, 통계, 관리 기능 포함

---

## 빠른 시작

### 1. 환경 변수 설정

```bash
# backend/.env
USE_MOCK_DATA=true  # Mock 모드 활성화
MOCK_DATA_PATH=app/data/sample_disasters.csv
```

### 2. 서버 시작

```bash
docker-compose up -d
```

### 3. 헬스체크

```bash
curl http://localhost:8000/api/v1/health/
```

**응답 예시:**
```json
{
  "status": "ok",
  "mock_mode": true,
  "data_source": "mock_csv",
  "mock_data_count": 55
}
```

---

## API 엔드포인트

### 재난문자 조회

#### 1. 최신 재난문자 N개 조회

```bash
GET /api/v1/disasters/mock?limit=5
```

**쿼리 파라미터:**
- `limit`: 반환할 개수 (1~50, 기본 5)
- `category`: 재난 구분 필터 (기상특보, 지진, 교통, 사회재난, 산불, 화재발생)
- `start_date`: 시작 날짜 (YYYY-MM-DD)
- `end_date`: 종료 날짜 (YYYY-MM-DD)

**예시:**
```bash
# 최신 10개
curl "http://localhost:8000/api/v1/disasters/mock?limit=10"

# 지진 관련만
curl -G "http://localhost:8000/api/v1/disasters/mock" \
  --data-urlencode "category=지진"

# 날짜 범위
curl -G "http://localhost:8000/api/v1/disasters/mock" \
  --data-urlencode "start_date=2025-01-10" \
  --data-urlencode "end_date=2025-01-15"
```

**응답 예시:**
```json
[
  {
    "serial_number": 55,
    "date": "2025-04-08",
    "time": "11:02",
    "category": "산불",
    "message": "건조특보가 발효중...",
    "issued_at": "2025-04-08T11:02:00"
  }
]
```

---

#### 2. 전체 재난문자 조회

```bash
GET /api/v1/disasters/mock/all
```

**예시:**
```bash
curl "http://localhost:8000/api/v1/disasters/mock/all"
```

---

#### 3. 재난 통계 정보

```bash
GET /api/v1/disasters/mock/statistics
```

**응답 예시:**
```json
{
  "total_disasters": 55,
  "by_category": {
    "기상특보": 31,
    "지진": 2,
    "교통": 1,
    "사회재난": 12,
    "산불": 7,
    "화재발생": 2
  },
  "data_source": "mock_csv",
  "mock_mode": true
}
```

---

### 관리자 API

#### 1. Mock 모드 상태 확인

```bash
GET /api/v1/admin/mock-mode-status
```

**응답 예시:**
```json
{
  "mock_mode_enabled": true,
  "data_source": "mock_csv",
  "total_mock_messages": 55,
  "message": "Mock 모드 활성화 - CSV 데이터 55개 로드됨"
}
```

---

#### 2. Mock/Real 모드 토글

```bash
POST /api/v1/admin/toggle-mock-mode
```

**예시:**
```bash
curl -X POST "http://localhost:8000/api/v1/admin/toggle-mock-mode"
```

**응답 예시:**
```json
{
  "success": true,
  "previous_mode": "Mock CSV",
  "current_mode": "Real API",
  "message": "재난 데이터 모드가 Real API(으)로 전환되었습니다."
}
```

---

#### 3. Mock 모드 명시적 설정

```bash
POST /api/v1/admin/set-mock-mode
Content-Type: application/json

{
  "enabled": true  # true=Mock, false=Real API
}
```

**예시:**
```bash
# Mock 모드 활성화
curl -X POST "http://localhost:8000/api/v1/admin/set-mock-mode" \
  -H "Content-Type: application/json" \
  -d '{"enabled": true}'

# Real API 모드로 전환
curl -X POST "http://localhost:8000/api/v1/admin/set-mock-mode" \
  -H "Content-Type: application/json" \
  -d '{"enabled": false}'
```

---

#### 4. Mock 데이터 재로드

```bash
POST /api/v1/admin/reload-mock-data
```

CSV 파일을 수정한 후 재시작 없이 데이터를 다시 로드합니다.

**예시:**
```bash
curl -X POST "http://localhost:8000/api/v1/admin/reload-mock-data"
```

---

## 테스트

### 전체 API 테스트 실행

```bash
cd backend
./test_mock_api.sh
```

### 개별 테스트

```bash
# 1. 헬스체크
curl http://localhost:8000/api/v1/health/ | jq

# 2. 최신 재난문자 5개
curl "http://localhost:8000/api/v1/disasters/mock?limit=5" | jq

# 3. 지진 관련만
curl -G "http://localhost:8000/api/v1/disasters/mock" \
  --data-urlencode "category=지진" | jq

# 4. 통계
curl "http://localhost:8000/api/v1/disasters/mock/statistics" | jq

# 5. Mock 모드 토글
curl -X POST "http://localhost:8000/api/v1/admin/toggle-mock-mode" | jq
```

---

## 📊 데이터 구조

### CSV 파일 형식

```csv
연번,날짜,시간,구분,문자전송내용
1,2025-01-07,06:38,기상특보,"현재 1100도로 대소형 통제..."
2,2025-01-08,20:34,기상특보,"현재 1100도로 대소형 통제..."
```

### Pydantic 모델

```python
class MockDisasterMessage(BaseModel):
    serial_number: int
    date: str              # YYYY-MM-DD
    time: str              # HH:MM
    category: str          # 재난 구분
    message: str           # 문자전송내용
    issued_at: datetime    # 날짜+시간 조합
```

---

## 설정

### 환경 변수

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `USE_MOCK_DATA` | Mock 모드 활성화 여부 | `true` |
| `MOCK_DATA_PATH` | CSV 파일 경로 | `app/data/sample_disasters.csv` |

### CSV 파일 위치

```
backend/
  app/
    data/
      sample_disasters.csv  ← 이 파일
```

---

## 사용 시나리오

### 1. 개발/테스트 환경

```bash
# Mock 모드로 개발
USE_MOCK_DATA=true docker-compose up -d
```

### 2. 실제 API 복구 시

```bash
# 방법 1: 환경 변수 변경 후 재시작
USE_MOCK_DATA=false docker-compose restart backend

# 방법 2: API로 즉시 전환 (재시작 불필요)
curl -X POST http://localhost:8000/api/v1/admin/set-mock-mode \
  -H "Content-Type: application/json" \
  -d '{"enabled": false}'
```

### 3. CSV 데이터 업데이트

```bash
# 1. CSV 파일 수정
vim backend/app/data/sample_disasters.csv

# 2. 데이터 재로드 (재시작 불필요)
curl -X POST http://localhost:8000/api/v1/admin/reload-mock-data
```

---

## 📚 추가 리소스

- **Swagger API 문서**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **헬스체크**: http://localhost:8000/api/v1/health/

---

## ⚠️ 주의사항

1. **프로덕션 환경**에서는 반드시 `USE_MOCK_DATA=false`로 설정
2. **API 키**: 실제 API 사용 시 `DISASTER_API_KEY` 필요
3. **CSV 인코딩**: UTF-8 with BOM 자동 처리
4. **날짜 형식**: YYYY-MM-DD HH:MM 형식 필수

---

## 트러블슈팅

### Mock 데이터가 0개로 표시됨

```bash
# 로그 확인
docker logs pes-backend | grep -i "mock\|csv"

# 파일 존재 확인
docker exec pes-backend ls -la /app/app/data/

# 데이터 재로드
curl -X POST http://localhost:8000/api/v1/admin/reload-mock-data
```

### CSV 파싱 에러

CSV 파일의 인코딩이 UTF-8인지 확인하세요. BOM이 있어도 자동으로 처리됩니다.


