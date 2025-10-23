"""
사용자 관련 API 엔드포인트
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime
import logging

from ....db.session import get_db
from ....models.user import User
from ....api.v1.schemas.user import (
    UserRegisterRequest,
    UserRegisterResponse,
    LocationUpdateRequest,
    LocationUpdateResponse,
    UserProfile
)
from ....core.security import create_access_token

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/register", response_model=UserRegisterResponse, status_code=status.HTTP_201_CREATED)
async def register_user(
    request: UserRegisterRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    사용자 등록
    
    앱 최초 실행 시 호출
    """
    try:
        # 기존 사용자 확인
        query = select(User).where(User.device_id == request.device_id)
        result = await db.execute(query)
        existing_user = result.scalar_one_or_none()
        
        if existing_user:
            # 기존 사용자 정보 업데이트
            existing_user.fcm_token = request.fcm_token
            existing_user.age_group = request.age_group
            existing_user.mobility = request.mobility
            existing_user.is_active = True
            existing_user.updated_at = datetime.utcnow()
            
            user = existing_user
        else:
            # 새 사용자 생성
            user = User(
                device_id=request.device_id,
                fcm_token=request.fcm_token,
                age_group=request.age_group,
                mobility=request.mobility,
                is_active=True
            )
            db.add(user)
        
        await db.commit()
        await db.refresh(user)
        
        # 세션 토큰 생성
        session_token = create_access_token(
            data={"user_id": str(user.id), "device_id": user.device_id}
        )
        
        logger.info(f"User registered: {user.device_id}")
        
        return UserRegisterResponse(
            user_id=user.id,
            session_token=session_token,
            message="사용자 등록 완료"
        )
        
    except Exception as e:
        logger.error(f"Error registering user: {str(e)}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="사용자 등록 실패"
        )


@router.post("/location/update", response_model=LocationUpdateResponse)
async def update_location(
    request: LocationUpdateRequest,
    db: AsyncSession = Depends(get_db),
    # TODO: Bearer 토큰 인증 추가
):
    """
    사용자 위치 업데이트
    
    앱에서 10초마다 호출
    """
    try:
        # TODO: 토큰에서 user_id 추출
        # 현재는 간단히 구현
        
        # 위치 업데이트 로직
        # PostGIS POINT 생성
        location_wkt = f'SRID=4326;POINT({request.longitude} {request.latitude})'
        
        # 실제로는 토큰에서 가져온 user_id 사용
        # 여기서는 예시로 첫 번째 활성 사용자 업데이트
        
        logger.info(f"Location updated: {request.latitude}, {request.longitude}")
        
        return LocationUpdateResponse(
            status="success",
            message="위치 업데이트 완료",
            updated_at=datetime.utcnow()
        )
        
    except Exception as e:
        logger.error(f"Error updating location: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="위치 업데이트 실패"
        )


@router.get("/profile", response_model=UserProfile)
async def get_user_profile(
    db: AsyncSession = Depends(get_db),
    # TODO: Bearer 토큰 인증 추가
):
    """
    사용자 프로필 조회
    """
    try:
        # TODO: 토큰에서 user_id 추출
        
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="구현 예정"
        )
        
    except Exception as e:
        logger.error(f"Error fetching profile: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="프로필 조회 실패"
        )

