"""
훈련 시스템 API 엔드포인트
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, text
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel
import logging
from math import radians, sin, cos, sqrt, atan2

from ....db.session import get_db, get_shelter_db
from ....models.user import User
from ....models.shelter import Shelter
from ....models.training import TrainingSession, UserPoints
from ....core.constants import TRAINING_COMPLETION_POINTS, COMPLETION_DISTANCE_METERS
from ....services.shelter_finder import ShelterFinder

logger = logging.getLogger(__name__)

router = APIRouter()


# Request/Response 스키마
class ShelterInfo(BaseModel):
    id: str
    name: str
    address: str
    shelter_type: str
    latitude: float
    longitude: float
    distance: float  # 미터 단위


class NearbySheltersResponse(BaseModel):
    shelters: List[ShelterInfo]


class StartTrainingRequest(BaseModel):
    device_id: str
    shelter_id: str
    latitude: float
    longitude: float


class StartTrainingResponse(BaseModel):
    session_id: int
    user_id: str
    shelter: ShelterInfo
    initial_distance: float


class CheckCompletionRequest(BaseModel):
    session_id: int
    latitude: float
    longitude: float


class CheckCompletionResponse(BaseModel):
    is_completed: bool
    distance: float
    points_earned: Optional[int] = None
    total_points: Optional[int] = None
    message: str


class TrainingHistoryItem(BaseModel):
    session_id: int
    shelter_name: str
    completed_at: Optional[datetime]
    points_earned: int


class TrainingHistoryResponse(BaseModel):
    history: List[TrainingHistoryItem]


# 거리 계산 함수 (Haversine Formula)
def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    두 좌표 간의 거리를 미터 단위로 계산
    
    Args:
        lat1, lon1: 첫 번째 좌표 (위도, 경도)
        lat2, lon2: 두 번째 좌표 (위도, 경도)
    
    Returns:
        거리 (미터)
    """
    R = 6371000  # 지구 반지름 (미터)
    
    phi1 = radians(lat1)
    phi2 = radians(lat2)
    delta_phi = radians(lat2 - lat1)
    delta_lambda = radians(lon2 - lon1)
    
    a = sin(delta_phi/2)**2 + cos(phi1) * cos(phi2) * sin(delta_lambda/2)**2
    c = 2 * atan2(sqrt(a), sqrt(1-a))
    
    return R * c


@router.get("/nearby-shelters", response_model=NearbySheltersResponse)
async def get_nearby_shelters(
    latitude: float = Query(..., description="현재 위도"),
    longitude: float = Query(..., description="현재 경도"),
    limit: int = Query(5, ge=1, le=10, description="반환할 대피소 수"),
    shelter_db: AsyncSession = Depends(get_shelter_db)
):
    """
    현재 위치 기반 가까운 대피소 조회
    
    ID를 포함한 대피소 정보를 반환합니다.
    """
    try:
        # ID를 포함한 쿼리
        query = text("""
            SELECT 
                id,
                name,
                address,
                shelter_type,
                latitude,
                longitude,
                distance_km
            FROM (
                SELECT 
                    id,
                    name,
                    address,
                    shelter_type,
                    latitude,
                    longitude,
                    (
                        6371 * acos(
                            LEAST(1.0, 
                                cos(radians(:user_lat)) * cos(radians(latitude)) *
                                cos(radians(longitude) - radians(:user_lng)) +
                                sin(radians(:user_lat)) * sin(radians(latitude))
                            )
                        )
                    ) AS distance_km
                FROM shelters
                WHERE latitude IS NOT NULL
                  AND longitude IS NOT NULL
            ) AS shelter_distances
            WHERE distance_km <= :radius_km
            ORDER BY distance_km ASC
            LIMIT :limit
        """)
        
        result = await shelter_db.execute(
            query,
            {
                "user_lat": latitude,
                "user_lng": longitude,
                "radius_km": 10.0,
                "limit": limit
            }
        )
        
        rows = result.fetchall()
        
        shelters = []
        for row in rows:
            shelters.append(ShelterInfo(
                id=str(row.id),
                name=row.name,
                address=row.address,
                shelter_type=row.shelter_type,
                latitude=float(row.latitude),
                longitude=float(row.longitude),
                distance=float(row.distance_km) * 1000  # km를 미터로 변환
            ))
        
        logger.info(f"Found {len(shelters)} nearby shelters")
        return NearbySheltersResponse(shelters=shelters)
        
    except Exception as e:
        logger.error(f"Error getting nearby shelters: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"대피소 조회 실패: {str(e)}"
        )


