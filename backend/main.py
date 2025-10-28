"""
PES(Personal Emergency Siren) 백엔드 메인 애플리케이션
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from app.core.config import settings
from app.core.logging import setup_logging
from app.api.v1.endpoints import disasters, health, admin, action_cards, fcm
from app.db.session import log_shelter_db_info
# Phase 2: DB 연동 시 활성화 예정
# from app.api.v1.endpoints import user, shelters
# from app.background.tasks import disaster_polling_task

# 로깅 설정
logger = setup_logging()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """앱 생명주기 관리"""
    # 시작 시
    logger.info("Starting PES Backend...")
    
    # 대피소 DB 연결 정보 로깅 (추가)
    log_shelter_db_info()
    
    # Phase 2: 백그라운드 재난 폴링 (DB 연동 시 활성화)
    # await disaster_polling_task.start()
    # logger.info("Disaster polling task started")
    
    yield
    
    # 종료 시
    logger.info("Shutting down PES Backend...")
    # Phase 2: 백그라운드 태스크 종료
    # await disaster_polling_task.stop()
    # logger.info("Disaster polling task stopped")


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

# Phase 2: 사용자 프로필 및 대피소 API (DB 연동 시 활성화)
# app.include_router(
#     user.router,
#     prefix="/api/v1/user",
#     tags=["User"]
# )
# app.include_router(
#     shelters.router,
#     prefix="/api/v1/shelters",
#     tags=["Shelters"]
# )

app.include_router(
    disasters.router,
    prefix="/api/v1/disasters",
    tags=["Disasters"]
)

app.include_router(
    action_cards.router,
    prefix="/api/v1/action-cards",
    tags=["Action Cards"]
)

app.include_router(
    admin.router,
    prefix="/api/v1/admin",
    tags=["Admin"]
)

app.include_router(
    fcm.router,
    prefix="/api/v1/fcm",
    tags=["FCM"]
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

