"""
PES 백엔드 설정 파일
"""
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
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379"
    REDIS_CACHE_TTL: int = 1800  # 30분
    
    # Ollama
    OLLAMA_ENDPOINT: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "qwen3:8b-instruct"
    OLLAMA_TIMEOUT: int = 15
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
    
    # Polling Configuration
    DISASTER_POLL_INTERVAL_SECONDS: int = 10
    
    # Location Settings
    DEFAULT_SHELTER_SEARCH_RADIUS_KM: float = 2.0
    MAX_SHELTERS_RETURN: int = 3
    WALKING_SPEED_KM_PER_HOUR: float = 4.8
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# 싱글톤 인스턴스
settings = Settings()

