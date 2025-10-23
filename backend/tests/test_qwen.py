"""
Qwen3 8B LLM 테스트 스크립트
"""
import asyncio
import httpx
import sys
import os

# 프로젝트 루트를 path에 추가
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.services.llm_service import LLMService
from app.api.v1.schemas.shelter import ShelterInfo
import uuid


async def test_qwen_direct():
    """Ollama API 직접 테스트"""
    print("=" * 60)
    print("Qwen3 8B 직접 테스트")
    print("=" * 60)
    
    prompt = """당신은 대한민국 정부의 재난안전 전문가입니다.
호우 경보 상황에서 서울시 영등포구에 있는 성인에게 즉시 행동 지침을 정확히 3~5줄로 작성하세요.

가장 가까운 대피소:
1. 영등포초등학교 (도보 3분)
2. 영등포구민체육센터 (도보 5분)
3. 영등포도서관 (도보 7분)

규칙: 구체적 행동만, 금지사항 포함, 추측 절대 금지

행동 카드:"""
    
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.post(
                "http://localhost:11434/api/generate",
                json={
                    "model": "qwen3:8b-instruct",
                    "prompt": prompt,
                    "temperature": 0.3,
                    "stream": False
                }
            )
        
        if response.status_code == 200:
            result = response.json()
            print("\n✅ Qwen3 응답:")
            print("-" * 60)
            print(result['response'])
            print("-" * 60)
        else:
            print(f"\n❌ API 오류: {response.status_code}")
            print(response.text)
    
    except Exception as e:
        print(f"\n❌ 에러: {str(e)}")
        print("\n💡 Ollama가 실행 중인지 확인하세요:")
        print("   docker ps | grep ollama")
        print("   docker exec pes-ollama ollama list")


async def test_llm_service():
    """LLMService 클래스 테스트"""
    print("\n" + "=" * 60)
    print("LLMService 통합 테스트")
    print("=" * 60)
    
    llm_service = LLMService()
    
    # 샘플 대피소 데이터
    shelters = [
        ShelterInfo(
            id=uuid.uuid4(),
            name="영등포초등학교",
            address="서울시 영등포구 영등포로 123",
            shelter_type="초등학교",
            capacity=500,
            distance_km=0.25,
            walking_minutes=3,
            latitude=37.5263,
            longitude=126.8962
        ),
        ShelterInfo(
            id=uuid.uuid4(),
            name="영등포구민체육센터",
            address="서울시 영등포구 영등포로 234",
            shelter_type="체육관",
            capacity=800,
            distance_km=0.40,
            walking_minutes=5,
            latitude=37.5280,
            longitude=126.9000
        ),
        ShelterInfo(
            id=uuid.uuid4(),
            name="영등포도서관",
            address="서울시 영등포구 영등포로 345",
            shelter_type="도서관",
            capacity=300,
            distance_km=0.55,
            walking_minutes=7,
            latitude=37.5240,
            longitude=126.8920
        )
    ]
    
    user_profile = {
        "age_group": "성인",
        "mobility": "정상"
    }
    
    try:
        action_card, method = await llm_service.generate_action_card(
            disaster_type="호우",
            location="서울시 영등포구",
            user_profile=user_profile,
            shelters=shelters
        )
        
        print(f"\n✅ 행동카드 생성 성공 (방법: {method})")
        print("-" * 60)
        print(action_card)
        print("-" * 60)
        
        # 대피소 정보 출력
        print("\n📍 추천 대피소:")
        for i, shelter in enumerate(shelters, 1):
            print(f"  {i}. {shelter.name} - 도보 {shelter.walking_minutes}분 ({shelter.distance_km}km)")
    
    except Exception as e:
        print(f"\n❌ 에러: {str(e)}")


async def test_multiple_scenarios():
    """여러 재난 시나리오 테스트"""
    print("\n" + "=" * 60)
    print("다양한 재난 시나리오 테스트")
    print("=" * 60)
    
    llm_service = LLMService()
    
    scenarios = [
        {"disaster_type": "지진", "location": "서울시 강남구"},
        {"disaster_type": "태풍", "location": "부산시 해운대구"},
        {"disaster_type": "화재", "location": "서울시 영등포구"},
    ]
    
    shelter = ShelterInfo(
        id=uuid.uuid4(),
        name="대피소",
        address="주소",
        shelter_type="초등학교",
        capacity=500,
        distance_km=0.3,
        walking_minutes=4,
        latitude=37.5263,
        longitude=126.8962
    )
    
    user_profile = {"age_group": "성인", "mobility": "정상"}
    
    for scenario in scenarios:
        print(f"\n📢 {scenario['disaster_type']} 시나리오 ({scenario['location']})")
        print("-" * 60)
        
        try:
            action_card, method = await llm_service.generate_action_card(
                disaster_type=scenario["disaster_type"],
                location=scenario["location"],
                user_profile=user_profile,
                shelters=[shelter]
            )
            
            print(f"생성 방법: {method}")
            print(action_card)
            print()
        
        except Exception as e:
            print(f"❌ 에러: {str(e)}\n")


async def main():
    """메인 테스트 실행"""
    print("\n🚀 Qwen3 8B LLM 테스트 시작\n")
    
    # 1. Ollama API 직접 테스트
    await test_qwen_direct()
    
    # 2. LLMService 테스트
    await test_llm_service()
    
    # 3. 다양한 시나리오 테스트
    await test_multiple_scenarios()
    
    print("\n" + "=" * 60)
    print("✅ 모든 테스트 완료")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())

