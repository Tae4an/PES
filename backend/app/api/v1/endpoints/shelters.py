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

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/nearby", response_model=ShelterSearchResponse)
async def get_nearby_shelters(
    lat: float = Query(..., ge=-90, le=90, description="위도"),
    lng: float = Query(..., ge=-180, le=180, description="경도"),
    radius: float = Query(2.0, ge=0.1, le=10.0, description="검색 반경 (km)"),
    limit: int = Query(3, ge=1, le=10, description="최대 결과 수"),
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

@router.get("/all")
async def get_all_shelters(
    page: int = Query(1, ge=1, description="페이지 번호"),
    page_size: int = Query(50, ge=1, le=100, description="페이지당 결과 수"),
    shelter_type: str = Query(None, description="대피소 유형 필터"),
    db: AsyncSession = Depends(get_shelter_db)  # 변경됨
):
    """
    전체 대피소 목록 조회 (페이징)
    
    Args:
        page: 페이지 번호 (1부터 시작)
        page_size: 페이지당 결과 수 (최대 100)
        shelter_type: 대피소 유형 필터 (예: '초등학교', '체육관', '임시대피소')
    
    Returns:
        대피소 목록 및 페이징 정보
    """
    try:
        # 전체 개수 조회
        count_query = select(func.count(Shelter.id))
        if shelter_type:
            count_query = count_query.where(Shelter.shelter_type == shelter_type)
        
        total_result = await db.execute(count_query)
        total_count = total_result.scalar()
        
        # 페이징 처리
        offset = (page - 1) * page_size
        
        # 대피소 조회
        query = select(
            Shelter.id,
            Shelter.name,
            Shelter.address,
            Shelter.shelter_type,
            Shelter.capacity,
            Shelter.area_m2,
            Shelter.phone,
            Shelter.operator,
            Shelter.has_parking,
            Shelter.has_generator,
            func.ST_Y(Shelter.location.ST_Transform(4326)).label('latitude'),
            func.ST_X(Shelter.location.ST_Transform(4326)).label('longitude')
        )
        
        if shelter_type:
            query = query.where(Shelter.shelter_type == shelter_type)
        
        query = query.order_by(Shelter.name).offset(offset).limit(page_size)
        
        result = await db.execute(query)
        rows = result.fetchall()
        
        shelters = []
        for row in rows:
            shelter = ShelterInfo(
                id=row.id,
                name=row.name,
                address=row.address,
                shelter_type=row.shelter_type,
                capacity=row.capacity,
                latitude=float(row.latitude) if row.latitude else None,
                longitude=float(row.longitude) if row.longitude else None,
                distance_km=None,
                walking_minutes=None
            )
            shelters.append(shelter)
        
        total_pages = (total_count + page_size - 1) // page_size
        
        logger.info(f"Retrieved {len(shelters)} shelters (page {page}/{total_pages})")
        
        return {
            "shelters": shelters,
            "pagination": {
                "current_page": page,
                "page_size": page_size,
                "total_count": total_count,
                "total_pages": total_pages,
                "has_next": page < total_pages,
                "has_previous": page > 1
            },
            "filter": {
                "shelter_type": shelter_type
            }
        }
        
    except Exception as e:
        logger.error(f"Error retrieving all shelters: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="대피소 목록 조회 실패"
        )


@router.get("/stats")
async def get_shelter_statistics(
    db: AsyncSession = Depends(get_shelter_db)  # 변경됨
):
    """
    대피소 통계 정보 조회
    
    Returns:
        대피소 유형별 개수, 전체 수용 인원 등
    """
    try:
        # 전체 대피소 수
        total_query = select(func.count(Shelter.id))
        total_result = await db.execute(total_query)
        total_count = total_result.scalar()
        
        # 유형별 개수
        type_query = select(
            Shelter.shelter_type,
            func.count(Shelter.id).label('count')
        ).group_by(Shelter.shelter_type).order_by(func.count(Shelter.id).desc())
        
        type_result = await db.execute(type_query)
        type_stats = [
            {"shelter_type": row.shelter_type, "count": row.count}
            for row in type_result.fetchall()
        ]
        
        # 총 수용 인원
        capacity_query = select(func.sum(Shelter.capacity))
        capacity_result = await db.execute(capacity_query)
        total_capacity = capacity_result.scalar() or 0
        
        logger.info(f"Retrieved shelter statistics: {total_count} shelters")
        
        return {
            "total_shelters": total_count,
            "total_capacity": total_capacity,
            "by_type": type_stats
        }
        
    except Exception as e:
        logger.error(f"Error retrieving shelter statistics: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="대피소 통계 조회 실패"
        )


@router.get("/types")
async def get_shelter_types(
    db: AsyncSession = Depends(get_shelter_db)  # 변경됨
):
    """
    대피소 유형 목록 조회
    
    Returns:
        데이터베이스에 존재하는 대피소 유형 목록
    """
    try:
        query = select(Shelter.shelter_type).distinct().order_by(Shelter.shelter_type)
        result = await db.execute(query)
        types = [row[0] for row in result.fetchall()]
        
        logger.info(f"Retrieved {len(types)} shelter types")
        
        return {
            "shelter_types": types,
            "count": len(types)
        }
        
    except Exception as e:
        logger.error(f"Error retrieving shelter types: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="대피소 유형 조회 실패"
        )