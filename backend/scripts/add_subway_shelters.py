"""
안산시 지하철역을 민방위대피소로 추가하는 스크립트
정확한 주소 기반으로 좌표 자동 변환
"""
import asyncio
import sys
from pathlib import Path
import uuid
from datetime import datetime

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.db.session import ShelterAsyncSessionLocal
from app.models.shelter import Shelter
from app.external.google_maps import get_coordinates_from_address
from sqlalchemy import select

# 안산시 지하철역 데이터 (정확한 주소)
SUBWAY_STATIONS = [
    # 4호선 (6개역)
    {
        "name": "신길온천역 지하보도",
        "address": "경기 안산시 단원구 황고개로 2",
        "line": "4호선"
    },
    {
        "name": "안산역 지하보도",
        "address": "경기 안산시 단원구 중앙대로 462",
        "line": "4호선"
    },
    {
        "name": "초지역 지하보도",
        "address": "경기 안산시 단원구 중앙대로 620",
        "line": "4호선"
    },
    {
        "name": "중앙역 지하보도",
        "address": "경기 안산시 단원구 중앙대로 918",
        "line": "4호선"
    },
    {
        "name": "한대앞역 지하보도",
        "address": "경기 안산시 상록구 충장로 337",
        "line": "4호선"
    },
    {
        "name": "상록수역 지하보도",
        "address": "경기 안산시 상록구 상록수로 61",
        "line": "4호선"
    },
    # 수인선 (6개역)
    {
        "name": "반월역 지하보도",
        "address": "경기 안산시 상록구 건건로 119-10",
        "line": "수인선"
    },
    {
        "name": "사리역 지하보도",
        "address": "경기 안산시 상록구 충장로 103",
        "line": "수인선"
    },
    {
        "name": "원시역 지하보도",
        "address": "경기 안산시 단원구 산단로 70",
        "line": "수인선"
    },
    {
        "name": "시우역 지하보도",
        "address": "경기 안산시 단원구 동산로 50",
        "line": "수인선"
    },
    {
        "name": "선부역 지하보도",
        "address": "경기 안산시 단원구 선부광장로 68",
        "line": "수인선"
    },
    {
        "name": "달미역 지하보도",
        "address": "경기 안산시 단원구 순환로 160",
        "line": "수인선"
    }
]


async def main():
    """지하철역 민방위대피소 추가 (좌표 자동 변환)"""
    
    print("=" * 70)
    print("🚇 안산시 지하철역 민방위대피소 추가")
    print("=" * 70)
    print(f"\n추가할 지하철역: {len(SUBWAY_STATIONS)}개")
    print()
    
    # 노선별로 출력
    line_4 = [s for s in SUBWAY_STATIONS if s['line'] == '4호선']
    line_suin = [s for s in SUBWAY_STATIONS if s['line'] == '수인선']
    
    print(f"📍 4호선 ({len(line_4)}개역)")
    for idx, station in enumerate(line_4, 1):
        print(f"  {idx}. {station['name']} - {station['address']}")
    
    print(f"\n📍 수인선 ({len(line_suin)}개역)")
    for idx, station in enumerate(line_suin, 1):
        print(f"  {idx}. {station['name']} - {station['address']}")
    
    response = input(f"\n총 {len(SUBWAY_STATIONS)}개의 지하철역을 추가하시겠습니까? (y/N): ")
    if response.lower() != 'y':
        print("취소되었습니다.")
        return
    
    async with ShelterAsyncSessionLocal() as db:
        try:
            added_count = 0
            skipped_count = 0
            failed_count = 0
            
            print("\n🗺️  주소 → 좌표 변환 및 추가 중...\n")
            
            for idx, station in enumerate(SUBWAY_STATIONS, 1):
                # 중복 확인
                result = await db.execute(
                    select(Shelter).where(Shelter.name == station['name'])
                )
                existing = result.scalar_one_or_none()
                
                if existing:
                    print(f"⚠️  [{idx}/{len(SUBWAY_STATIONS)}] 이미 존재: {station['name']}")
                    skipped_count += 1
                    continue
                
                # 주소 → 좌표 변환
                print(f"🔍 [{idx}/{len(SUBWAY_STATIONS)}] 좌표 변환 중: {station['name']}")
                coords = await get_coordinates_from_address(station['address'])
                
                if not coords:
                    print(f"❌ 좌표 변환 실패: {station['address']}")
                    failed_count += 1
                    await asyncio.sleep(1.0)  # API 제한 대비
                    continue
                
                latitude, longitude = coords
                print(f"   ✅ 좌표: ({latitude:.6f}, {longitude:.6f})")
                
                # 새 대피소 추가
                shelter = Shelter(
                    id=uuid.uuid4(),
                    name=station['name'],
                    address=station['address'],
                    shelter_type='민방위대피소',
                    latitude=latitude,
                    longitude=longitude,
                    capacity=5000,  # 지하철역은 수용 인원 5000명으로 설정
                    phone='1666-1234',
                    operator='안산시 단원구' if '단원구' in station['address'] else '안산시 상록구',
                    description=f"민방위 대피소 : {station['name']} ({station['line']})",
                    created_at=datetime.utcnow(),
                    updated_at=datetime.utcnow()
                )
                
                db.add(shelter)
                added_count += 1
                print(f"   💾 추가 완료\n")
                
                # API 제한 대비 (Nominatim: 1초당 1요청)
                await asyncio.sleep(1.0)
            
            await db.commit()
            
            print("=" * 70)
            print("✅ 완료")
            print("=" * 70)
            print(f"추가된 지하철역: {added_count}개")
            print(f"이미 존재하는 역: {skipped_count}개")
            print(f"실패한 역: {failed_count}개")
            print(f"총 처리: {added_count + skipped_count + failed_count}개")
            print()
            
        except Exception as e:
            print(f"\n❌ 오류 발생: {e}")
            import traceback
            traceback.print_exc()
            await db.rollback()
        finally:
            await db.close()


if __name__ == "__main__":
    asyncio.run(main())