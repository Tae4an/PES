"""
보상 시스템 API 엔드포인트
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime
from typing import List
from pydantic import BaseModel
import logging
import random
import string

from ....db.session import get_db
from ....models.user import User
from ....models.training import UserPoints, RewardRedemption
from ....core.constants import REWARDS

logger = logging.getLogger(__name__)

router = APIRouter()


# Request/Response 스키마
class Reward(BaseModel):
    id: str
    partner: str
    name: str
    points: int
    image: str
    description: str


class RewardsListResponse(BaseModel):
    rewards: List[Reward]


class PointsBalanceResponse(BaseModel):
    total_points: int
    completed_trainings: int


class RedeemRewardRequest(BaseModel):
    device_id: str
    reward_id: str


class RedeemRewardResponse(BaseModel):
    success: bool
    redemption_code: str
    reward_name: str
    points_spent: int
    remaining_points: int


class RedemptionCode(BaseModel):
    id: int
    reward_name: str
    redemption_code: str
    points_spent: int
    redeemed_at: datetime


class MyCodesResponse(BaseModel):
    codes: List[RedemptionCode]


def generate_redemption_code() -> str:
    """
    랜덤 교환 코드 생성
    
    형식: XXXX-XXXX-XXXX (12자리)
    """
    chars = string.ascii_uppercase + string.digits
    code = ''.join(random.choices(chars, k=12))
    # 4자리씩 나누기
    return f"{code[0:4]}-{code[4:8]}-{code[8:12]}"


@router.get("/list", response_model=RewardsListResponse)
async def get_rewards_list():
    """
    교환 가능한 보상 목록 조회
    
    하드코딩된 보상 데이터를 반환합니다.
    """
    try:
        rewards = [Reward(**reward) for reward in REWARDS]
        return RewardsListResponse(rewards=rewards)
    except Exception as e:
        logger.error(f"Error getting rewards list: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="보상 목록 조회 실패"
        )


@router.get("/points/{device_id}", response_model=PointsBalanceResponse)
async def get_points_balance(
    device_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    포인트 잔액 조회
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
        
        # 포인트 조회
        points_query = select(UserPoints).where(UserPoints.user_id == user.id)
        points_result = await db.execute(points_query)
        points = points_result.scalar_one_or_none()
        
        # 완료한 훈련 횟수 (TrainingSession에서 조회)
        from ....models.training import TrainingSession
        completed_query = select(TrainingSession).where(
            TrainingSession.user_id == user.id,
            TrainingSession.status == 'completed'
        )
        completed_result = await db.execute(completed_query)
        completed_count = len(completed_result.scalars().all())
        
        return PointsBalanceResponse(
            total_points=points.total_points if points else 0,
            completed_trainings=completed_count
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting points balance: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="포인트 조회 실패"
        )


@router.post("/redeem", response_model=RedeemRewardResponse)
async def redeem_reward(
    request: RedeemRewardRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    보상 교환
    
    포인트를 사용하여 보상을 교환하고 랜덤 코드를 발급합니다.
    """
    try:
        # 1. 사용자 찾기
        user_query = select(User).where(User.device_id == request.device_id)
        user_result = await db.execute(user_query)
        user = user_result.scalar_one_or_none()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="사용자를 찾을 수 없습니다"
            )
        
        # 2. 보상 정보 찾기 (하드코딩 데이터에서)
        reward = next((r for r in REWARDS if r['id'] == request.reward_id), None)
        
        if not reward:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="보상을 찾을 수 없습니다"
            )
        
        # 3. 포인트 확인
        points_query = select(UserPoints).where(UserPoints.user_id == user.id)
        points_result = await db.execute(points_query)
        user_points = points_result.scalar_one_or_none()
        
        if not user_points or user_points.total_points < reward['points']:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"포인트가 부족합니다 (필요: {reward['points']}, 보유: {user_points.total_points if user_points else 0})"
            )
        
        # 4. 포인트 차감
        user_points.total_points -= reward['points']
        user_points.updated_at = datetime.utcnow()
        
        # 5. 교환 코드 생성
        redemption_code = generate_redemption_code()
        
        # 6. 교환 내역 저장
        redemption = RewardRedemption(
            user_id=user.id,
            reward_name=reward['name'],
            points_spent=reward['points'],
            redemption_code=redemption_code,
            redeemed_at=datetime.utcnow()
        )
        db.add(redemption)
        
        await db.commit()
        
        logger.info(f"Reward redeemed: user={user.device_id}, reward={reward['name']}, code={redemption_code}")
        
        return RedeemRewardResponse(
            success=True,
            redemption_code=redemption_code,
            reward_name=reward['name'],
            points_spent=reward['points'],
            remaining_points=user_points.total_points
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error redeeming reward: {str(e)}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"보상 교환 실패: {str(e)}"
        )


@router.get("/my-codes/{device_id}", response_model=MyCodesResponse)
async def get_my_codes(
    device_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    내가 교환한 코드 목록 조회
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
        
        # 교환 내역 조회
        codes_query = select(RewardRedemption).where(
            RewardRedemption.user_id == user.id
        ).order_by(RewardRedemption.redeemed_at.desc())
        
        codes_result = await db.execute(codes_query)
        redemptions = codes_result.scalars().all()
        
        codes = []
        for redemption in redemptions:
            codes.append(RedemptionCode(
                id=redemption.id,
                reward_name=redemption.reward_name,
                redemption_code=redemption.redemption_code,
                points_spent=redemption.points_spent,
                redeemed_at=redemption.redeemed_at
            ))
        
        return MyCodesResponse(codes=codes)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting my codes: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="교환 내역 조회 실패"
        )

