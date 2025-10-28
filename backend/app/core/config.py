"""
PES 백엔드 설정 파일
"""
import os
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """애플리케이션 설정"""
    
    # Application
    APP_NAME: str = "PES"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    
    # Database
    DATABASE_URL: str = "postgresql+asyncpg://pes_user:pes_password@localhost:5432/pes"
    
    # 로컬 대피소 DB 설정 (선택적)
    LOCAL_SHELTER_DB_HOST: Optional[str] = None
    LOCAL_SHELTER_DB_PORT: Optional[str] = None
    LOCAL_SHELTER_DB_NAME: Optional[str] = None
    LOCAL_SHELTER_DB_USER: Optional[str] = None
    LOCAL_SHELTER_DB_PASSWORD: Optional[str] = None
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379"
    REDIS_CACHE_TTL: int = 1800  # 30분
    
    # Ollama (별도 AI 서버에서 실행)
    OLLAMA_ENDPOINT: str = "http://localhost:11434"  # 로컬 AI 서버
    OLLAMA_MODEL: str = "qwen3:8b" 
    OLLAMA_TIMEOUT: int = 30  # AI 응답 대기 시간 (초)
    OLLAMA_TEMPERATURE: float = 0.3
    
    # 행정안전부 재난문자 API
    DISASTER_API_URL: str = "https://www.safetydata.go.kr/api/disasterMsg"
    DISASTER_API_KEY: str = ""
    DISASTER_API_TIMEOUT: int = 5
    
    # Firebase
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None
    
    # Security
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Logging
    LOG_LEVEL: str = "INFO"
    SENTRY_DSN: Optional[str] = None
    
    # Mock Data Configuration
    USE_MOCK_DATA: bool = True  # True: CSV Mock 사용, False: 실제 API 사용
    MOCK_DATA_PATH: str = "app/data/sample_disasters.csv"
    
    # Polling Configuration
    DISASTER_POLL_INTERVAL_SECONDS: int = 10
    
    # Location Settings
    DEFAULT_SHELTER_SEARCH_RADIUS_KM: float = 2.0
    MAX_SHELTERS_RETURN: int = 3
    WALKING_SPEED_KM_PER_HOUR: float = 4.8
    
    # Google Maps (향후 사용)
    GOOGLE_MAPS_API_KEY: Optional[str] = None
    GOOGLE_GEOCODING_API_URL: str = "https://maps.googleapis.com/maps/api/geocode/json"
    
    # Firebase Configuration
    FIREBASE_CREDENTIALS_PATH: str = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
        "credentials",
        "firebase-service-account.json"
    )
    
    @property
    def use_local_shelter_db(self) -> bool:
        """
        로컬 대피소 DB 사용 여부 확인
        5개 환경변수가 모두 설정되어 있으면 True
        """
        return all([
            self.LOCAL_SHELTER_DB_HOST,
            self.LOCAL_SHELTER_DB_PORT,
            self.LOCAL_SHELTER_DB_NAME,
            self.LOCAL_SHELTER_DB_USER,
            self.LOCAL_SHELTER_DB_PASSWORD
        ])
    
    @property
    def local_shelter_db_url(self) -> str:
        """
        로컬 대피소 DB 연결 URL 생성
        설정이 없으면 기본 DATABASE_URL 반환
        """
        if not self.use_local_shelter_db:
            return self.DATABASE_URL
        
        return (
            f"postgresql+asyncpg://"
            f"{self.LOCAL_SHELTER_DB_USER}:{self.LOCAL_SHELTER_DB_PASSWORD}@"
            f"{self.LOCAL_SHELTER_DB_HOST}:{self.LOCAL_SHELTER_DB_PORT}/"
            f"{self.LOCAL_SHELTER_DB_NAME}"
        )
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# 싱글톤 인스턴스
settings = Settings()

