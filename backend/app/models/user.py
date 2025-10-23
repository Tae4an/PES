"""
사용자 모델
"""
from sqlalchemy import Column, String, DateTime, Integer, Boolean
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid
from geoalchemy2 import Geography
from ..db.session import Base


class User(Base):
    """사용자 모델 (세션 단위)"""
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_id = Column(String(255), unique=True, nullable=False, index=True)
    fcm_token = Column(String(512), nullable=True)
    
    # 사용자 프로필 (비식별)
    age_group = Column(String(50), nullable=True)  # '청소년', '성인', '노인'
    mobility = Column(String(50), default='정상')  # '정상', '휠체어', '유아동반'
    
    # 세션 정보
    is_active = Column(Boolean, default=True)
    last_location_update = Column(DateTime, nullable=True)
    
    # 위치 (세션 단위만 보관, 1시간 TTL)
    location = Column(Geography(geometry_type='POINT', srid=4326), nullable=True)
    admin_region = Column(String(255), nullable=True)  # '서울시 영등포구' 등
    
    # 타임스탬프
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f"<User {self.device_id}>"

