"""
훈련 시스템 모델
"""
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
from ..db.session import Base


class TrainingSession(Base):
    """훈련 세션 모델"""
    __tablename__ = "training_sessions"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)
    shelter_id = Column(UUID(as_uuid=True), ForeignKey('shelters.id'), nullable=False)
    shelter_name = Column(String(200), nullable=True)
    status = Column(String(20), default='ongoing', index=True)  # 'ongoing', 'completed', 'abandoned'
    started_at = Column(DateTime, default=datetime.utcnow)
    completed_at = Column(DateTime, nullable=True)
    points_earned = Column(Integer, default=0)
    initial_distance = Column(Integer, nullable=True)  # 훈련 시작 시 대피소까지의 거리 (미터)
    
    def __repr__(self):
        return f"<TrainingSession {self.id} - User {self.user_id}>"


class UserPoints(Base):
    """사용자 포인트 모델"""
    __tablename__ = "user_points"
    
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    total_points = Column(Integer, default=0)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f"<UserPoints {self.user_id}: {self.total_points}P>"


class RewardRedemption(Base):
    """보상 교환 내역 모델"""
    __tablename__ = "reward_redemptions"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)
    reward_name = Column(String(100), nullable=False)
    points_spent = Column(Integer, nullable=False)
    redemption_code = Column(String(20), nullable=False, unique=True)
    redeemed_at = Column(DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f"<RewardRedemption {self.id} - {self.reward_name}>"

