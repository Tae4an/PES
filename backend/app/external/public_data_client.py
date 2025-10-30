"""
공공데이터포털 대피소 API 클라이언트
"""
import httpx
import logging
from typing import List, Dict, Any

from ..core.config import settings

logger = logging.getLogger(__name__)


class PublicDataClient:
    """공공데이터포털 대피소 데이터 수집 클라이언트"""
    
    def __init__(self):
        self.base_url = "https://api.odcloud.kr/api"
        # ✅ 인코딩된 키를 그대로 사용 (unquote 제거)
        self.service_key = settings.PUBLIC_DATA_PORTAL_KEY
        self.timeout = 30.0
    
    async def fetch_shelters(
        self,
        page: int = 1,
        per_page: int = 100
    ) -> Dict[str, Any]:
        """
        대피소 데이터 조회
        
        Args:
            page: 페이지 번호 (1부터 시작)
            per_page: 페이지당 결과 수 (최대 1000)
        
        Returns:
            API 응답 데이터
        """
        try:
            # 공공데이터포털 대피소 API 엔드포인트
            endpoint = f"{self.base_url}/15134734/v1/uddi:c9f22ef9-a20e-4b8f-b902-ab079951de68"
            
            # httpx가 자동으로 인코딩하지 않도록 URL에 직접 포함
            url = f"{endpoint}?page={page}&perPage={per_page}&serviceKey={self.service_key}&returnType=JSON"
            
            logger.info(f"🔍 공공데이터 API 요청: page={page}, perPage={per_page}")
            logger.debug(f"📡 요청 URL: {url}")
            
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                # params 대신 URL에 직접 포함하여 자동 인코딩 방지
                response = await client.get(url)
                response.raise_for_status()
                
                data = response.json()
                
                current_count = data.get("currentCount", 0)
                match_count = data.get("matchCount", 0)
                
                logger.info(f"✅ 대피소 데이터 조회 성공: {current_count}건 (전체: {match_count}건)")
                
                return data
        
        except httpx.HTTPError as e:
            logger.error(f"❌ 공공데이터 API 호출 실패: {e}")
            # 응답 내용 출력 (디버깅용)
            if hasattr(e, 'response') and e.response is not None:
                logger.error(f"응답 내용: {e.response.text}")
            raise
        except Exception as e:
            logger.error(f"❌ 대피소 데이터 조회 실패: {e}")
            raise
    
    async def fetch_all_shelters(self, max_pages: int = 50) -> List[Dict[str, Any]]:
        """
        전체 대피소 데이터 조회 (자동 페이징)
        
        Args:
            max_pages: 최대 페이지 수 (무한 루프 방지)
        
        Returns:
            전체 대피소 목록
        """
        all_shelters = []
        page = 1
        per_page = 100
        
        try:
            while page <= max_pages:
                data = await self.fetch_shelters(page=page, per_page=per_page)
                
                items = data.get("data", [])
                
                if not items:
                    break
                
                all_shelters.extend(items)
                logger.info(f"📄 페이지 {page} 수집 완료: {len(items)}건 (누적: {len(all_shelters)}건)")
                
                # 전체 개수 확인
                match_count = data.get("matchCount", 0)
                if len(all_shelters) >= match_count:
                    break
                
                page += 1
            
            logger.info(f"🎉 전체 대피소 수집 완료: {len(all_shelters)}건")
            return all_shelters
        
        except Exception as e:
            logger.error(f"❌ 전체 대피소 수집 실패: {e}")
            return all_shelters


# 싱글톤 인스턴스
public_data_client = PublicDataClient()