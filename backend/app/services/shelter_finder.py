"""
대피소 검색 서비스 (latitude/longitude 기반)
"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import logging

from ..api.v1.schemas.shelter import ShelterInfo
from ..core.config import settings

logger = logging.getLogger(__name__)


class ShelterFinder:
    """대피소 검색 서비스"""
    
    # 재난 유형과 대피소 유형 매핑
    DISASTER_TO_SHELTER_TYPE = {
        "민방위": "민방위대피소",
        "지진": "지진대피소",
        "해일": "해일대피소",
        "기타": "기타대피소"
    }
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.walking_speed_km_per_hour = settings.WALKING_SPEED_KM_PER_HOUR if hasattr(settings, 'WALKING_SPEED_KM_PER_HOUR') else 4.0
    
    async def get_shelters_within_radius(
        self,
        latitude: float,
        longitude: float,
        radius_km: float = 2.0,
        limit: int = 3
    ) -> List[ShelterInfo]:
        """
        사용자 위치 반경 내 대피소 검색 (Haversine 공식 사용)
        
        Args:
            latitude: 사용자 위도
            longitude: 사용자 경도
            radius_km: 검색 반경 (km)
            limit: 최대 결과 수
        
        Returns:
            대피소 정보 리스트 (거리 순 정렬)
        """
        try:
            logger.info(f"Searching shelters: lat={latitude}, lng={longitude}, radius={radius_km}km, limit={limit}")
            
            # 서브쿼리를 사용하여 거리 계산 후 필터링
            query = text("""
                SELECT 
                    name,
                    address,
                    shelter_type,
                    latitude,
                    longitude,
                    distance_km
                FROM (
                    SELECT 
                        name,
                        address,
                        shelter_type,
                        latitude,
                        longitude,
                        (
                            6371 * acos(
                                LEAST(1.0, 
                                    cos(radians(:user_lat)) * cos(radians(latitude)) *
                                    cos(radians(longitude) - radians(:user_lng)) +
                                    sin(radians(:user_lat)) * sin(radians(latitude))
                                )
                            )
                        ) AS distance_km
                    FROM shelters
                    WHERE latitude IS NOT NULL
                      AND longitude IS NOT NULL
                ) AS shelter_distances
                WHERE distance_km <= :radius_km
                ORDER BY distance_km ASC
                LIMIT :limit
            """)
            
            result = await self.db.execute(
                query,
                {
                    "user_lat": latitude,
                    "user_lng": longitude,
                    "radius_km": radius_km,
                    "limit": limit
                }
            )
            
            rows = result.fetchall()
            logger.info(f"Query returned {len(rows)} rows")
            
            shelters = []
            for row in rows:
                distance_km = float(row.distance_km)
                walking_minutes = self._calculate_walking_time(distance_km)
                
                shelter = ShelterInfo(
                    name=row.name,
                    address=row.address,
                    shelter_type=row.shelter_type,
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
            import traceback
            traceback.print_exc()
            return []
    
    async def get_shelters_by_disaster_type(
        self,
        disaster_type: str,
        latitude: float,
        longitude: float,
        radius_km: float = 10.0,
        limit: int = 5
    ) -> List[ShelterInfo]:
        """
        재난 유형별 대피소 검색
        
        Args:
            disaster_type: 재난 유형 (민방위, 지진, 해일, 기타)
            latitude: 사용자 위도
            longitude: 사용자 경도
            radius_km: 검색 반경 (km)
            limit: 최대 결과 수
        
        Returns:
            해당 재난 유형의 대피소 리스트 (거리 순 정렬)
        """
        try:
            # 재난 유형을 대피소 유형으로 변환
            shelter_type = self.DISASTER_TO_SHELTER_TYPE.get(disaster_type)
            
            if not shelter_type:
                logger.warning(f"Unknown disaster type: {disaster_type}")
                return []
            
            logger.info(f"Searching {disaster_type} shelters: lat={latitude}, lng={longitude}, radius={radius_km}km, limit={limit}")
            
            # shelter_type에 공백이 포함될 수 있으므로 TRIM 및 LIKE 사용
            query = text("""
                SELECT 
                    name,
                    address,
                    shelter_type,
                    latitude,
                    longitude,
                    distance_km
                FROM (
                    SELECT 
                        name,
                        address,
                        shelter_type,
                        latitude,
                        longitude,
                        (
                            6371 * acos(
                                LEAST(1.0, 
                                    cos(radians(:user_lat)) * cos(radians(latitude)) *
                                    cos(radians(longitude) - radians(:user_lng)) +
                                    sin(radians(:user_lat)) * sin(radians(latitude))
                                )
                            )
                        ) AS distance_km
                    FROM shelters
                    WHERE latitude IS NOT NULL
                      AND longitude IS NOT NULL
                      AND TRIM(shelter_type) LIKE :shelter_type_pattern
                ) AS shelter_distances
                WHERE distance_km <= :radius_km
                ORDER BY distance_km ASC
                LIMIT :limit
            """)
            
            result = await self.db.execute(
                query,
                {
                    "user_lat": latitude,
                    "user_lng": longitude,
                    "shelter_type_pattern": f"%{shelter_type}%",
                    "radius_km": radius_km,
                    "limit": limit
                }
            )
            
            rows = result.fetchall()
            logger.info(f"Query returned {len(rows)} rows for disaster type '{disaster_type}'")
            
            shelters = []
            for row in rows:
                distance_km = float(row.distance_km)
                walking_minutes = self._calculate_walking_time(distance_km)
                
                shelter = ShelterInfo(
                    name=row.name,
                    address=row.address,
                    shelter_type=row.shelter_type.strip(),
                    latitude=float(row.latitude),
                    longitude=float(row.longitude),
                    distance_km=round(distance_km, 2),
                    walking_minutes=walking_minutes
                )
                shelters.append(shelter)
            
            logger.info(f"Found {len(shelters)} {disaster_type} shelters within {radius_km}km")
            return shelters
            
        except Exception as e:
            logger.error(f"Error searching shelters by disaster type: {str(e)}")
            import traceback
            traceback.print_exc()
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
    
    async def get_shelters_by_type_and_location(
        self,
        shelter_type: str,
        latitude: float,
        longitude: float,
        offset: int = 0,
        limit: int = 20
    ) -> List[ShelterInfo]:
        """
        대피소 유형 + 거리순 검색
        
        Args:
            shelter_type: 대피소 유형
            latitude: 위도
            longitude: 경도
            offset: 오프셋
            limit: 최대 결과 수
        
        Returns:
            거리순으로 정렬된 대피소 목록
        """
        try:
            query = text("""
                SELECT 
                    name,
                    address,
                    shelter_type,
                    latitude,
                    longitude,
                    (
                        6371 * acos(
                            LEAST(1.0,
                                cos(radians(:lat)) * cos(radians(latitude)) *
                                cos(radians(longitude) - radians(:lng)) +
                                sin(radians(:lat)) * sin(radians(latitude))
                            )
                        )
                    ) AS distance_km
                FROM shelters
                WHERE TRIM(shelter_type) = :shelter_type
                  AND latitude IS NOT NULL
                  AND longitude IS NOT NULL
                ORDER BY distance_km
                OFFSET :offset
                LIMIT :limit
            """)
            
            result = await self.db.execute(
                query,
                {
                    "lat": latitude,
                    "lng": longitude,
                    "shelter_type": shelter_type,
                    "offset": offset,
                    "limit": limit
                }
            )
            
            shelters = []
            for row in result.fetchall():
                distance_km = float(row.distance_km)
                walking_minutes = self._calculate_walking_time(distance_km)
                
                shelter = ShelterInfo(
                    name=row.name,
                    address=row.address,
                    shelter_type=row.shelter_type.strip(),
                    latitude=float(row.latitude),
                    longitude=float(row.longitude),
                    distance_km=round(distance_km, 2),
                    walking_minutes=walking_minutes
                )
                shelters.append(shelter)
            
            return shelters
            
        except Exception as e:
            logger.error(f"Error finding shelters by type and location: {e}")
            return []