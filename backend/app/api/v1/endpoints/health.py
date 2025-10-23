"""
헬스체크 API 엔드포인트
"""
from fastapi import APIRouter, status
from datetime import datetime
from pydantic import BaseModel

router = APIRouter()


class HealthResponse(BaseModel):
    """헬스체크 응답"""
    status: str
    timestamp: datetime
    version: str


@router.get("/", response_model=HealthResponse)
async def health_check():
    """
    서버 상태 확인
    """
    return HealthResponse(
        status="ok",
        timestamp=datetime.utcnow(),
        version="1.0.0"
    )

