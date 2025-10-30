"""
대피소 모델
"""
from sqlalchemy import Column, String, Integer, Float, DateTime, Text
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid

from ..db.session import Base


class Shelter(Base):
    """대피소 정보 모델"""
    __tablename__ = "shelters"
    
    # 기본 정보
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False, index=True, comment="대피소 이름")
    address = Column(String(512), nullable=False, comment="주소")
    shelter_type = Column(String(100), nullable=False, index=True, comment="대피소 유형")
    
    # 좌표 정보 (PostGIS 제거, 일반 Float 사용)
    latitude = Column(Float, nullable=True, index=True, comment="위도")
    longitude = Column(Float, nullable=True, index=True, comment="경도")
    
    # 수용 정보
    capacity = Column(Integer, nullable=True, comment="수용 인원")
    area_m2 = Column(Float, nullable=True, comment="면적 (㎡)")
    
    # 연락처 및 운영 정보
    phone = Column(String(50), nullable=True, comment="전화번호")
    operator = Column(String(255), nullable=True, comment="운영기관")
    
    # 부가 정보
    description = Column(Text, nullable=True, comment="설명")
    has_parking = Column(String(10), nullable=True, comment="주차 가능 여부")
    has_generator = Column(String(10), nullable=True, comment="발전기 보유 여부")
    
    # 메타데이터
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    def __repr__(self):
        return f"<Shelter(id={self.id}, name={self.name}, type={self.shelter_type})>"
    
    def to_dict(self):
        """딕셔너리 변환"""
        return {
            "id": str(self.id),
            "name": self.name,
            "address": self.address,
            "shelter_type": self.shelter_type,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "capacity": self.capacity,
            "area_m2": self.area_m2,
            "phone": self.phone,
            "operator": self.operator,
            "description": self.description,
            "has_parking": self.has_parking,
            "has_generator": self.has_generator,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }