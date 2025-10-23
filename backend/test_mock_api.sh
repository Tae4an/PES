#!/bin/bash
# Mock API 테스트 스크립트

BASE_URL="http://localhost:8000/api/v1"

echo "=========================================="
echo "PES Mock API 테스트"
echo "=========================================="
echo ""

echo "1️⃣  헬스체크 (현재 모드 확인)"
echo "---"
curl -s "${BASE_URL}/health/" | jq
echo ""
echo ""

echo "2️⃣  최신 재난문자 5개 조회"
echo "---"
curl -s "${BASE_URL}/disasters/mock?limit=5" | jq '.[0:2]'
echo ""
echo ""

echo "3️⃣  지진 관련 재난문자만 조회"
echo "---"
curl -s -G "${BASE_URL}/disasters/mock" \
  --data-urlencode "category=지진" \
  --data-urlencode "limit=10" | jq
echo ""
echo ""

echo "4️⃣  날짜 범위로 조회 (2025-01-10 ~ 2025-01-15)"
echo "---"
curl -s -G "${BASE_URL}/disasters/mock" \
  --data-urlencode "start_date=2025-01-10" \
  --data-urlencode "end_date=2025-01-15" \
  --data-urlencode "limit=10" | jq '. | length'
echo " 건의 재난문자"
echo ""
echo ""

echo "5️⃣  재난 통계 정보"
echo "---"
curl -s "${BASE_URL}/disasters/mock/statistics" | jq
echo ""
echo ""

echo "6️⃣  Mock 모드 상태 확인"
echo "---"
curl -s "${BASE_URL}/admin/mock-mode-status" | jq
echo ""
echo ""

echo "7️⃣  Mock → Real API 모드 전환"
echo "---"
curl -s -X POST "${BASE_URL}/admin/toggle-mock-mode" | jq
echo ""
echo ""

echo "8️⃣  헬스체크 (Real API 모드 확인)"
echo "---"
curl -s "${BASE_URL}/health/" | jq
echo ""
echo ""

echo "9️⃣  Real API → Mock 모드 전환 (명시적 설정)"
echo "---"
curl -s -X POST "${BASE_URL}/admin/set-mock-mode" \
  -H "Content-Type: application/json" \
  -d '{"enabled": true}' | jq
echo ""
echo ""

echo "🔟  최종 헬스체크 (Mock 모드 복원 확인)"
echo "---"
curl -s "${BASE_URL}/health/" | jq
echo ""
echo ""

echo "=========================================="
echo "✅ 테스트 완료!"
echo "=========================================="
echo ""
echo "📚 API 문서: http://localhost:8000/docs"
echo ""

