"""
공공데이터포털 대피소 데이터 수집 스크립트
"""
import asyncio
import sys
from pathlib import Path

# 프로젝트 루트를 Python 경로에 추가
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.db.session import shelter_engine, AsyncSessionLocal
from app.core.config import settings
from app.services.shelter_import_service import ShelterImportService
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def main():
    """대피소 데이터 수집 및 저장"""
    
    print("=" * 60)
    print("🏢 공공데이터포털 대피소 데이터 수집 시작")
    print("=" * 60)
    
    # 로컬 대피소 DB 연결 정보 출력
    if settings.use_local_shelter_db:
        print(f"\n🔗 연결 대상: 로컬 대피소 DB")
        print(f"   호스트: {settings.LOCAL_SHELTER_DB_HOST}:{settings.LOCAL_SHELTER_DB_PORT}")
        print(f"   데이터베이스: {settings.LOCAL_SHELTER_DB_NAME}")
        print(f"   사용자: {settings.LOCAL_SHELTER_DB_USER}")
    else:
        print(f"\n🔗 연결 대상: 기본 DB")
        print(f"   URL: {settings.DATABASE_URL}")
    
    # shelter_engine을 사용한 세션 생성
    from sqlalchemy.ext.asyncio import async_sessionmaker, AsyncSession
    
    # 로컬 대피소 DB용 세션 팩토리 생성
    ShelterSessionLocal = async_sessionmaker(
        shelter_engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autocommit=False,
        autoflush=False
    )
    
    async with ShelterSessionLocal() as db:
        try:
            # 연결 테스트
            from sqlalchemy import text
            result = await db.execute(text("SELECT current_database(), version()"))
            db_name, version = result.fetchone()
            print(f"\n✅ DB 연결 성공: {db_name}")
            print(f"   PostgreSQL 버전: {version.split(',')[0]}")
            
            import_service = ShelterImportService(db)
            
            # 1. 현재 대피소 개수 확인
            current_count = await import_service.get_shelter_count()
            print(f"\n📊 현재 저장된 대피소: {current_count}개")
            
            # 2. 기존 데이터 삭제 여부 확인
            if current_count > 0:
                response = input(f"\n⚠️  기존 {current_count}개 대피소를 삭제하고 새로 수집하시겠습니까? (y/N): ")
                if response.lower() == 'y':
                    deleted_count = await import_service.clear_all_shelters()
                    print(f"🗑️  기존 데이터 삭제 완료: {deleted_count}개")
            
            # 3. 수집 개수 설정
            max_shelters = input("\n최대 수집 개수를 입력하세요 (Enter: 전체 수집): ").strip()
            max_shelters = int(max_shelters) if max_shelters else None
            
            if max_shelters:
                print(f"\n🔍 최대 {max_shelters}개 대피소 수집 시작...")
            else:
                print("\n🔍 전체 대피소 수집 시작...")
            
            # 4. 데이터 수집
            result = await import_service.import_shelters_from_public_data(max_shelters=max_shelters)
            
            # 5. 결과 출력
            print("\n" + "=" * 60)
            print("✅ 대피소 데이터 수집 완료")
            print("=" * 60)
            print(f"총 수집 시도: {result['total']}개")
            print(f"✅ 성공: {result['success']}개")
            print(f"❌ 실패: {result['failed']}개")
            
            if result['errors']:
                print("\n⚠️  오류 목록 (최대 10개):")
                for error in result['errors'][:10]:
                    print(f"  - {error}")
            
            # 6. 최종 확인
            final_count = await import_service.get_shelter_count()
            print(f"\n📊 최종 저장된 대피소: {final_count}개")
            
        except KeyboardInterrupt:
            print("\n\n⚠️  사용자에 의해 중단되었습니다.")
            await db.rollback()
        except Exception as e:
            print(f"\n❌ 오류 발생: {e}")
            logger.exception("대피소 수집 실패")
            await db.rollback()
        finally:
            await db.close()


if __name__ == "__main__":
    asyncio.run(main())