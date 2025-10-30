"""
재난 데이터 서비스
CSV Mock 데이터와 실제 API를 전환하여 제공
"""
import csv
import logging
from typing import List, Optional
from datetime import datetime
from pathlib import Path

from ..core.config import settings
from ..api.v1.schemas.disaster import MockDisasterMessage

logger = logging.getLogger(__name__)


class DisasterService:
    """
    재난 데이터 서비스
    - CSV 파일에서 Mock 데이터 로드
    - Mock/Real API 모드 전환
    """
    
    def __init__(self):
        """초기화"""
        self._mock_data: List[MockDisasterMessage] = []
        self._mock_mode: bool = settings.USE_MOCK_DATA
        self._load_mock_data()
    
    def _load_mock_data(self) -> None:
        """
        CSV 파일에서 Mock 데이터를 로드하여 Pydantic 모델로 변환
        """
        try:
            settings.MOCK_DATA_PATH = settings.MOCK_DATA_PATH[:-1]
            csv_path = Path(settings.MOCK_DATA_PATH)
            
            if not csv_path.exists():
                logger.warning(f"❌ Mock 데이터 파일을 찾을 수 없습니다: {csv_path}")
                return
            
            with open(csv_path, 'r', encoding='utf-8-sig') as f:  # BOM 처리
                reader = csv.DictReader(f)
                
                for row in reader:
                    try:
                        # 날짜 + 시간 조합하여 datetime 생성
                        date_str = row['날짜']
                        time_str = row['시간']
                        issued_at = datetime.strptime(f"{date_str} {time_str}", "%Y-%m-%d %H:%M")
                        
                        # Pydantic 모델로 변환
                        disaster_msg = MockDisasterMessage(
                            serial_number=int(row['연번']),
                            date=date_str,
                            time=time_str,
                            category=row['구분'],
                            message=row['문자전송내용'],
                            issued_at=issued_at
                        )
                        
                        self._mock_data.append(disaster_msg)
                    
                    except (ValueError, KeyError) as e:
                        logger.error(f"⚠️  CSV 행 파싱 실패: {row}, 에러: {e}")
                        continue
            
            logger.info(f"✅ Mock 데이터 로드 완료: {len(self._mock_data)}개")
        
        except Exception as e:
            logger.error(f"❌ Mock 데이터 로드 실패: {e}")
            self._mock_data = []
    
    def get_mock_disasters(self, limit: int = 5) -> List[MockDisasterMessage]:
        """
        최신 N개의 Mock 재난문자 반환
        
        Args:
            limit: 반환할 개수 (기본 5개)
        
        Returns:
            List[MockDisasterMessage]: Mock 재난문자 목록
        """
        # 발령 시각 기준 내림차순 정렬 (최신순)
        sorted_data = sorted(
            self._mock_data,
            key=lambda x: x.issued_at,
            reverse=True
        )
        
        return sorted_data[:limit]
    
    def get_all_mock_disasters(self) -> List[MockDisasterMessage]:
        """
        모든 Mock 재난문자 반환
        
        Returns:
            List[MockDisasterMessage]: 전체 Mock 재난문자 목록
        """
        return sorted(
            self._mock_data,
            key=lambda x: x.issued_at,
            reverse=True
        )
    
    def filter_mock_disasters(
        self,
        category: Optional[str] = None,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None
    ) -> List[MockDisasterMessage]:
        """
        조건에 맞는 Mock 재난문자 필터링
        
        Args:
            category: 재난 구분 (기상특보, 지진, 교통, 사회재난)
            start_date: 시작 날짜 (YYYY-MM-DD)
            end_date: 종료 날짜 (YYYY-MM-DD)
        
        Returns:
            List[MockDisasterMessage]: 필터링된 재난문자 목록
        """
        filtered = self._mock_data.copy()
        
        # 카테고리 필터
        if category:
            filtered = [d for d in filtered if d.category == category]
        
        # 날짜 범위 필터
        if start_date:
            start_dt = datetime.strptime(start_date, "%Y-%m-%d")
            filtered = [d for d in filtered if d.issued_at >= start_dt]
        
        if end_date:
            end_dt = datetime.strptime(f"{end_date} 23:59:59", "%Y-%m-%d %H:%M:%S")
            filtered = [d for d in filtered if d.issued_at <= end_dt]
        
        return sorted(filtered, key=lambda x: x.issued_at, reverse=True)
    
    def toggle_mock_mode(self) -> bool:
        """
        Mock 모드 ON/OFF 전환
        
        Returns:
            bool: 변경 후 Mock 모드 상태
        """
        self._mock_mode = not self._mock_mode
        
        mode_str = "Mock CSV" if self._mock_mode else "Real API"
        logger.info(f"🔄 재난 데이터 모드 전환: {mode_str}")
        
        return self._mock_mode
    
    def set_mock_mode(self, enabled: bool) -> bool:
        """
        Mock 모드 상태 설정
        
        Args:
            enabled: True=Mock 모드, False=Real API 모드
        
        Returns:
            bool: 설정된 Mock 모드 상태
        """
        self._mock_mode = enabled
        
        mode_str = "Mock CSV" if enabled else "Real API"
        logger.info(f"⚙️  재난 데이터 모드 설정: {mode_str}")
        
        return self._mock_mode
    
    @property
    def is_mock_mode(self) -> bool:
        """현재 Mock 모드 활성화 여부"""
        return self._mock_mode
    
    @property
    def mock_data_count(self) -> int:
        """Mock 데이터 총 개수"""
        return len(self._mock_data)
    
    @property
    def data_source(self) -> str:
        """현재 데이터 소스"""
        return "mock_csv" if self._mock_mode else "real_api"
    
    def reload_mock_data(self) -> int:
        """
        Mock 데이터 재로드
        
        Returns:
            int: 로드된 데이터 개수
        """
        self._mock_data.clear()
        self._load_mock_data()
        
        logger.info(f"🔄 Mock 데이터 재로드 완료: {len(self._mock_data)}개")
        
        return len(self._mock_data)
    
    def get_disaster_statistics(self) -> dict:
        """
        재난 통계 정보 반환
        
        Returns:
            dict: 카테고리별 재난 발생 건수
        """
        stats = {}
        
        for disaster in self._mock_data:
            category = disaster.category
            stats[category] = stats.get(category, 0) + 1
        
        return stats


# 싱글톤 인스턴스
disaster_service = DisasterService()

