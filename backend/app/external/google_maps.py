"""
Google Maps API 서비스 (향후 사용)
"""
import httpx
import logging
from typing import Optional, Dict, Tuple
from ..core.config import settings

logger = logging.getLogger(__name__)


class GoogleMapsService:
    """Google Maps API 서비스"""
    
    def __init__(self):
        self.api_key = settings.GOOGLE_MAPS_API_KEY
        self.geocoding_url = settings.GOOGLE_GEOCODING_API_URL
        self.timeout = 10
    
    async def geocode_address(self, address: str) -> Optional[Tuple[float, float]]:
        """
        주소를 좌표로 변환 (Geocoding)
        
        Args:
            address: 주소 문자열
        
        Returns:
            (위도, 경도) 또는 None
        """
        if not self.api_key:
            logger.warning("Google Maps API key not configured")
            return None
        
        try:
            params = {
                "address": address,
                "key": self.api_key
            }
            
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(self.geocoding_url, params=params)
            
            if response.status_code == 200:
                data = response.json()
                
                if data.get("status") == "OK" and data.get("results"):
                    location = data["results"][0]["geometry"]["location"]
                    lat = location["lat"]
                    lng = location["lng"]
                    
                    logger.info(f"Geocoded '{address}' to ({lat}, {lng})")
                    return (lat, lng)
                else:
                    logger.warning(f"Geocoding failed for '{address}': {data.get('status')}")
                    return None
            else:
                logger.error(f"Geocoding API error: {response.status_code}")
                return None
        
        except Exception as e:
            logger.error(f"Geocoding error: {str(e)}")
            return None
    
    async def reverse_geocode(self, lat: float, lng: float) -> Optional[str]:
        """
        좌표를 주소로 변환 (Reverse Geocoding)
        
        Args:
            lat: 위도
            lng: 경도
        
        Returns:
            주소 문자열 또는 None
        """
        if not self.api_key:
            logger.warning("Google Maps API key not configured")
            return None
        
        try:
            params = {
                "latlng": f"{lat},{lng}",
                "key": self.api_key
            }
            
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(self.geocoding_url, params=params)
            
            if response.status_code == 200:
                data = response.json()
                
                if data.get("status") == "OK" and data.get("results"):
                    address = data["results"][0]["formatted_address"]
                    
                    logger.info(f"Reverse geocoded ({lat}, {lng}) to '{address}'")
                    return address
                else:
                    logger.warning(f"Reverse geocoding failed for ({lat}, {lng}): {data.get('status')}")
                    return None
            else:
                logger.error(f"Reverse geocoding API error: {response.status_code}")
                return None
        
        except Exception as e:
            logger.error(f"Reverse geocoding error: {str(e)}")
            return None
    
    async def get_place_details(self, place_id: str) -> Optional[Dict]:
        """
        장소 상세 정보 조회
        
        Args:
            place_id: Google Places ID
        
        Returns:
            장소 정보 딕셔너리 또는 None
        """
        if not self.api_key:
            logger.warning("Google Maps API key not configured")
            return None
        
        # Place Details API 엔드포인트
        url = "https://maps.googleapis.com/maps/api/place/details/json"
        
        try:
            params = {
                "place_id": place_id,
                "key": self.api_key,
                "fields": "name,formatted_address,geometry,phone_number,website"
            }
            
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(url, params=params)
            
            if response.status_code == 200:
                data = response.json()
                
                if data.get("status") == "OK":
                    return data.get("result")
                else:
                    logger.warning(f"Place details failed for {place_id}: {data.get('status')}")
                    return None
            else:
                logger.error(f"Place details API error: {response.status_code}")
                return None
        
        except Exception as e:
            logger.error(f"Place details error: {str(e)}")
            return None


# 싱글톤 인스턴스
google_maps_service = GoogleMapsService()

