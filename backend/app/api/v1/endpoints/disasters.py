"""
재난 관련 API 엔드포인트
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from datetime import datetime
import logging

from ....db.session import get_db
from ....services.llm_service import LLMService
from ....services.shelter_finder import ShelterFinder
from ....services.disaster_service import disaster_service
from ....api.v1.schemas.disaster import (
    ActionCardGenerateRequest,
    ActionCardResponse,
    MockDisasterMessage
)

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


@router.get("/active", response_model=List[MockDisasterMessage])
async def get_active_disasters(
    limit: int = Query(5, ge=1, le=50, description="반환할 재난문자 개수"),
    latitude: Optional[float] = Query(None, description="사용자 위도"),
    longitude: Optional[float] = Query(None, description="사용자 경도")
):
    """
    현재 활성화된 재난 정보 조회
    
    - Mock 모드: CSV 파일에서 최신 재난문자 반환
    - Real API 모드: 실제 재난문자 API 호출
    - 위치 정보가 있으면 해당 지역 재난 우선 반환
    
    **예시:**
    - `/api/v1/disasters/active?limit=10` - 최신 10개
    - `/api/v1/disasters/active?latitude=37.5&longitude=127.0&limit=5` - 내 위치 기준 5개
    """
    try:
        # Mock 모드에서는 최신 재난문자 반환
        disasters = disaster_service.get_mock_disasters(limit=limit)
        
        # TODO: 위치 기반 필터링 (향후 구현)
        # if latitude and longitude:
        #     disasters = filter_by_location(disasters, latitude, longitude)
        
        logger.info(f"✅ 활성 재난 조회: {len(disasters)}개 반환")
        return disasters
    
    except Exception as e:
        logger.error(f"❌ 활성 재난 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"재난 조회 실패: {str(e)}"
        )


@router.get("/mock", response_model=List[MockDisasterMessage])
async def get_mock_disasters(
    limit: int = Query(5, ge=1, le=50, description="반환할 재난문자 개수"),
    category: Optional[str] = Query(None, description="재난 구분 필터 (기상특보, 지진, 교통, 사회재난)"),
    start_date: Optional[str] = Query(None, description="시작 날짜 (YYYY-MM-DD)"),
    end_date: Optional[str] = Query(None, description="종료 날짜 (YYYY-MM-DD)")
):
    """
    Mock 재난문자 조회 (CSV 기반)
    
    **환경변수 USE_MOCK_DATA=true 일 때 사용**
    
    - 최신 재난문자부터 반환
    - 카테고리/날짜 범위로 필터링 가능
    - 실제 API 복구 시 자동 전환
    
    **예시:**
    - `/api/v1/disasters/mock?limit=10` - 최신 10개
    - `/api/v1/disasters/mock?category=지진` - 지진 관련만
    - `/api/v1/disasters/mock?start_date=2025-01-10&end_date=2025-01-15` - 날짜 범위
    """
    try:
        # Mock 모드가 아닐 경우 경고
        if not disaster_service.is_mock_mode:
            logger.warning("⚠️  Mock 모드가 비활성화되어 있습니다. 실제 API를 사용 중입니다.")
        
        # 필터링 조건이 있으면 필터링, 없으면 최신 N개
        if category or start_date or end_date:
            disasters = disaster_service.filter_mock_disasters(
                category=category,
                start_date=start_date,
                end_date=end_date
            )
            # 필터링 후 limit 적용
            return disasters[:limit]
        else:
            return disaster_service.get_mock_disasters(limit=limit)
    
    except Exception as e:
        logger.error(f"❌ Mock 재난문자 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"재난문자 조회 실패: {str(e)}"
        )


@router.get("/mock/all", response_model=List[MockDisasterMessage])
async def get_all_mock_disasters():
    """
    전체 Mock 재난문자 조회
    
    **CSV 파일의 모든 재난문자를 반환**
    
    - 최신순 정렬
    - 통계 분석 및 테스트용
    """
    try:
        disasters = disaster_service.get_all_mock_disasters()
        
        logger.info(f"✅ 전체 Mock 재난문자 반환: {len(disasters)}개")
        
        return disasters
    
    except Exception as e:
        logger.error(f"❌ 전체 Mock 재난문자 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"재난문자 조회 실패: {str(e)}"
        )


@router.get("/mock/statistics")
async def get_disaster_statistics():
    """
    재난 통계 정보
    
    **카테고리별 재난 발생 건수를 반환**
    
    - 기상특보, 지진, 교통, 사회재난 등 분류별 집계
    - 데이터 분석 및 대시보드용
    """
    try:
        stats = disaster_service.get_disaster_statistics()
        total = sum(stats.values())
        
        return {
            "total_disasters": total,
            "by_category": stats,
            "data_source": disaster_service.data_source,
            "mock_mode": disaster_service.is_mock_mode
        }
    
    except Exception as e:
        logger.error(f"❌ 재난 통계 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"통계 조회 실패: {str(e)}"
        )

