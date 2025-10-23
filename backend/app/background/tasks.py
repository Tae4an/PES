"""
백그라운드 작업 (재난문자 폴링)
"""
import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger
from sqlalchemy import select
from datetime import datetime, timedelta

from ..services.disaster_poller import DisasterPoller
from ..services.shelter_finder import ShelterFinder
from ..services.llm_service import LLMService
from ..external.fcm_client import fcm_client
from ..models.user import User
from ..models.disaster import Disaster
from ..db.session import AsyncSessionLocal
from ..core.config import settings

logger = logging.getLogger(__name__)


class DisasterPollingTask:
    """재난문자 폴링 백그라운드 작업"""
    
    def __init__(self):
        self.scheduler = AsyncIOScheduler()
        self.disaster_poller = DisasterPoller()
        self.llm_service = LLMService()
        self.is_running = False
    
    async def start(self):
        """폴링 작업 시작"""
        if self.is_running:
            logger.warning("Polling task already running")
            return
        
        # Redis 초기화
        await self.disaster_poller.initialize_redis()
        
        # 스케줄러 설정 (10초 간격)
        self.scheduler.add_job(
            self._poll_and_process,
            trigger=IntervalTrigger(seconds=settings.DISASTER_POLL_INTERVAL_SECONDS),
            id="disaster_polling",
            name="재난문자 폴링",
            replace_existing=True,
            max_instances=1
        )
        
        self.scheduler.start()
        self.is_running = True
        logger.info(f"Disaster polling started (interval: {settings.DISASTER_POLL_INTERVAL_SECONDS}s)")
    
    async def stop(self):
        """폴링 작업 중지"""
        if not self.is_running:
            return
        
        self.scheduler.shutdown()
        await self.disaster_poller.close()
        self.is_running = False
        logger.info("Disaster polling stopped")
    
    async def _poll_and_process(self):
        """재난문자 폴링 및 처리"""
        try:
            logger.info("Polling disasters...")
            
            # 재난문자 폴링
            new_disasters = await self.disaster_poller.poll_disasters()
            
            if not new_disasters:
                logger.debug("No new disasters found")
                return
            
            logger.info(f"Processing {len(new_disasters)} new disasters")
            
            # 각 재난에 대해 처리
            for disaster_data in new_disasters:
                await self._process_disaster(disaster_data)
                
        except Exception as e:
            logger.error(f"Error in polling task: {str(e)}", exc_info=True)
    
    async def _process_disaster(self, disaster_data: dict):
        """개별 재난 처리"""
        try:
            async with AsyncSessionLocal() as db:
                # 재난 정보 저장
                disaster = await self._save_disaster(db, disaster_data)
                
                if not disaster:
                    return
                
                # 활성 사용자 조회 (최근 1시간 내 위치 업데이트한 사용자)
                active_users = await self._get_active_users(db)
                
                logger.info(f"Found {len(active_users)} active users")
                
                # 각 사용자에 대해 처리
                notifications = []
                
                for user in active_users:
                    # 사용자 위치와 재난 지역 교차 판정 (간단한 거리 기반)
                    # 실제로는 PostGIS로 폴리곤 교차 판정해야 함
                    if await self._should_notify_user(db, user, disaster):
                        # 대피소 검색
                        shelter_finder = ShelterFinder(db)
                        shelters = await shelter_finder.get_shelters_within_radius(
                            latitude=user.location.latitude if user.location else 37.5665,
                            longitude=user.location.longitude if user.location else 126.9780,
                            radius_km=settings.DEFAULT_SHELTER_SEARCH_RADIUS_KM,
                            limit=settings.MAX_SHELTERS_RETURN
                        )
                        
                        # 행동카드 생성
                        user_profile = {
                            "age_group": user.age_group,
                            "mobility": user.mobility
                        }
                        
                        action_card, generation_method = await self.llm_service.generate_action_card(
                            disaster_type=disaster.disaster_type,
                            location=disaster.location,
                            user_profile=user_profile,
                            shelters=shelters
                        )
                        
                        # FCM 알림 준비
                        if user.fcm_token:
                            notifications.append({
                                "fcm_token": user.fcm_token,
                                "action_card": action_card,
                                "disaster_type": disaster.disaster_type,
                                "disaster_id": str(disaster.id),
                                "shelters": [
                                    {
                                        "name": s.name,
                                        "distance_km": s.distance_km,
                                        "walking_minutes": s.walking_minutes
                                    }
                                    for s in shelters
                                ]
                            })
                        
                        logger.info(f"Action card prepared for user {user.device_id}")
                
                # 배치 알림 발송
                if notifications:
                    result = await fcm_client.send_batch_notifications(notifications)
                    logger.info(f"Notifications sent: {result}")
                
        except Exception as e:
            logger.error(f"Error processing disaster: {str(e)}", exc_info=True)
    
    async def _save_disaster(self, db, disaster_data: dict):
        """재난 정보를 DB에 저장"""
        try:
            disaster = Disaster(
                msg_id=disaster_data.get('MD101_SN', ''),
                disaster_type=disaster_data.get('DSSTR_SE_NM', '기타'),
                location=disaster_data.get('RCV_AREA_NM', ''),
                message=disaster_data.get('MSG', ''),
                severity=disaster_data.get('EMRG_STEP_NM', ''),
                issued_at=datetime.fromisoformat(disaster_data.get('CRT_DT', datetime.now().isoformat()))
            )
            
            db.add(disaster)
            await db.commit()
            await db.refresh(disaster)
            
            logger.info(f"Disaster saved: {disaster.disaster_type} at {disaster.location}")
            return disaster
            
        except Exception as e:
            logger.error(f"Error saving disaster: {str(e)}")
            await db.rollback()
            return None
    
    async def _get_active_users(self, db):
        """활성 사용자 조회 (최근 1시간 내)"""
        try:
            one_hour_ago = datetime.utcnow() - timedelta(hours=1)
            
            query = select(User).where(
                User.is_active == True,
                User.last_location_update >= one_hour_ago
            )
            
            result = await db.execute(query)
            users = result.scalars().all()
            
            return users
            
        except Exception as e:
            logger.error(f"Error fetching active users: {str(e)}")
            return []
    
    async def _should_notify_user(self, db, user, disaster) -> bool:
        """사용자에게 알림을 보내야 하는지 판단"""
        # 간단한 구현: 모든 활성 사용자에게 알림
        # 실제로는 PostGIS로 위치 교차 판정
        
        if not user.location:
            return False
        
        # TODO: PostGIS ST_Intersects로 실제 교차 판정
        # 현재는 간단히 모든 활성 사용자에게 알림
        return True


# 싱글톤 인스턴스
disaster_polling_task = DisasterPollingTask()

