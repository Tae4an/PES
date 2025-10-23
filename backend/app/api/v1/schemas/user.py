"""
사용자 관련 Pydantic 스키마
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from uuid import UUID


class UserRegisterRequest(BaseModel):
    """사용자 등록 요청"""
    device_id: str = Field(..., description="기기 고유 식별자")
    fcm_token: str = Field(..., description="Firebase Cloud Messaging 토큰")
    age_group: Optional[str] = Field(None, description="연령대: 청소년, 성인, 노인")
    mobility: Optional[str] = Field("정상", description="이동성: 정상, 휠체어, 유아동반")


class UserRegisterResponse(BaseModel):
    """사용자 등록 응답"""
    user_id: UUID
    session_token: str
    message: str = "사용자 등록 완료"


class LocationUpdateRequest(BaseModel):
    """위치 업데이트 요청"""
    latitude: float = Field(..., ge=-90, le=90, description="위도")
    longitude: float = Field(..., ge=-180, le=180, description="경도")


class LocationUpdateResponse(BaseModel):
    """위치 업데이트 응답"""
    status: str = "success"
    message: str = "위치 업데이트 완료"
    updated_at: datetime


class UserProfile(BaseModel):
    """사용자 프로필"""
    user_id: UUID
    device_id: str
    age_group: Optional[str]
    mobility: str
    is_active: bool
    last_location_update: Optional[datetime]
    
    class Config:
        from_attributes = True

