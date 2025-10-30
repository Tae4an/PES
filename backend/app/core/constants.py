"""
훈련 시스템 상수 정의
"""

# 보상 목록 (하드코딩)
REWARDS = [
    {
        "id": "reward_1",
        "partner": "올리브영",
        "name": "3,000원 할인 쿠폰",
        "points": 300,
        "image": "oliveyoung.png",
        "description": "올리브영 전 매장에서 사용 가능한 3,000원 할인 쿠폰"
    },
    {
        "id": "reward_2",
        "partner": "스타벅스",
        "name": "아메리카노 쿠폰",
        "points": 500,
        "image": "starbucks.png",
        "description": "전국 스타벅스 매장에서 사용 가능한 아메리카노 쿠폰"
    },
    {
        "id": "reward_3",
        "partner": "GS25",
        "name": "2,000원 상품권",
        "points": 200,
        "image": "gs25.png",
        "description": "GS25 편의점에서 사용 가능한 2,000원 상품권"
    },
    {
        "id": "reward_4",
        "partner": "CU",
        "name": "3,000원 상품권",
        "points": 300,
        "image": "cu.png",
        "description": "CU 편의점에서 사용 가능한 3,000원 상품권"
    },
    {
        "id": "reward_5",
        "partner": "배달의민족",
        "name": "5,000원 할인 쿠폰",
        "points": 500,
        "image": "baemin.png",
        "description": "배달의민족 앱에서 사용 가능한 5,000원 할인 쿠폰"
    }
]

# 포인트 정책
TRAINING_COMPLETION_POINTS = 100  # 훈련 완료 시 지급 포인트
COMPLETION_DISTANCE_METERS = 10   # 완료 인정 거리 (미터)

# 연령대 옵션
AGE_GROUPS = ["10대", "20대", "30대", "40대", "50대", "60대 이상"]

# 거동 옵션
MOBILITY_OPTIONS = ["정상", "노약자", "휠체어", "목발", "유모차"]

