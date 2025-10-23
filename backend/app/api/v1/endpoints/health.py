"""
헬스체크 API 엔드포인트
"""
from fastapi import APIRouter, status
from datetime import datetime
from pydantic import BaseModel
from typing import Optional

from ....services.disaster_service import disaster_service

router = APIRouter()


class HealthResponse(BaseModel):
    """헬스체크 응답"""
    status: str
    timestamp: datetime
    version: str
    mock_mode: bool
    data_source: str
    mock_data_count: Optional[int] = None


@router.get("/", response_model=HealthResponse)
async def health_check():
    """
    서버 상태 확인
    
    **시스템 상태 및 Mock 모드 정보를 포함**
    
    - 서버 정상 동작 여부
    - 현재 데이터 소스 (Mock CSV / Real API)
    - Mock 데이터 개수
    """
    return HealthResponse(
        status="ok",
        timestamp=datetime.utcnow(),
        version="1.0.0",
        mock_mode=disaster_service.is_mock_mode,
        data_source=disaster_service.data_source,
        mock_data_count=disaster_service.mock_data_count if disaster_service.is_mock_mode else None
    )

