"""
대피소 모델
"""
from sqlalchemy import Column, String, Integer, Float
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid
from geoalchemy2 import Geography
from ..db.session import Base


class Shelter(Base):
    """대피소 모델"""
    __tablename__ = "shelters"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # 기본 정보
    name = Column(String(255), nullable=False)  # '○○초등학교'
    address = Column(String(512), nullable=False)
    shelter_type = Column(String(100), nullable=False, index=True)  # '초등학교', '체육관', '임시대피소'
    
    # 수용 정보
    capacity = Column(Integer, nullable=True)  # 수용 인원
    area_m2 = Column(Float, nullable=True)  # 면적 (제곱미터)
    
    # 위치 (PostGIS)
    location = Column(Geography(geometry_type='POINT', srid=4326), nullable=False, index=True)
    
    # 메타데이터
    phone = Column(String(50), nullable=True)
    operator = Column(String(255), nullable=True)  # 운영 주체
    
    # 시설 정보
    has_parking = Column(String(10), nullable=True)  # '가능', '불가능'
    has_generator = Column(String(10), nullable=True)  # 비상발전기
    
    def __repr__(self):
        return f"<Shelter {self.name}>"

