"""
Firebase Cloud Messaging 푸시 알림 클라이언트
"""
import logging
from typing import Optional, Dict, List
from datetime import datetime
import os

try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False
    logger = logging.getLogger(__name__)
    logger.warning("firebase_admin not installed")

from ..core.config import settings

logger = logging.getLogger(__name__)


class FCMClient:
    """Firebase Cloud Messaging 클라이언트"""
    
    def __init__(self):
        self.initialized = False
        self._initialize_firebase()
    
    def _initialize_firebase(self):
        """Firebase Admin SDK 초기화"""
        if not FIREBASE_AVAILABLE:
            logger.warning("Firebase Admin SDK not available")
            return
        
        try:
            # Firebase credentials 파일 확인
            cred_path = settings.FIREBASE_CREDENTIALS_PATH
            
            if not cred_path or not os.path.exists(cred_path):
                logger.warning(f"Firebase credentials not found at {cred_path}")
                return
            
            # Firebase 앱 초기화 (이미 초기화되었는지 확인)
            if not firebase_admin._apps:
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                logger.info("Firebase Admin SDK initialized")
            
            self.initialized = True
            
        except Exception as e:
            logger.error(f"Failed to initialize Firebase: {str(e)}")
            self.initialized = False
    
    async def send_action_card_to_user(
        self,
        fcm_token: str,
        action_card: str,
        disaster_type: str,
        disaster_id: str,
        shelters: List[Dict]
    ) -> bool:
        """
        사용자에게 행동카드 푸시 알림 발송
        
        Args:
            fcm_token: Firebase Cloud Messaging 토큰
            action_card: 행동카드 텍스트
            disaster_type: 재난 유형
            disaster_id: 재난 ID
            shelters: 대피소 리스트
        
        Returns:
            발송 성공 여부
        """
        if not self.initialized:
            logger.warning("FCM not initialized - skipping notification")
            return False
        
        try:
            # 알림 제목
            title = f"🚨 [{disaster_type} 경보] 즉시 대피 필요"
            
            # 알림 본문 (행동카드의 첫 줄 또는 요약)
            body_lines = action_card.split('\n')
            body = body_lines[1] if len(body_lines) > 1 else action_card[:100]
            
            # 푸시 메시지 생성
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                data={
                    "type": "action_card",
                    "disaster_id": disaster_id,
                    "disaster_type": disaster_type,
                    "action_card": action_card,
                    "shelters": str(shelters),
                    "timestamp": datetime.utcnow().isoformat()
                },
                android=messaging.AndroidConfig(
                    priority="high",
                    ttl=600,  # 10분
                    notification=messaging.AndroidNotification(
                        sound="emergency_alert",
                        priority="max",
                        channel_id="emergency"
                    )
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound="emergency_alert.caf",
                            badge=1,
                            content_available=True
                        )
                    )
                ),
                token=fcm_token
            )
            
            # 메시지 발송
            response = messaging.send(message)
            logger.info(f"FCM message sent successfully: {response}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send FCM message: {str(e)}")
            return False
    
    async def send_batch_notifications(
        self,
        notifications: List[Dict]
    ) -> Dict[str, int]:
        """
        배치로 여러 사용자에게 알림 발송
        
        Args:
            notifications: 알림 정보 리스트 
                [{fcm_token, action_card, disaster_type, ...}, ...]
        
        Returns:
            발송 결과 통계
        """
        if not self.initialized:
            logger.warning("FCM not initialized")
            return {"success": 0, "failed": len(notifications)}
        
        success_count = 0
        failed_count = 0
        
        for notif in notifications:
            result = await self.send_action_card_to_user(
                fcm_token=notif["fcm_token"],
                action_card=notif["action_card"],
                disaster_type=notif["disaster_type"],
                disaster_id=notif["disaster_id"],
                shelters=notif.get("shelters", [])
            )
            
            if result:
                success_count += 1
            else:
                failed_count += 1
        
        logger.info(f"Batch notification: {success_count} success, {failed_count} failed")
        return {"success": success_count, "failed": failed_count}


# 싱글톤 인스턴스
fcm_client = FCMClient()

