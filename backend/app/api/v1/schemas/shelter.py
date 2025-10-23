"""
대피소 관련 Pydantic 스키마
"""
from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID


class ShelterInfo(BaseModel):
    """대피소 정보"""
    id: UUID
    name: str
    address: str
    shelter_type: str
    capacity: Optional[int]
    distance_km: Optional[float] = Field(None, description="사용자로부터의 거리 (km)")
    walking_minutes: Optional[int] = Field(None, description="도보 소요 시간 (분)")
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    
    class Config:
        from_attributes = True


class ShelterSearchRequest(BaseModel):
    """대피소 검색 요청"""
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    radius_km: Optional[float] = Field(2.0, ge=0.1, le=10.0, description="검색 반경 (km)")
    limit: Optional[int] = Field(3, ge=1, le=10, description="최대 결과 수")


class ShelterSearchResponse(BaseModel):
    """대피소 검색 응답"""
    shelters: list[ShelterInfo]
    total_count: int
    search_radius_km: float

