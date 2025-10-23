"""
행정안전부 재난문자 10초 폴링 서비스
"""
import httpx
import asyncio
from typing import List, Dict, Optional
import logging
from datetime import datetime
import redis.asyncio as aioredis

from ..core.config import settings

logger = logging.getLogger(__name__)


class DisasterPoller:
    """재난문자 폴링 서비스"""
    
    def __init__(self):
        self.api_url = settings.DISASTER_API_URL
        self.api_key = settings.DISASTER_API_KEY
        self.timeout = settings.DISASTER_API_TIMEOUT
        self.redis_client: Optional[aioredis.Redis] = None
        self.cache_ttl = settings.REDIS_CACHE_TTL
    
    async def initialize_redis(self):
        """Redis 클라이언트 초기화"""
        try:
            self.redis_client = await aioredis.from_url(
                settings.REDIS_URL,
                encoding="utf-8",
                decode_responses=True
            )
            logger.info("Redis client initialized")
        except Exception as e:
            logger.error(f"Failed to initialize Redis: {str(e)}")
            self.redis_client = None
    
    async def poll_disasters(self) -> List[Dict]:
        """
        행정안전부 API에서 재난문자 폴링
        
        Returns:
            새로운 재난문자 리스트
        """
        try:
            params = {
                "serviceKey": self.api_key,
                "pageNo": 1,
                "numOfRows": 50,
                "type": "json"
            }
            
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(self.api_url, params=params)
            
            if response.status_code != 200:
                logger.error(f"Disaster API error: {response.status_code}")
                return []
            
            data = response.json()
            
            # API 응답 구조에 따라 수정 필요
            disasters = data.get('DisasterMsg', [])
            if isinstance(disasters, dict):
                disasters = disasters.get('row', [])
            
            # 새로운 재난만 필터링
            new_disasters = []
            for disaster in disasters:
                msg_id = disaster.get('MD101_SN', str(disaster.get('create_date', '')))
                
                # Redis 캐시 확인
                if await self._is_new_disaster(msg_id):
                    new_disasters.append(disaster)
                    await self._cache_disaster(msg_id)
            
            if new_disasters:
                logger.info(f"Found {len(new_disasters)} new disasters")
            
            return new_disasters
            
        except asyncio.TimeoutError:
            logger.warning("Disaster API timeout")
            return []
        except Exception as e:
            logger.error(f"Error polling disasters: {str(e)}")
            return []
    
    async def _is_new_disaster(self, msg_id: str) -> bool:
        """재난문자가 새로운 것인지 확인 (Redis 캐시)"""
        if not self.redis_client:
            return True
        
        try:
            cache_key = f"disaster:{msg_id}"
            exists = await self.redis_client.exists(cache_key)
            return not bool(exists)
        except Exception as e:
            logger.error(f"Redis check error: {str(e)}")
            return True
    
    async def _cache_disaster(self, msg_id: str):
        """재난문자를 Redis에 캐시"""
        if not self.redis_client:
            return
        
        try:
            cache_key = f"disaster:{msg_id}"
            await self.redis_client.setex(
                cache_key,
                self.cache_ttl,
                datetime.utcnow().isoformat()
            )
        except Exception as e:
            logger.error(f"Redis cache error: {str(e)}")
    
    async def close(self):
        """리소스 정리"""
        if self.redis_client:
            await self.redis_client.close()


# 더미 데이터 (API 키가 없을 때 테스트용)
async def get_mock_disasters() -> List[Dict]:
    """테스트용 더미 재난문자"""
    return [
        {
            "MD101_SN": "TEST_20251023_001",
            "MSG": "[호우 경보] 서울 영등포구에 호우 경보가 발령되었습니다. 즉시 안전한 곳으로 대피하세요.",
            "DSSTR_SE_NM": "호우",
            "RCV_AREA_NM": "서울시 영등포구",
            "EMRG_STEP_NM": "경보",
            "CRT_DT": datetime.now().isoformat(),
            "location_lat": 37.5263,
            "location_lng": 126.8962
        }
    ]

