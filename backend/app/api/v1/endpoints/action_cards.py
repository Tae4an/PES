from fastapi import APIRouter, HTTPException, status, Query
from typing import List, Optional
from pydantic import BaseModel
import logging
from datetime import datetime
from uuid import UUID, uuid4

from ....services.llm_service import LLMService
from ...v1.schemas.shelter import ShelterInfo

logger = logging.getLogger(__name__)

router = APIRouter()

# LLM 서비스 초기화
llm_service = LLMService()

# Action Card 요청 모델
class ActionCardRequest(BaseModel):
    disaster_id: int
    latitude: float
    longitude: float
    age_group: str
    mobility: str

# Action Card 응답 모델
class ActionCardResponse(BaseModel):
    id: str
    disaster_id: int
    title: str
    description: str
    priority: str
    estimated_time: int  # 분 단위
    steps: List[str]
    emergency_contacts: List[str]
    created_at: str

@router.post("/generate", response_model=ActionCardResponse)
async def generate_action_card(request: ActionCardRequest):
    """
    재난 상황에 따른 개인화된 행동 지침 카드 생성 (AI 기반)
    
    - disaster_id: 재난 ID
    - latitude, longitude: 사용자 현재 위치
    - age_group: 연령대 (예: "20~40대", "40~60대", "60대 이상")
    - mobility: 이동능력 (예: "normal", "limited", "wheelchair")
    
    **AI 모델 (Ollama Qwen3 8B)**을 사용하여 실시간으로 개인화된 행동 지침을 생성합니다.
    AI 서비스가 실패할 경우 검증된 행정안전부 기본 템플릿을 제공합니다.
    
    **예시:**
    ```json
    {
        "disaster_id": 55,
        "latitude": 37.785834,
        "longitude": -122.406417,
        "age_group": "20~40대",
        "mobility": "normal"
    }
    ```
    """
    try:
        logger.info(f"🚀 Action Card 생성 요청: disaster_id={request.disaster_id}, location=({request.latitude}, {request.longitude})")
        
        # 1. 재난 정보 조회 (Mock - 실제로는 DB에서)
        disaster_type = _get_disaster_type(request.disaster_id)
        location = "제주도"  # Mock 위치
        logger.info(f"📍 재난 유형: {disaster_type}, 위치: {location}")
        
        # 2. 주변 대피소 검색 (Mock - 실제로는 ShelterFinder 사용)
        shelters = _get_mock_shelters(request.latitude, request.longitude)
        logger.info(f"🏠 대피소 {len(shelters)}개 검색됨")
        
        # 3. 사용자 프로필
        user_profile = {
            "age_group": request.age_group,
            "mobility": request.mobility
        }
        logger.info(f"👤 사용자 프로필: {user_profile}")
        
        # 4. AI 기반 행동 카드 생성
        logger.info("🤖 LLM Service 호출 시작...")
        action_text, generation_method = await llm_service.generate_action_card(
            disaster_type=disaster_type,
            location=location,
            user_profile=user_profile,
            shelters=shelters
        )
        logger.info(f"📝 생성 완료: method={generation_method}, text_length={len(action_text)}")
        
        # 5. 응답 생성
        action_card = _build_action_card_response(
            request=request,
            disaster_type=disaster_type,
            action_text=action_text,
            shelters=shelters,
            generation_method=generation_method
        )
        
        logger.info(f"✅ Action Card 생성 완료: {action_card.id} (method: {generation_method})")
        return action_card
        
    except Exception as e:
        logger.error(f"❌ Action Card 생성 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Action Card 생성 실패: {str(e)}"
        )

def _get_disaster_type(disaster_id: int) -> str:
    """재난 ID로부터 재난 유형 조회 (Mock)"""
    # 실제로는 DB에서 조회
    return "산불"

def _get_mock_shelters(latitude: float, longitude: float) -> List[ShelterInfo]:
    """Mock 대피소 정보 생성"""
    # 실제로는 ShelterFinder.get_shelters_within_radius() 사용
    return [
        ShelterInfo(
            id=uuid4(),
            name="제주시민회관 대피소",
            address="제주시 동광로 20",
            shelter_type="지진해일대피소",
            capacity=200,
            latitude=33.5010,
            longitude=126.5314,
            distance_km=0.8,
            walking_minutes=10
        ),
        ShelterInfo(
            id=uuid4(),
            name="제주도청 비상대피소",
            address="제주시 문연로 6",
            shelter_type="민방위대피소",
            capacity=150,
            latitude=33.4890,
            longitude=126.5012,
            distance_km=1.2,
            walking_minutes=15
        ),
        ShelterInfo(
            id=uuid4(),
            name="제주중앙초등학교 대피소",
            address="제주시 중앙로 213",
            shelter_type="지진해일대피소",
            capacity=300,
            latitude=33.5120,
            longitude=126.5218,
            distance_km=1.5,
            walking_minutes=18
        )
    ]

