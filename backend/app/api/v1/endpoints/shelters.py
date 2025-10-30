"""
대피소 관련 API 엔드포인트
"""
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
import logging

from ....db.session import get_shelter_db  # get_db -> get_shelter_db로 변경
from ....services.shelter_finder import ShelterFinder
from ....api.v1.schemas.shelter import ShelterSearchResponse, ShelterInfo
from ....models.shelter import Shelter

from ....api.v1.schemas.shelter import (
    ShelterInfo,
    ShelterSearchResponse,
    DisasterType,
    DisasterShelterSearchResponse
)

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/nearby", response_model=ShelterSearchResponse)
async def get_nearby_shelters(
    lat: float = Query(..., ge=-90, le=90, description="위도"),
    lng: float = Query(..., ge=-180, le=180, description="경도"),
    radius: float = Query(10.0, ge=0.1, le=10.0, description="검색 반경 (km)"),
    limit: int = Query(5, ge=1, le=10, description="최대 결과 수"),
    db: AsyncSession = Depends(get_shelter_db)  # 변경됨
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
        
@router.get("/by-disaster/{disaster_type}", response_model=DisasterShelterSearchResponse)
async def get_shelters_by_disaster_type(
    disaster_type: DisasterType,
    lat: float = Query(..., ge=-90, le=90, description="위도"),
    lng: float = Query(..., ge=-180, le=180, description="경도"),
    radius: float = Query(10.0, ge=0.1, le=50.0, description="검색 반경 (km)"),
    limit: int = Query(5, ge=1, le=20, description="최대 결과 수"),
    db: AsyncSession = Depends(get_shelter_db)
):
    """
    재난 유형별 대피소 검색
    
    Args:
        disaster_type: 재난 유형 (민방위, 지진, 해일, 기타)
        lat: 사용자 위도
        lng: 사용자 경도
        radius: 검색 반경 (km, 기본 10km)
        limit: 최대 결과 수 (기본 5개)
    
    Returns:
        해당 재난 유형의 대피소 목록 (거리순 정렬)
    
    Examples:
        - GET /api/v1/shelters/by-disaster/민방위?lat=37.295692&lng=126.841425
        - GET /api/v1/shelters/by-disaster/지진?lat=37.295692&lng=126.841425&radius=5.0&limit=3
    """
    try:
        shelter_finder = ShelterFinder(db)
        
        shelters = await shelter_finder.get_shelters_by_disaster_type(
            disaster_type=disaster_type.value,
            latitude=lat,
            longitude=lng,
            radius_km=radius,
            limit=limit
        )
        
        logger.info(f"Found {len(shelters)} shelters for disaster type '{disaster_type.value}' near ({lat}, {lng})")
        
        return DisasterShelterSearchResponse(
            disaster_type=disaster_type.value,
            shelters=shelters,
            total_count=len(shelters),
            search_radius_km=radius
        )
        
    except Exception as e:
        logger.error(f"Error retrieving shelters by disaster type: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"재난 유형별 대피소 검색 실패: {str(e)}"
        )