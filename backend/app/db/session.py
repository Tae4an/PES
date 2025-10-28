"""
데이터베이스 세션 관리
"""
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
import logging
from ..core.config import settings

logger = logging.getLogger(__name__)

# Base 클래스
Base = declarative_base()

# 기본 DB 엔진 (일반 데이터용)
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    future=True,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20
)

# 기본 세션 팩토리
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False
)

# 대피소 전용 DB 엔진 (로컬 설정이 있으면 별도 엔진 사용)
if settings.use_local_shelter_db:
    shelter_engine = create_async_engine(
        settings.local_shelter_db_url,
        echo=settings.DEBUG,
        future=True,
        pool_pre_ping=True,
        pool_size=5,
        max_overflow=10
    )
    _using_local_shelter_db = True
else:
    shelter_engine = engine
    _using_local_shelter_db = False

# 대피소 전용 세션 팩토리
ShelterAsyncSessionLocal = async_sessionmaker(
    shelter_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False
)

def log_shelter_db_info():
    """대피소 DB 연결 정보 로깅 (startup 시 호출)"""
    if _using_local_shelter_db:
        logger.info(
            f"🏢 로컬 대피소 DB 사용: "
            f"{settings.LOCAL_SHELTER_DB_HOST}:{settings.LOCAL_SHELTER_DB_PORT}/"
            f"{settings.LOCAL_SHELTER_DB_NAME}"
        )
    else:
        logger.info("🏢 기본 DB를 대피소 DB로 사용")
        

async def get_db() -> AsyncSession:
    """
    일반 데이터베이스 세션 의존성
    
    Yields:
        AsyncSession: 비동기 DB 세션
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def get_shelter_db() -> AsyncSession:
    """
    대피소 전용 데이터베이스 세션 의존성
    로컬 설정이 있으면 별도 DB 사용, 없으면 기본 DB 사용
    
    Yields:
        AsyncSession: 비동기 DB 세션
    """
    async with ShelterAsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()