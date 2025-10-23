"""
재난 모델
"""
from sqlalchemy import Column, String, DateTime, Text, Integer
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid
from geoalchemy2 import Geography
from ..db.session import Base


class Disaster(Base):
    """재난 정보 모델"""
    __tablename__ = "disasters"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # 행정안전부 API 데이터
    msg_id = Column(String(255), unique=True, nullable=False, index=True)  # 재난문자 고유 ID
    disaster_type = Column(String(100), nullable=False, index=True)  # '호우', '지진', '태풍' 등
    location = Column(String(255), nullable=False)  # 발생 지역
    message = Column(Text, nullable=False)  # 원본 재난문자
    
    # 공간 정보 (PostGIS)
    # 재난 발생 지역의 폴리곤 또는 포인트
    disaster_area = Column(Geography(geometry_type='POLYGON', srid=4326), nullable=True)
    
    # 메타데이터
    severity = Column(String(50), nullable=True)  # '경보', '주의보', '특보'
    issued_at = Column(DateTime, nullable=False)  # 발령 시각
    
    # 타임스탬프
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f"<Disaster {self.disaster_type} at {self.location}>"