def _build_action_card_response(
    request: ActionCardRequest,
    disaster_type: str,
    action_text: str,
    shelters: List[ShelterInfo],
    generation_method: str
) -> ActionCardResponse:
    """행동 카드 응답 생성"""
    
    # Action Card ID 생성
    card_id = f"card_{request.disaster_id}_{int(request.latitude * 1000)}_{int(request.longitude * 1000)}_{generation_method}"
    
    # 행동 단계 추출 (각 줄을 단계로)
    steps = [line.strip() for line in action_text.split('\n') if line.strip() and not line.startswith('🚨')]
    
    # 제목 추출 (첫 줄 또는 기본 제목)
    if steps and '경보' in steps[0]:
        title = steps[0].replace('🚨', '').strip()
        steps = steps[1:]  # 제목 제외
    else:
        title = f"{disaster_type} 대피 행동 지침"
    
    # 설명 생성
    if shelters:
        description = f"{disaster_type} 발생! 가장 가까운 대피소는 {shelters[0].name} (도보 {shelters[0].walking_minutes}분)"
    else:
        description = f"{disaster_type} 발생! 즉시 안전한 곳으로 대피하세요."
    
    # 우선순위 결정
    priority_map = {
        "지진": "critical",
        "화재": "critical",
        "산불": "high",
        "태풍": "high",
        "호우": "medium"
    }
    priority = priority_map.get(disaster_type, "high")
    
    # 예상 소요 시간 (가장 가까운 대피소까지 시간)
    estimated_time = shelters[0].walking_minutes if shelters else 15
    
    return ActionCardResponse(
        id=card_id,
        disaster_id=request.disaster_id,
        title=title,
        description=description,
        priority=priority,
        estimated_time=estimated_time,
        steps=steps[:5],  # 최대 5개 단계
        emergency_contacts=["119", "112", "제주도청 064-710-2114"],
        created_at=datetime.now().isoformat()
    )

@router.get("/{card_id}", response_model=ActionCardResponse)
async def get_action_card(card_id: str):
    """
    특정 Action Card 조회
    """
    try:
        # Mock 데이터 반환 (실제로는 DB에서 조회)
        mock_card = ActionCardResponse(
            id=card_id,
            disaster_id=55,
            title="산불 대피 행동 지침",
            description="건조특보 발효 중 산불 위험이 높습니다.",
            priority="high",
            estimated_time=15,
            steps=[
                "현재 위치에서 가장 가까운 대피소로 이동",
                "마스크를 착용하여 연기에 노출되지 않도록 주의",
                "대피소 도착 후 안전 확인 및 가족에게 연락"
            ],
            emergency_contacts=["119", "112", "제주도청 064-710-2114"],
            created_at=datetime.now().isoformat()
        )
        
        logger.info(f"✅ Action Card 조회 완료: {card_id}")
        return mock_card
        
    except Exception as e:
        logger.error(f"❌ Action Card 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Action Card를 찾을 수 없습니다: {card_id}"
        )

@router.get("/", response_model=List[ActionCardResponse])
async def get_action_cards(
    limit: int = Query(10, ge=1, le=50, description="반환할 Action Card 개수"),
    disaster_id: Optional[int] = Query(None, description="재난 ID 필터")
):
    """
    Action Card 목록 조회
    """
    try:
        # Mock 데이터 반환
        mock_cards = [
            ActionCardResponse(
                id="card_55_37785_122406_llm",
                disaster_id=55,
                title="산불 대피 행동 지침",
                description="건조특보 발효 중 산불 위험이 높습니다.",
                priority="high",
                estimated_time=15,
                steps=[
                    "현재 위치에서 가장 가까운 대피소로 이동",
                    "마스크를 착용하여 연기에 노출되지 않도록 주의"
                ],
                emergency_contacts=["119", "112"],
                created_at=datetime.now().isoformat()
            )
        ]
        
        logger.info(f"✅ Action Card 목록 조회 완료: {len(mock_cards)}개")
        return mock_cards[:limit]
        
    except Exception as e:
        logger.error(f"❌ Action Card 목록 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Action Card 목록 조회 실패: {str(e)}"
        )