@router.post("/start", response_model=StartTrainingResponse)
async def start_training(
    request: StartTrainingRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    훈련 시작
    """
    try:
        # 1. 사용자 확인 (device_id 또는 username으로 찾기)
        user_query = select(User).where(
            (User.device_id == request.device_id) | (User.username == request.device_id)
        )
        user_result = await db.execute(user_query)
        user = user_result.scalar_one_or_none()
        
        if not user:
            logger.error(f"사용자를 찾을 수 없음: device_id={request.device_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="사용자를 찾을 수 없습니다"
            )
        
        # 2. 대피소 확인
        shelter_query = select(Shelter).where(Shelter.id == request.shelter_id)
        shelter_result = await db.execute(shelter_query)
        shelter = shelter_result.scalar_one_or_none()
        
        if not shelter:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="대피소를 찾을 수 없습니다"
            )
        
        # 3. 대피소 위치 추출 (PostGIS)
        location_query = text(f"""
            SELECT 
                ST_Y(location::geometry) as latitude,
                ST_X(location::geometry) as longitude
            FROM shelters
            WHERE id = :shelter_id
        """)
        location_result = await db.execute(location_query, {"shelter_id": request.shelter_id})
        location_row = location_result.fetchone()
        
        shelter_lat = location_row.latitude
        shelter_lon = location_row.longitude
        
        # 4. 초기 거리 계산
        initial_distance = calculate_distance(
            request.latitude, request.longitude,
            shelter_lat, shelter_lon
        )
        
        # 5. 훈련 세션 생성
        training_session = TrainingSession(
            user_id=user.id,
            shelter_id=shelter.id,
            shelter_name=shelter.name,
            status='ongoing',
            started_at=datetime.utcnow()
        )
        db.add(training_session)
        await db.commit()
        await db.refresh(training_session)
        
        logger.info(f"Training started: session_id={training_session.id}, user={user.device_id}")
        
        return StartTrainingResponse(
            session_id=training_session.id,
            user_id=str(user.id),
            shelter=ShelterInfo(
                id=str(shelter.id),
                name=shelter.name,
                address=shelter.address,
                shelter_type=shelter.shelter_type,
                latitude=shelter_lat,
                longitude=shelter_lon,
                distance=round(initial_distance, 1)
            ),
            initial_distance=round(initial_distance, 1)
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error starting training: {str(e)}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"훈련 시작 실패: {str(e)}"
        )


@router.post("/check", response_model=CheckCompletionResponse)
async def check_completion(
    request: CheckCompletionRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    훈련 완료 확인
    
    클라이언트에서 1초마다 호출하여 목표 대피소에 도달했는지 확인합니다.
    """
    try:
        # 1. 훈련 세션 확인
        session_query = select(TrainingSession).where(
            TrainingSession.id == request.session_id,
            TrainingSession.status == 'ongoing'
        )
        session_result = await db.execute(session_query)
        session = session_result.scalar_one_or_none()
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="진행 중인 훈련을 찾을 수 없습니다"
            )
        
        # 2. 대피소 위치 조회
        location_query = text(f"""
            SELECT 
                ST_Y(location::geometry) as latitude,
                ST_X(location::geometry) as longitude
            FROM shelters
            WHERE id = :shelter_id
        """)
        location_result = await db.execute(location_query, {"shelter_id": str(session.shelter_id)})
        location_row = location_result.fetchone()
        
        shelter_lat = location_row.latitude
        shelter_lon = location_row.longitude
        
        # 3. 현재 거리 계산
        distance = calculate_distance(
            request.latitude, request.longitude,
            shelter_lat, shelter_lon
        )
        
        # 4. 완료 조건 체크 (10m 이내)
        if distance <= COMPLETION_DISTANCE_METERS:
            # 훈련 완료 처리
            session.status = 'completed'
            session.completed_at = datetime.utcnow()
            session.points_earned = TRAINING_COMPLETION_POINTS
            
            # 포인트 지급
            points_query = select(UserPoints).where(UserPoints.user_id == session.user_id)
            points_result = await db.execute(points_query)
            user_points = points_result.scalar_one_or_none()
            
            if user_points:
                user_points.total_points += TRAINING_COMPLETION_POINTS
                user_points.updated_at = datetime.utcnow()
            else:
                user_points = UserPoints(
                    user_id=session.user_id,
                    total_points=TRAINING_COMPLETION_POINTS
                )
                db.add(user_points)
            
            await db.commit()
            
            logger.info(f"Training completed: session_id={session.id}, points={TRAINING_COMPLETION_POINTS}")
            
            return CheckCompletionResponse(
                is_completed=True,
                distance=round(distance, 1),
                points_earned=TRAINING_COMPLETION_POINTS,
                total_points=user_points.total_points,
                message=f"훈련 완료! {TRAINING_COMPLETION_POINTS} 포인트 획득!"
            )
        else:
            # 아직 미완료
            remaining = round(distance, 1)
            return CheckCompletionResponse(
                is_completed=False,
                distance=remaining,
                message=f"{remaining}m 남았습니다"
            )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error checking completion: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="완료 확인 실패"
        )


@router.get("/history/{device_id}", response_model=TrainingHistoryResponse)
async def get_training_history(
    device_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    훈련 기록 조회
    """
    try:
        # 사용자 찾기
        user_query = select(User).where(User.device_id == device_id)
        user_result = await db.execute(user_query)
        user = user_result.scalar_one_or_none()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="사용자를 찾을 수 없습니다"
            )
        
        # 완료된 훈련 조회
        history_query = select(TrainingSession).where(
            TrainingSession.user_id == user.id,
            TrainingSession.status == 'completed'
        ).order_by(TrainingSession.completed_at.desc())
        
        history_result = await db.execute(history_query)
        sessions = history_result.scalars().all()
        
        history = []
        for session in sessions:
            history.append(TrainingHistoryItem(
                session_id=session.id,
                shelter_name=session.shelter_name,
                completed_at=session.completed_at,
                points_earned=session.points_earned
            ))
        
        return TrainingHistoryResponse(history=history)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting training history: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="훈련 기록 조회 실패"
        )


@router.post("/abandon/{session_id}")
async def abandon_training(
    session_id: int,
    db: AsyncSession = Depends(get_db)
):
    """
    훈련 포기
    """
    try:
        session_query = select(TrainingSession).where(
            TrainingSession.id == session_id,
            TrainingSession.status == 'ongoing'
        )
        session_result = await db.execute(session_query)
        session = session_result.scalar_one_or_none()
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="진행 중인 훈련을 찾을 수 없습니다"
            )
        
        session.status = 'abandoned'
        await db.commit()
        
        logger.info(f"Training abandoned: session_id={session_id}")
        
        return {"success": True, "message": "훈련을 포기했습니다"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error abandoning training: {str(e)}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="훈련 포기 처리 실패"
        )

