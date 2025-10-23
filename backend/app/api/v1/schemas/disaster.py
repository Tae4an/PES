"""
재난 관련 Pydantic 스키마
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from uuid import UUID


class DisasterInfo(BaseModel):
    """재난 정보"""
    id: UUID
    msg_id: str
    disaster_type: str
    location: str
    message: str
    severity: Optional[str]
    issued_at: datetime
    
    class Config:
        from_attributes = True


class ActionCardGenerateRequest(BaseModel):
    """행동카드 생성 요청 (테스트용)"""
    disaster_type: str = Field(..., description="재난 유형: 호우, 지진, 태풍 등")
    location: str = Field(..., description="재난 발생 지역")
    user_latitude: float = Field(..., ge=-90, le=90)
    user_longitude: float = Field(..., ge=-180, le=180)
    age_group: Optional[str] = Field("성인", description="연령대")
    mobility: Optional[str] = Field("정상", description="이동성")


class ActionCardResponse(BaseModel):
    """행동카드 응답"""
    action_card: str = Field(..., description="생성된 행동카드 텍스트")
    shelters: list = Field(default_factory=list, description="추천 대피소 목록")
    generated_at: datetime = Field(default_factory=datetime.utcnow)
    generation_method: str = Field(..., description="생성 방법: llm 또는 fallback")

