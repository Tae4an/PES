"""
PostGIS 기반 대피소 검색 서비스
"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text
from geoalchemy2.functions import ST_DWithin, ST_Distance, ST_MakePoint
from geoalchemy2.elements import WKTElement
import logging

from ..models.shelter import Shelter
from ..api.v1.schemas.shelter import ShelterInfo
from ..core.config import settings

logger = logging.getLogger(__name__)


class ShelterFinder:
    """대피소 검색 서비스"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.walking_speed_km_per_hour = settings.WALKING_SPEED_KM_PER_HOUR
    
    async def get_shelters_within_radius(
        self,
        latitude: float,
        longitude: float,
        radius_km: float = 2.0,
        limit: int = 3
    ) -> List[ShelterInfo]:
        """
        사용자 위치 반경 내 대피소 검색
        
        Args:
            latitude: 사용자 위도
            longitude: 사용자 경도
            radius_km: 검색 반경 (km)
            limit: 최대 결과 수
        
        Returns:
            대피소 정보 리스트 (거리 순 정렬)
        """
        try:
            # 사용자 위치 포인트 생성 (SRID 4326)
            user_point = f'SRID=4326;POINT({longitude} {latitude})'
            
            # PostGIS 쿼리
            query = text("""
                SELECT 
                    id,
                    name,
                    address,
                    shelter_type,
                    capacity,
                    ST_Y(location::geometry) as latitude,
                    ST_X(location::geometry) as longitude,
                    ST_Distance(
                        location::geography,
                        ST_GeogFromText(:user_point)
                    ) / 1000.0 as distance_km
                FROM shelters
                WHERE ST_DWithin(
                    location::geography,
                    ST_GeogFromText(:user_point),
                    :radius_meters
                )
                ORDER BY distance_km ASC
                LIMIT :limit
            """)
            
            result = await self.db.execute(
                query,
                {
                    "user_point": user_point,
                    "radius_meters": radius_km * 1000,
                    "limit": limit
                }
            )
            
            rows = result.fetchall()
            
            shelters = []
            for row in rows:
                distance_km = float(row.distance_km)
                walking_minutes = self._calculate_walking_time(distance_km)
                
                shelter = ShelterInfo(
                    id=row.id,
                    name=row.name,
                    address=row.address,
                    shelter_type=row.shelter_type,
                    capacity=row.capacity,
                    latitude=float(row.latitude),
                    longitude=float(row.longitude),
                    distance_km=round(distance_km, 2),
                    walking_minutes=walking_minutes
                )
                shelters.append(shelter)
            
            logger.info(f"Found {len(shelters)} shelters within {radius_km}km")
            return shelters
            
        except Exception as e:
            logger.error(f"Error searching shelters: {str(e)}")
            return []
    
    def _calculate_walking_time(self, distance_km: float) -> int:
        """
        도보 소요 시간 계산
        
        Args:
            distance_km: 거리 (km)
        
        Returns:
            도보 소요 시간 (분)
        """
        hours = distance_km / self.walking_speed_km_per_hour
        minutes = int(hours * 60)
        return max(1, minutes)  # 최소 1분
    
    async def check_user_in_disaster_zone(
        self,
        user_lat: float,
        user_lng: float,
        disaster_polygon_wkt: str
    ) -> bool:
        """
        사용자가 재난 지역 내에 있는지 판정
        
        Args:
            user_lat: 사용자 위도
            user_lng: 사용자 경도
            disaster_polygon_wkt: 재난 지역 폴리곤 (WKT 형식)
        
        Returns:
            교차 여부
        """
        try:
            user_point = f'SRID=4326;POINT({user_lng} {user_lat})'
            
            query = text("""
                SELECT ST_Intersects(
                    ST_GeogFromText(:user_point),
                    ST_GeogFromText(:disaster_polygon)
                ) as intersects
            """)
            
            result = await self.db.execute(
                query,
                {
                    "user_point": user_point,
                    "disaster_polygon": disaster_polygon_wkt
                }
            )
            
            row = result.fetchone()
            return bool(row.intersects) if row else False
            
        except Exception as e:
            logger.error(f"Error checking disaster zone intersection: {str(e)}")
            return False

