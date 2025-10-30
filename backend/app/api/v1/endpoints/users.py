"""
사용자 관련 API 엔드포인트 (훈련 시스템)
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime
from typing import Optional
from pydantic import BaseModel
import logging
from uuid import UUID

from ....db.session import get_db
from ....models.user import User
from ....models.training import UserPoints, TrainingSession

logger = logging.getLogger(__name__)

router = APIRouter()


# Request/Response 스키마
class RegisterOrLoginRequest(BaseModel):
    device_id: str
    fcm_token: Optional[str] = None

class LoginRequest(BaseModel):
    username: str
    password: str

class LoginResponse(BaseModel):
    user_id: str
    username: str
    nickname: str
    age_group: Optional[str]
    mobility: str
    total_points: int
    message: str


class RegisterOrLoginResponse(BaseModel):
    user_id: str
    device_id: str
    nickname: str
    age_group: Optional[str]
    mobility: str
    total_points: int
    is_new_user: bool


class UserInfoResponse(BaseModel):
    user_id: str
    nickname: str
    age_group: Optional[str]
    mobility: str
    total_points: int
    completed_trainings: int


class UpdateProfileRequest(BaseModel):
    device_id: str
    nickname: Optional[str] = None
    age_group: Optional[str] = None
    mobility: Optional[str] = None


class UpdateProfileResponse(BaseModel):
    success: bool
    message: str = "프로필이 업데이트되었습니다"


class DeleteAccountRequest(BaseModel):
    device_id: str


@router.post("/register-or-login", response_model=RegisterOrLoginResponse)
async def register_or_login(
    request: RegisterOrLoginRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    회원가입 또는 로그인 (자동)
    
    앱 실행 시 자동으로 호출됩니다.
    - device_id가 있으면 로그인
    - device_id가 없으면 자동 회원가입
    """
    try:
        # 1. device_id로 사용자 찾기
        query = select(User).where(User.device_id == request.device_id)
        result = await db.execute(query)
        user = result.scalar_one_or_none()
        
        is_new_user = False
        
        # 2. 없으면 새로 생성 (자동 회원가입)
        if not user:
            user = User(
                device_id=request.device_id,
                fcm_token=request.fcm_token,
                nickname="익명",
                age_group=None,
                mobility="정상",
                is_active=True
            )
            db.add(user)
            await db.commit()
            await db.refresh(user)
            
            # 포인트 초기화
            user_points = UserPoints(user_id=user.id, total_points=0)
            db.add(user_points)
            await db.commit()
            
            is_new_user = True
            logger.info(f"New user created: {user.device_id}")
        else:
            # 기존 사용자면 FCM 토큰만 업데이트
            if request.fcm_token:
                user.fcm_token = request.fcm_token
                user.updated_at = datetime.utcnow()
                await db.commit()
            logger.info(f"Existing user logged in: {user.device_id}")
        
        # 3. 포인트 조회
        points_query = select(UserPoints).where(UserPoints.user_id == user.id)
        points_result = await db.execute(points_query)
        points = points_result.scalar_one_or_none()
        
        if not points:
            points = UserPoints(user_id=user.id, total_points=0)
            db.add(points)
            await db.commit()
        
        return RegisterOrLoginResponse(
            user_id=str(user.id),
            device_id=user.device_id,
            nickname=user.nickname or "익명",
            age_group=user.age_group,
            mobility=user.mobility or "정상",
            total_points=points.total_points,
            is_new_user=is_new_user
        )
        
    except Exception as e:
        logger.error(f"Error in register_or_login: {str(e)}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"로그인 처리 실패: {str(e)}"
        )


@router.post("/login", response_model=LoginResponse)
async def login(
    request: LoginRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    간단한 ID/PW 로그인
    """
    try:
        # 사용자 찾기
        query = select(User).where(
            User.username == request.username,
            User.password == request.password
        )
        result = await db.execute(query)
        user = result.scalar_one_or_none()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="아이디 또는 비밀번호가 잘못되었습니다"
            )
        
        # 포인트 조회
        points_query = select(UserPoints).where(UserPoints.user_id == user.id)
        points_result = await db.execute(points_query)
        points = points_result.scalar_one_or_none()
        
        if not points:
            points = UserPoints(user_id=user.id, total_points=0)
            db.add(points)
            await db.commit()
        
        logger.info(f"로그인 성공: username={request.username}, user_id={user.id}")
        
        return LoginResponse(
            user_id=str(user.id),
            username=user.username,
            nickname=user.nickname or "익명",
            age_group=user.age_group,
            mobility=user.mobility or "정상",
            total_points=points.total_points,
            message="로그인 성공"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in login: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"로그인 실패: {str(e)}"
        )


@router.get("/me/{device_id}", response_model=UserInfoResponse)
async def get_my_info(
    device_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    내 정보 조회
    """
    try:
        # 사용자 찾기
        query = select(User).where(User.device_id == device_id)
        result = await db.execute(query)
        user = result.scalar_one_or_none()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="사용자를 찾을 수 없습니다"
            )
        
        # 포인트 조회
        points_query = select(UserPoints).where(UserPoints.user_id == user.id)
        points_result = await db.execute(points_query)
        points = points_result.scalar_one_or_none()
        
        # 완료한 훈련 횟수 조회
        completed_query = select(TrainingSession).where(
            TrainingSession.user_id == user.id,
            TrainingSession.status == 'completed'
        )
        completed_result = await db.execute(completed_query)
        completed_count = len(completed_result.scalars().all())
        
        return UserInfoResponse(
            user_id=str(user.id),
            nickname=user.nickname or "익명",
            age_group=user.age_group,
            mobility=user.mobility or "정상",
            total_points=points.total_points if points else 0,
            completed_trainings=completed_count
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting user info: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="사용자 정보 조회 실패"
        )


@router.put("/profile", response_model=UpdateProfileResponse)
async def update_profile(
    request: UpdateProfileRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    프로필 업데이트
    """
    try:
        # 사용자 찾기
        query = select(User).where(User.device_id == request.device_id)
        result = await db.execute(query)
        user = result.scalar_one_or_none()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="사용자를 찾을 수 없습니다"
            )
        
        # 프로필 업데이트
        if request.nickname is not None:
            user.nickname = request.nickname
        if request.age_group is not None:
            user.age_group = request.age_group
        if request.mobility is not None:
            user.mobility = request.mobility
        
        user.updated_at = datetime.utcnow()
        await db.commit()
        
        logger.info(f"Profile updated for user: {user.device_id}")
        
        return UpdateProfileResponse(
            success=True,
            message="프로필이 업데이트되었습니다"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating profile: {str(e)}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="프로필 업데이트 실패"
        )


@router.delete("/account", status_code=status.HTTP_200_OK)
async def delete_account(
    request: DeleteAccountRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    회원 탈퇴
    
    사용자와 관련된 모든 데이터가 삭제됩니다 (CASCADE).
    """
    try:
        # 사용자 찾기
        query = select(User).where(User.device_id == request.device_id)
        result = await db.execute(query)
        user = result.scalar_one_or_none()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="사용자를 찾을 수 없습니다"
            )
        
        # 사용자 삭제 (CASCADE로 관련 데이터 자동 삭제)
        await db.delete(user)
        await db.commit()
        
        logger.info(f"User deleted: {request.device_id}")
        
        return {"success": True, "message": "회원 탈퇴가 완료되었습니다"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting account: {str(e)}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="회원 탈퇴 처리 실패"
        )

