"""
FCM (Firebase Cloud Messaging) 관련 API 엔드포인트
"""
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional
import logging
from datetime import datetime

from ....external.fcm_client import fcm_client

logger = logging.getLogger(__name__)

router = APIRouter()


class FCMTokenRequest(BaseModel):
    """FCM 토큰 등록 요청"""
    fcm_token: str = Field(..., description="Firebase Cloud Messaging 토큰")
    user_id: Optional[str] = Field(None, description="사용자 ID (선택사항)")
    device_type: str = Field("mobile", description="기기 유형 (mobile, tablet, web)")
    app_version: Optional[str] = Field(None, description="앱 버전")


class FCMTokenResponse(BaseModel):
    """FCM 토큰 등록 응답"""
    success: bool
    message: str
    token_id: Optional[str] = None
    registered_at: datetime


class TestNotificationRequest(BaseModel):
    """테스트 알림 요청"""
    fcm_token: str = Field(..., description="테스트할 FCM 토큰")
    title: str = Field("PES 테스트 알림", description="알림 제목")
    body: str = Field("Firebase 푸시 알림이 정상적으로 작동합니다!", description="알림 내용")


@router.post("/token/register", response_model=FCMTokenResponse)
async def register_fcm_token(request: FCMTokenRequest):
    """
    FCM 토큰 등록
    
    클라이언트 앱에서 생성된 FCM 토큰을 서버에 등록합니다.
    등록된 토큰은 재난 알림 발송 시 사용됩니다.
    
    **예시:**
    ```json
    {
        "fcm_token": "dA1B2c3D4e5F6g7H8i9J0k...",
        "user_id": "user123",
        "device_type": "mobile",
        "app_version": "1.0.0"
    }
    ```
    """
    try:
        # TODO: 실제 구현에서는 데이터베이스에 저장
        # 현재는 로깅만 수행
        logger.info(f"FCM 토큰 등록: {request.fcm_token[:20]}...")
        logger.info(f"사용자 ID: {request.user_id}, 기기: {request.device_type}")
        
        # Mock 응답 (실제로는 DB에 저장 후 ID 반환)
        token_id = f"token_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        return FCMTokenResponse(
            success=True,
            message="FCM 토큰이 성공적으로 등록되었습니다.",
            token_id=token_id,
            registered_at=datetime.now()
        )
        
    except Exception as e:
        logger.error(f"FCM 토큰 등록 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"FCM 토큰 등록 실패: {str(e)}"
        )


@router.post("/test/notification")
async def send_test_notification(request: TestNotificationRequest):
    """
    테스트 푸시 알림 전송
    
    지정된 FCM 토큰으로 테스트 알림을 전송합니다.
    Firebase 설정이 올바른지 확인하는 용도입니다.
    
    **예시:**
    ```json
    {
        "fcm_token": "dA1B2c3D4e5F6g7H8i9J0k...",
        "title": "PES 테스트",
        "body": "푸시 알림 테스트입니다!"
    }
    ```
    """
    try:
        # FCM 클라이언트 초기화 확인
        if not fcm_client.initialized:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Firebase Admin SDK가 초기화되지 않았습니다. 서비스 계정 키를 확인하세요."
            )
        
        # 테스트 알림 전송
        success = await fcm_client.send_action_card_to_user(
            fcm_token=request.fcm_token,
            action_card=f"{request.body}\n\n이것은 테스트 알림입니다.",
            disaster_type="테스트",
            disaster_id="test_001",
            shelters=[]
        )
        
        if success:
            logger.info(f"테스트 알림 전송 성공: {request.fcm_token[:20]}...")
            return {
                "success": True,
                "message": "테스트 알림이 성공적으로 전송되었습니다.",
                "sent_at": datetime.now().isoformat()
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="알림 전송에 실패했습니다. FCM 토큰을 확인하세요."
            )
            
    except HTTPException:
        raise  # 이미 처리된 HTTP 예외는 다시 발생
    except Exception as e:
        logger.error(f"테스트 알림 전송 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"테스트 알림 전송 실패: {str(e)}"
        )


@router.get("/status")
async def get_fcm_status():
    """
    FCM 서비스 상태 확인
    
    Firebase Admin SDK 초기화 상태와 설정을 확인합니다.
    """
    try:
        return {
            "fcm_initialized": fcm_client.initialized,
            "firebase_available": fcm_client.initialized,
            "service_status": "active" if fcm_client.initialized else "inactive",
            "checked_at": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"FCM 상태 확인 실패: {e}")
        return {
            "fcm_initialized": False,
            "firebase_available": False,
            "service_status": "error",
            "error": str(e),
            "checked_at": datetime.now().isoformat()
        }


@router.post("/emergency/broadcast")
async def send_emergency_broadcast(
    disaster_type: str,
    action_card: str,
    disaster_id: str,
    target_tokens: list[str]
):
    """
    긴급 재난 알림 일괄 전송
    
    여러 사용자에게 동시에 재난 알림을 전송합니다.
    실제 재난 상황에서 사용되는 API입니다.
    
    **주의: 이 API는 관리자 권한이 필요합니다.**
    """
    try:
        if not fcm_client.initialized:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Firebase Admin SDK가 초기화되지 않았습니다."
            )
        
        # 배치 알림 데이터 준비
        notifications = []
        for token in target_tokens:
            notifications.append({
                "fcm_token": token,
                "action_card": action_card,
                "disaster_type": disaster_type,
                "disaster_id": disaster_id,
                "shelters": []  # TODO: 실제 대피소 데이터 연동
            })
        
        # 배치 전송
        result = await fcm_client.send_batch_notifications(notifications)
        
        logger.info(f"긴급 알림 배치 전송 완료: {result}")
        
        return {
            "success": True,
            "message": "긴급 알림이 전송되었습니다.",
            "total_sent": len(target_tokens),
            "success_count": result["success"],
            "failed_count": result["failed"],
            "sent_at": datetime.now().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"긴급 알림 전송 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"긴급 알림 전송 실패: {str(e)}"
        )
