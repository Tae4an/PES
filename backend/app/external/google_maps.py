"""
Google Maps API 클라이언트 (주소 → 좌표 변환)
"""
import httpx
import logging
from typing import Optional, Tuple, List, Dict
import asyncio

from ..core.config import settings

logger = logging.getLogger(__name__)


async def get_coordinates_from_address(address: str) -> Optional[Tuple[float, float]]:
    """
    Google Maps Geocoding API를 사용하여 주소 → 좌표 변환
    
    Args:
        address: 도로명 주소
    
    Returns:
        (위도, 경도) 튜플 또는 None
    """
    if not settings.GOOGLE_MAPS_API_KEY:
        logger.warning("⚠️  Google Maps API 키가 설정되지 않음")
        return None
    
    try:
        url = "https://maps.googleapis.com/maps/api/geocode/json"
        params = {
            "address": address,
            "key": settings.GOOGLE_MAPS_API_KEY,
            "language": "ko"  # 한국어 결과
        }
        
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(url, params=params)
            response.raise_for_status()
            
            data = response.json()
            
            if data["status"] == "OK" and data["results"]:
                location = data["results"][0]["geometry"]["location"]
                latitude = location["lat"]
                longitude = location["lng"]
                
                logger.debug(f"✅ 좌표 변환 성공: {address} → ({latitude}, {longitude})")
                return (latitude, longitude)
            elif data["status"] == "ZERO_RESULTS":
                logger.warning(f"⚠️  주소를 찾을 수 없음: {address}")
                return None
            elif data["status"] == "OVER_QUERY_LIMIT":
                logger.error(f"❌ Google Maps API 할당량 초과")
                # 1초 대기 후 재시도
                await asyncio.sleep(1)
                return await get_coordinates_from_address(address)
            else:
                logger.warning(f"⚠️  좌표 변환 실패: {address}, status={data['status']}")
                return None
    
    except httpx.TimeoutException:
        logger.error(f"❌ Google Maps API 타임아웃: {address}")
        return None
    except Exception as e:
        logger.error(f"❌ Google Maps API 오류: {e}")
        return None


async def get_batch_coordinates(
    addresses: List[str],
    delay_ms: int = 200
) -> Dict[str, Optional[Tuple[float, float]]]:
    """
    여러 주소를 배치로 좌표 변환 (API 할당량 고려)
    
    Args:
        addresses: 주소 목록
        delay_ms: 요청 간 대기 시간 (밀리초)
    
    Returns:
        {주소: (위도, 경도)} 딕셔너리
    """
    results = {}
    
    for i, address in enumerate(addresses, 1):
        logger.info(f"좌표 변환 중: {i}/{len(addresses)} - {address}")
        
        coords = await get_coordinates_from_address(address)
        results[address] = coords
        
        # API 할당량 보호를 위한 지연
        if i < len(addresses):
            await asyncio.sleep(delay_ms / 1000.0)
    
    success_count = sum(1 for v in results.values() if v is not None)
    logger.info(f"✅ 좌표 변환 완료: {success_count}/{len(addresses)}건 성공")
    
    return results