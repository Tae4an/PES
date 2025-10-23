"""
재난 관련 API 엔드포인트
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime
import logging

from ....db.session import get_db
from ....services.llm_service import LLMService
from ....services.shelter_finder import ShelterFinder
from ....api.v1.schemas.disaster import ActionCardGenerateRequest, ActionCardResponse

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/action-card/generate", response_model=ActionCardResponse)
async def generate_action_card(
    request: ActionCardGenerateRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    행동카드 생성 (테스트용)
    
    LLM을 사용하여 개인화된 재난 행동카드 생성
    """
    try:
        # 주변 대피소 검색
        shelter_finder = ShelterFinder(db)
        shelters = await shelter_finder.get_shelters_within_radius(
            latitude=request.user_latitude,
            longitude=request.user_longitude,
            radius_km=2.0,
            limit=3
        )
        
        # LLM으로 행동카드 생성
        llm_service = LLMService()
        
        user_profile = {
            "age_group": request.age_group,
            "mobility": request.mobility
        }
        
        action_card, generation_method = await llm_service.generate_action_card(
            disaster_type=request.disaster_type,
            location=request.location,
            user_profile=user_profile,
            shelters=shelters
        )
        
        logger.info(f"Action card generated via {generation_method}")
        
        return ActionCardResponse(
            action_card=action_card,
            shelters=[
                {
                    "name": s.name,
                    "address": s.address,
                    "distance_km": s.distance_km,
                    "walking_minutes": s.walking_minutes
                }
                for s in shelters
            ],
            generated_at=datetime.utcnow(),
            generation_method=generation_method
        )
        
    except Exception as e:
        logger.error(f"Error generating action card: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="행동카드 생성 실패"
        )

