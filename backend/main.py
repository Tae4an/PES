"""
PES(Personal Emergency Siren) 백엔드 메인 애플리케이션
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from app.core.config import settings
from app.core.logging import setup_logging
from app.api.v1.endpoints import user, shelters, disasters, health, admin
from app.background.tasks import disaster_polling_task

# 로깅 설정
logger = setup_logging()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """앱 생명주기 관리"""
    # 시작 시
    logger.info("Starting PES Backend...")
    
    # 백그라운드 폴링 시작
    await disaster_polling_task.start()
    logger.info("Disaster polling task started")
    
    yield
    
    # 종료 시
    logger.info("Shutting down PES Backend...")
    await disaster_polling_task.stop()
    logger.info("Disaster polling task stopped")


# FastAPI 앱 생성
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="재난 안전 모바일 앱 백엔드 API",
    lifespan=lifespan
)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 프로덕션에서는 특정 도메인만 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API 라우터 등록
app.include_router(
    health.router,
    prefix="/api/v1/health",
    tags=["Health"]
)

app.include_router(
    user.router,
    prefix="/api/v1/user",
    tags=["User"]
)

app.include_router(
    shelters.router,
    prefix="/api/v1/shelters",
    tags=["Shelters"]
)

app.include_router(
    disasters.router,
    prefix="/api/v1/disasters",
    tags=["Disasters"]
)

app.include_router(
    admin.router,
    prefix="/api/v1/admin",
    tags=["Admin"]
)


@app.get("/")
async def root():
    """루트 엔드포인트"""
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "running",
        "docs": "/docs"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG
    )

