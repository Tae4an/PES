"""
대피소 관련 API 엔드포인트
"""
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
import logging

from ....db.session import get_db
from ....services.shelter_finder import ShelterFinder
from ....api.v1.schemas.shelter import ShelterSearchResponse

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/nearby", response_model=ShelterSearchResponse)
async def get_nearby_shelters(
    lat: float = Query(..., ge=-90, le=90, description="위도"),
    lng: float = Query(..., ge=-180, le=180, description="경도"),
    radius: float = Query(2.0, ge=0.1, le=10.0, description="검색 반경 (km)"),
    limit: int = Query(3, ge=1, le=10, description="최대 결과 수"),
    db: AsyncSession = Depends(get_db)
):
    """
    현재 위치 기반 주변 대피소 검색
    
    Args:
        lat: 위도
        lng: 경도
        radius: 검색 반경 (km)
        limit: 최대 결과 수
    
    Returns:
        주변 대피소 목록 (거리 순 정렬)
    """
    try:
        shelter_finder = ShelterFinder(db)
        
        shelters = await shelter_finder.get_shelters_within_radius(
            latitude=lat,
            longitude=lng,
            radius_km=radius,
            limit=limit
        )
        
        logger.info(f"Found {len(shelters)} shelters near ({lat}, {lng})")
        
        return ShelterSearchResponse(
            shelters=shelters,
            total_count=len(shelters),
            search_radius_km=radius
        )
        
    except Exception as e:
        logger.error(f"Error searching shelters: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="대피소 검색 실패"
        )

