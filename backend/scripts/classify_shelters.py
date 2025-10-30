"""
대피소 유형 자동 분류 스크립트
지진 / 해일 / 민방위(전쟁) / 기타로 분류
"""
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.db.session import ShelterAsyncSessionLocal
from sqlalchemy import select
from app.models.shelter import Shelter

# 분류 규칙 (우선순위 순서)
CLASSIFICATION_RULES = {
    '민방위대피소': {
        'keywords': {
            'name': ['민방위교육장', '지하보도', '지하상가', '지하철'],
            'address': [],
            'description': ['민방위', '지하보도', '지하상가', '지하철']
        },
        'priority': 1,
        'score_weight': 20
    },
    '지진대피소': {
        'keywords': {
            'name': [
                '초등학교', '중학교', '고등학교', '대학교', '학교',
                '체육관', '운동장', '주민센터', '복지관', '구청',
                '동사무소', '면사무소', '시청', '병원'
            ],
            'address': [],
            'description': ['학교', '체육관', '운동장', '공공시설']
        },
        'priority': 2,
        'score_weight': 15
    },
    '해일대피소': {
        'keywords': {
            'name': ['CC', '골프', '컨트리클럽', '리조트', '호텔'],
            'address': [
                '대부', '선감', '풍도', '육도', 
                '대부남동', '대부북동', '대부동동',
                '대부북', '대부남'
            ],
            'description': ['고지대', '언덕', '산', '해안']
        },
        'priority': 3,
        'score_weight': 25  # 해안가는 가중치 높게
    },
    '기타대피소': {
        'keywords': {
            'name': [
                '교회', '성당', '사찰', '절',
                '아파트', '빌딩', '타워', '프라자',
                '주차장', '오피스텔', '연립', '빌라'
            ],
            'address': [],
            'description': ['주차장', '지하', '아파트']
        },
        'priority': 4,
        'score_weight': 5
    }
}


def classify_shelter(name: str, address: str, description: str) -> str:
    """
    대피소 정보를 기반으로 유형 분류
    
    Args:
        name: 대피소 이름
        address: 주소
        description: 설명
    
    Returns:
        대피소 유형
    """
    name = name or ''
    address = address or ''
    description = description or ''
    
    # 각 유형별 점수 계산
    type_scores = []
    
    for shelter_type, rules in CLASSIFICATION_RULES.items():
        score = 0
        
        # 이름 매칭
        for keyword in rules['keywords']['name']:
            if keyword in name:
                score += rules['score_weight']
        
        # 주소 매칭 (가중치 높음 - 특히 해일대피소)
        for keyword in rules['keywords']['address']:
            if keyword in address:
                score += rules['score_weight'] * 3  # 주소 매칭은 강력한 신호
        
        # 설명 매칭
        for keyword in rules['keywords']['description']:
            if keyword in description:
                score += rules['score_weight'] * 0.5
        
        if score > 0:
            type_scores.append((shelter_type, score, rules['priority']))
    
    if type_scores:
        # 점수가 가장 높은 유형 선택, 같으면 우선순위가 높은 것
        type_scores.sort(key=lambda x: (-x[1], x[2]))
        return type_scores[0][0]
    
    return '기타대피소'


async def main():
    """대피소 유형 자동 분류"""
    
    print("=" * 70)
    print("🏢 대피소 유형 자동 분류")
    print("=" * 70)
    print()
    print("분류 기준:")
    print("  1. 🌊 지진대피소    - 학교, 체육관, 공공시설 (넓은 공간)")
    print("  2. 🌀 해일대피소    - 고지대, 해안가 CC/리조트")
    print("  3. ⚔️  민방위대피소  - 지하보도, 지하상가, 민방위교육장")
    print("  4. 📦 기타대피소    - 교회, 아파트, 기타 시설")
    print()
    
    async with ShelterAsyncSessionLocal() as db:
        try:
            # 1. 모든 대피소 조회
            result = await db.execute(select(Shelter))
            shelters = result.scalars().all()
            
            if not shelters:
                print("❌ 분류할 대피소가 없습니다.")
                return
            
            print(f"📊 분류 대상: {len(shelters)}개")
            
            # 사용자 확인
            response = input(f"\n{len(shelters)}개의 대피소를 재분류하시겠습니까? (y/N): ")
            if response.lower() != 'y':
                print("취소되었습니다.")
                return
            
            print("\n분류 중...\n")
            
            # 2. 각 대피소 분류
            classification_stats = {
                '지진대피소': 0,
                '해일대피소': 0,
                '민방위대피소': 0,
                '기타대피소': 0
            }
            
            updated_count = 0
            
            for idx, shelter in enumerate(shelters, 1):
                new_type = classify_shelter(
                    shelter.name,
                    shelter.address,
                    shelter.description or ''
                )
                
                # 유형 업데이트
                shelter.shelter_type = new_type
                classification_stats[new_type] += 1
                updated_count += 1
                
                # 처음 20개만 출력
                if idx <= 20:
                    emoji_map = {
                        '지진대피소': '🌊',
                        '해일대피소': '🌀',
                        '민방위대피소': '⚔️',
                        '기타대피소': '📦'
                    }
                    emoji = emoji_map.get(new_type, '📦')
                    print(f"  {emoji} {new_type:12s} - {shelter.name[:40]}")
                
                # 100개마다 중간 커밋
                if updated_count % 100 == 0:
                    await db.commit()
                    print(f"\n💾 중간 저장: {updated_count}/{len(shelters)}")
                    print()
            
            # 3. 최종 커밋
            await db.commit()
            
            # 4. 결과 출력
            print("\n" + "=" * 70)
            print("✅ 분류 완료")
            print("=" * 70)
            
            total = sum(classification_stats.values())
            
            # 이모지와 함께 출력
            emoji_map = {
                '지진대피소': '🌊',
                '해일대피소': '🌀',
                '민방위대피소': '⚔️',
                '기타대피소': '📦'
            }
            
            # 정렬된 순서로 출력
            for shelter_type in ['지진대피소', '해일대피소', '민방위대피소', '기타대피소']:
                count = classification_stats[shelter_type]
                percentage = (count / total * 100) if total > 0 else 0
                emoji = emoji_map.get(shelter_type, '📦')
                print(f"{emoji} {shelter_type:12s}: {count:3d}개 ({percentage:5.1f}%)")
            
            # 5. 샘플 확인
            print("\n" + "=" * 70)
            print("📋 분류 샘플 (각 유형별 5개)")
            print("=" * 70)
            
            for shelter_type in ['지진대피소', '해일대피소', '민방위대피소', '기타대피소']:
                result = await db.execute(
                    select(Shelter)
                    .where(Shelter.shelter_type == shelter_type)
                    .limit(5)
                )
                samples = result.scalars().all()
                
                if samples:
                    emoji = emoji_map.get(shelter_type, '📦')
                    print(f"\n{emoji} [{shelter_type}]")
                    for s in samples:
                        addr_short = s.address[:35] + '...' if len(s.address) > 35 else s.address
                        print(f"  • {s.name[:30]:30s} | {addr_short}")
            
            print("\n" + "=" * 70)
            
        except Exception as e:
            print(f"\n❌ 오류 발생: {e}")
            import traceback
            traceback.print_exc()
            await db.rollback()
        finally:
            await db.close()


if __name__ == "__main__":
    asyncio.run(main())