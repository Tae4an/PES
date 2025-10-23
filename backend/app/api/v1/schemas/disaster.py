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


class MockDisasterMessage(BaseModel):
    """Mock 재난문자 메시지 (CSV 기반)"""
    serial_number: int = Field(..., description="연번")
    date: str = Field(..., description="발생 날짜 (YYYY-MM-DD)")
    time: str = Field(..., description="발생 시간 (HH:MM)")
    category: str = Field(..., description="구분 (기상특보, 지진, 교통 등)")
    message: str = Field(..., description="문자전송내용")
    issued_at: datetime = Field(..., description="발령 시각 (날짜+시간 조합)")
    
    class Config:
        from_attributes = True


class MockModeStatus(BaseModel):
    """Mock 모드 상태"""
    mock_mode_enabled: bool = Field(..., description="Mock 모드 활성화 여부")
    data_source: str = Field(..., description="데이터 소스: 'mock_csv' 또는 'real_api'")
    total_mock_messages: int = Field(..., description="Mock 데이터 총 개수")
    message: str = Field(..., description="상태 메시지")

