"""
관리자 API 엔드포인트
Mock/Real 모드 전환 등 관리 기능
"""
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
import logging

from ....services.disaster_service import disaster_service
from ....api.v1.schemas.disaster import MockModeStatus

logger = logging.getLogger(__name__)

router = APIRouter()


class ToggleMockModeRequest(BaseModel):
    """Mock 모드 전환 요청"""
    enabled: bool = Field(..., description="True=Mock 모드, False=Real API 모드")


class ToggleMockModeResponse(BaseModel):
    """Mock 모드 전환 응답"""
    success: bool = Field(..., description="전환 성공 여부")
    previous_mode: str = Field(..., description="이전 모드")
    current_mode: str = Field(..., description="현재 모드")
    message: str = Field(..., description="상태 메시지")


@router.post("/toggle-mock-mode", response_model=ToggleMockModeResponse)
async def toggle_mock_mode():
    """
    Mock/Real API 모드 토글
    
    **현재 모드를 반대로 전환**
    
    - Mock → Real API
    - Real API → Mock
    - 실시간 모드 전환 (재시작 불필요)
    
    **사용 예시:**
    ```bash
    curl -X POST http://localhost:8000/api/v1/admin/toggle-mock-mode
    ```
    """
    try:
        # 이전 모드 저장
        previous_mode = "Mock CSV" if disaster_service.is_mock_mode else "Real API"
        
        # 모드 전환
        new_mode_enabled = disaster_service.toggle_mock_mode()
        current_mode = "Mock CSV" if new_mode_enabled else "Real API"
        
        logger.info(f"🔄 모드 전환: {previous_mode} → {current_mode}")
        
        return ToggleMockModeResponse(
            success=True,
            previous_mode=previous_mode,
            current_mode=current_mode,
            message=f"재난 데이터 모드가 {current_mode}(으)로 전환되었습니다."
        )
    
    except Exception as e:
        logger.error(f"❌ Mock 모드 전환 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"모드 전환 실패: {str(e)}"
        )


@router.post("/set-mock-mode", response_model=ToggleMockModeResponse)
async def set_mock_mode(request: ToggleMockModeRequest):
    """
    Mock 모드 명시적 설정
    
    **Mock 또는 Real API 모드로 직접 설정**
    
    - `enabled=true`: Mock CSV 모드
    - `enabled=false`: Real API 모드
    - 1초 이내 즉시 적용
    
    **사용 예시:**
    ```bash
    # Mock 모드로 설정
    curl -X POST http://localhost:8000/api/v1/admin/set-mock-mode \
      -H "Content-Type: application/json" \
      -d '{"enabled": true}'
    
    # Real API 모드로 설정
    curl -X POST http://localhost:8000/api/v1/admin/set-mock-mode \
      -H "Content-Type: application/json" \
      -d '{"enabled": false}'
    ```
    """
    try:
        # 이전 모드 저장
        previous_mode = "Mock CSV" if disaster_service.is_mock_mode else "Real API"
        
        # 모드 설정
        disaster_service.set_mock_mode(request.enabled)
        current_mode = "Mock CSV" if request.enabled else "Real API"
        
        logger.info(f"⚙️  모드 설정: {previous_mode} → {current_mode}")
        
        return ToggleMockModeResponse(
            success=True,
            previous_mode=previous_mode,
            current_mode=current_mode,
            message=f"재난 데이터 모드가 {current_mode}(으)로 설정되었습니다."
        )
    
    except Exception as e:
        logger.error(f"❌ Mock 모드 설정 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"모드 설정 실패: {str(e)}"
        )


@router.get("/mock-mode-status", response_model=MockModeStatus)
async def get_mock_mode_status():
    """
    현재 Mock 모드 상태 확인
    
    **현재 재난 데이터 소스 및 통계 정보**
    
    - Mock 모드 활성화 여부
    - 데이터 소스 (mock_csv / real_api)
    - Mock 데이터 총 개수
    - 상태 메시지
    
    **사용 예시:**
    ```bash
    curl http://localhost:8000/api/v1/admin/mock-mode-status
    ```
    """
    try:
        mock_enabled = disaster_service.is_mock_mode
        data_source = disaster_service.data_source
        total_count = disaster_service.mock_data_count
        
        if mock_enabled:
            message = f"Mock 모드 활성화 - CSV 데이터 {total_count}개 로드됨"
        else:
            message = "Real API 모드 활성화 - 실제 행정안전부 API 사용 중"
        
        return MockModeStatus(
            mock_mode_enabled=mock_enabled,
            data_source=data_source,
            total_mock_messages=total_count,
            message=message
        )
    
    except Exception as e:
        logger.error(f"❌ Mock 모드 상태 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"상태 조회 실패: {str(e)}"
        )


@router.post("/reload-mock-data")
async def reload_mock_data():
    """
    Mock 데이터 재로드
    
    **CSV 파일을 다시 읽어서 Mock 데이터를 갱신**
    
    - CSV 파일 수정 후 재로드 시 사용
    - 재시작 없이 데이터 갱신
    
    **사용 예시:**
    ```bash
    curl -X POST http://localhost:8000/api/v1/admin/reload-mock-data
    ```
    """
    try:
        count = disaster_service.reload_mock_data()
        
        logger.info(f"🔄 Mock 데이터 재로드 완료: {count}개")
        
        return {
            "success": True,
            "reloaded_count": count,
            "message": f"Mock 데이터를 재로드했습니다. (총 {count}개)"
        }
    
    except Exception as e:
        logger.error(f"❌ Mock 데이터 재로드 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"재로드 실패: {str(e)}"
        )

