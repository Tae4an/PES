"""
공공데이터포털 대피소 데이터 Import 서비스
"""
import logging
from typing import List, Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete, text
from datetime import datetime
import uuid
import asyncio

from ..models.shelter import Shelter
from ..external.public_data_client import public_data_client
from ..external.google_maps import get_coordinates_from_address

logger = logging.getLogger(__name__)


class ShelterImportService:
    """공공데이터포털 대피소 데이터 Import 서비스"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def import_shelters_from_public_data(
        self,
        max_shelters: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        공공데이터포털에서 대피소 데이터 수집 및 저장
        
        Args:
            max_shelters: 최대 수집 개수 (None이면 전체)
        
        Returns:
            {
                "total": 수집된 총 개수,
                "success": 성공 개수,
                "failed": 실패 개수,
                "errors": 오류 목록
            }
        """
        try:
            # 1. 공공데이터 API에서 데이터 수집
            logger.info("🔍 공공데이터포털 대피소 데이터 수집 시작")
            shelter_data = await public_data_client.fetch_all_shelters()
            
            if not shelter_data:
                logger.warning("⚠️  수집된 대피소 데이터가 없습니다")
                return {"total": 0, "success": 0, "failed": 0, "errors": []}
            
            # 최대 개수 제한
            if max_shelters:
                shelter_data = shelter_data[:max_shelters]
            
            # 2. 데이터 변환 및 저장
            saved_count = 0
            failed_count = 0
            errors = []
            
            for idx, item in enumerate(shelter_data, 1):
                try:
                    # ✅ 로그 간소화 (10개마다만 출력)
                    if idx % 10 == 0 or idx == 1:
                        logger.info(f"처리 중: {idx}/{len(shelter_data)}")
                    
                    shelter = await self._create_shelter_from_api_data(item)
                    
                    if shelter:
                        self.db.add(shelter)
                        saved_count += 1
                        
                        # 100개마다 중간 커밋
                        if saved_count % 100 == 0:
                            await self.db.commit()
                            logger.info(f"💾 중간 저장: {saved_count}건")
                    else:
                        failed_count += 1
                
                except Exception as e:
                    failed_count += 1
                    continue
            
            # 3. 최종 커밋
            await self.db.commit()
            
            return {
                "total": len(shelter_data),
                "success": saved_count,
                "failed": failed_count,
                "errors": errors[:5]  # ✅ 5개만
            }
        
        except Exception as e:
            logger.error(f"❌ 수집 실패: {e}")
            await self.db.rollback()
            raise
    
    async def _create_shelter_from_api_data(
        self,
        data: Dict[str, Any]
    ) -> Optional[Shelter]:
        """
        공공데이터 API 데이터를 Shelter 모델로 변환
        
        Args:
            data: API 응답 데이터
        
        Returns:
            Shelter 모델 인스턴스 또는 None
        """
        try:
            # API 응답 필드 매핑
            name = data.get("제목") or data.get("시설명")
            address = data.get("도로명주소") or data.get("주소")
            shelter_type = data.get("분류") or data.get("재종") or "민방위대피소"
            phone = data.get("전화번호")
            description = data.get("설명")
            
            # 필수 필드 검증
            if not name or not address:
                logger.warning(f"⚠️  필수 필드 누락: name={name}, address={address}")
                return None
            
            # 위도/경도 추출
            latitude = None
            longitude = None
            
            # 1. API에서 좌표 제공하는 경우
            if "위도" in data and "경도" in data:
                try:
                    latitude = float(data["위도"])
                    longitude = float(data["경도"])
                except (ValueError, TypeError):
                    pass
            
            # 좌표 변환 (로그 제거)
            if not latitude or not longitude:
                coords = await get_coordinates_from_address(address)
                if coords:
                    latitude, longitude = coords
                    await asyncio.sleep(1.0)
                else:
                    return None
            
            # ✅ Shelter 모델 생성 (latitude/longitude 직접 저장)
            shelter = Shelter(
                id=uuid.uuid4(),
                name=name[:255],
                address=address[:512],
                shelter_type=self._normalize_shelter_type(shelter_type),
                latitude=latitude,  # ✅ 변경
                longitude=longitude,  # ✅ 변경
                capacity=self._extract_capacity(description),
                area_m2=None,
                phone=phone[:50] if phone else None,
                operator=data.get("운영기관"),
                description=description[:1000] if description else None,
                has_parking=None,
                has_generator=None
            )
            
            logger.debug(f"✅ 대피소 변환 완료: {name} ({latitude}, {longitude})")
            return shelter
        
        except Exception as e:
            logger.error(f"❌ 대피소 데이터 변환 오류: {e}, 데이터: {data}")
            return None
    
    def _normalize_shelter_type(self, shelter_type: Optional[str]) -> str:
        """대피소 유형 정규화"""
        if not shelter_type:
            return "민방위대피소"
        
        # 유형 매핑
        type_mapping = {
            "민방위": "민방위대피소",
            "지진": "지진대피소",
            "옥외": "지진옥외대피소",
            "초등": "초등학교",
            "중학": "중학교",
            "고등": "고등학교",
            "체육": "체육관",
            "주민센터": "공공시설",
            "면사무소": "공공시설",
            "동사무소": "공공시설"
        }
        
        for key, value in type_mapping.items():
            if key in shelter_type:
                return value
        
        return shelter_type[:100]  # 길이 제한
    
    def _extract_capacity(self, description: Optional[str]) -> Optional[int]:
        """설명에서 수용 인원 추출"""
        if not description:
            return None
        
        import re
        # "수용인원: 500명" 같은 패턴 찾기
        match = re.search(r'수용.*?(\d+)', description)
        if match:
            try:
                return int(match.group(1))
            except ValueError:
                pass
        
        return None
    
    async def clear_all_shelters(self) -> int:
        """
        기존 대피소 데이터 전체 삭제
        
        Returns:
            삭제된 레코드 수
        """
        try:
            result = await self.db.execute(delete(Shelter))
            count = result.rowcount
            await self.db.commit()
            
            logger.info(f"🗑️  기존 대피소 데이터 삭제 완료: {count}건")
            return count
        
        except Exception as e:
            logger.error(f"❌ 대피소 데이터 삭제 실패: {e}")
            await self.db.rollback()
            raise
    
    async def get_shelter_count(self) -> int:
        """현재 저장된 대피소 개수 조회"""
        try:
            result = await self.db.execute(
                text("SELECT COUNT(*) FROM shelters")
            )
            count = result.scalar()
            return count or 0
        except Exception as e:
            logger.error(f"❌ 대피소 개수 조회 실패: {e}")
            return 0