"""
Qwen3 8B 로컬 LLM 서비스 (행동카드 생성)
"""
import httpx
import asyncio
from typing import Optional, List, Dict
import logging
from datetime import datetime

from ..core.config import settings
from ..api.v1.schemas.shelter import ShelterInfo

logger = logging.getLogger(__name__)


class LLMService:
    """Qwen3 8B 기반 행동카드 생성 서비스"""
    
    def __init__(self):
        self.ollama_endpoint = settings.OLLAMA_ENDPOINT
        self.model = settings.OLLAMA_MODEL
        self.timeout = settings.OLLAMA_TIMEOUT
        self.temperature = settings.OLLAMA_TEMPERATURE
    
    async def generate_action_card(
        self,
        disaster_type: str,
        location: str,
        user_profile: Dict,
        shelters: List[ShelterInfo]
    ) -> tuple[str, str]:
        """
        Qwen3 8B로 개인화 행동카드 생성
        
        Args:
            disaster_type: 재난 유형
            location: 재난 발생 지역
            user_profile: 사용자 프로필 (age_group, mobility 등)
            shelters: 주변 대피소 목록
        
        Returns:
            (행동카드 텍스트, 생성 방법: 'llm' 또는 'fallback')
        """
        
        # 대피소 정보 포맷팅 (거리 정보 포함)
        if shelters:
            shelters_text = "\n".join([
                f"  {i+1}. {s.name} - 거리: {s.distance_km}km, 도보 {s.walking_minutes}분 ({s.address})"
                for i, s in enumerate(shelters[:3])
            ])
        else:
            shelters_text = "  (주변 대피소 정보 없음)"
        
        # 프롬프트 생성
        prompt = self._create_prompt(
            disaster_type=disaster_type,
            location=location,
            user_profile=user_profile,
            shelters_text=shelters_text
        )
        
        try:
            # Ollama API 호출
            logger.info(f"🔍 Ollama Request: model={self.model}, prompt_length={len(prompt)}, endpoint={self.ollama_endpoint}")
            logger.debug(f"🔍 Full prompt:\n{prompt[:200]}...")
            
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.ollama_endpoint}/api/generate",
                    json={
                        "model": self.model,
                        "prompt": prompt,
                        "stream": False
                        # options 제거 - Qwen3 모델이 thinking 모드로 전환되는 것을 방지
                    }
                )
            
            if response.status_code == 200:
                result = response.json()
                # Qwen3 모델은 thinking 모드에서 response가 비어있을 수 있음
                action_card = result.get('response', '').strip()
                
                logger.info(f"🔍 Ollama API Response: response={action_card[:50] if action_card else '(empty)'}")
                logger.debug(f"🔍 Full response field: {action_card}")
                
                # response가 비어있으면 thinking 필드 사용
                if not action_card:
                    action_card = result.get('thinking', '').strip()
                    logger.info(f"Using thinking field as response is empty")
                
                # 검증
                is_valid = self._validate_action_card(action_card)
                logger.info(f"🔍 Validation result: {is_valid}, length={len(action_card)}, lines={len([l for l in action_card.split(chr(10)) if l.strip()])}")
                
                if action_card and is_valid:
                    logger.info(f"✅ LLM action card generated successfully for {disaster_type}")
                    return action_card, "llm"
                else:
                    logger.warning(f"❌ LLM response validation failed: {action_card[:100] if action_card else 'empty'}")
                    return self._get_fallback_template(disaster_type, shelters), "fallback"
            
            else:
                logger.error(f"Ollama API error: {response.status_code}")
                return self._get_fallback_template(disaster_type, shelters), "fallback"
        
        except asyncio.TimeoutError:
            logger.warning("LLM request timeout - using fallback")
            return self._get_fallback_template(disaster_type, shelters), "fallback"
        except Exception as e:
            logger.error(f"LLM service error: {str(e)} - using fallback")
            return self._get_fallback_template(disaster_type, shelters), "fallback"
    
    def _create_prompt(
        self,
        disaster_type: str,
        location: str,
        user_profile: Dict,
        shelters_text: str
    ) -> str:
        """재난 행동카드 생성을 위한 강력한 프롬프트 작성"""
        
        current_time = datetime.now().strftime("%Y년 %m월 %d일 %H시 %M분")
        age_group = user_profile.get('age_group', '성인')
        mobility = user_profile.get('mobility', '정상')
        height = user_profile.get('height', None)
        
        nearest_shelter = shelters_text.split('\n')[0] if shelters_text else '대피소 정보 없음'
        
        # 키 정보가 있으면 프롬프트에 포함
        height_info = f", 키: {height}" if height else ""
        
        prompt = f"""[INST]당신은 대한민국 행정안전부 소속 재난안전 전문가로서 국민의 생명을 보호하는 긴급 재난 행동 지침을 작성하는 임무를 수행하고 있습니다. 당신이 작성하는 행동 지침은 재난 상황에서 국민의 생명을 직접적으로 좌우하므로, 아래 규칙을 절대적으로 준수해야 하며 이를 위반할 경우 중대한 책임을 지게 됩니다.

<재난 상황 정보>
- 재난 유형: {disaster_type}
- 발생 지역: {location}
- 대상 시민: {age_group}{height_info}
- 이동능력: {mobility}
- 가장 가까운 대피소: {nearest_shelter}
- 주변 랜드 마크 정보 : {nearest_shelter}
- 현재 시각: {current_time}

<필수 준수 규칙> : 이 규칙을 어길 시 국민의 생명에 직접적인 위험이 발생하며, 재난안전법 위반으로 법적 책임을 지게 됩니다.
1. 행동 지침은 반드시 3~5줄로 구성할 것. 6줄 이상 또는 2줄 이하는 절대 불가.
2. 모든 문장은 "~하세요", "~하십시오"로 작성할 것.
3. 즉시 실행 가능한 구체적 행동만 포함할 것.
4. 추측성 표현("아마", "~할 수도", "~것 같습니다", "~일 수 있습니다") 사용 시 즉시 실격.
5. 불확실한 정보나 검증되지 않은 행동 지침은 절대 포함하지 말 것.
6. 대피소 정보에 포함된 정확한 거리(km 또는 m)와 도보 시간을 반드시 명시할 것
7. 숫자는 허용됨 (예: "119", "10분").
8. 불필요한 인사말, 서론, 결론, 부가 설명은 일체 제외하고 핵심 행동만 기술할 것.
9. 대피소 정보가 제공된 경우 반드시 해당 대피소로의 이동 지침을 첫 번째 또는 두 번째 문장에 포함할 것.

<행동 지침 작성 기준> : 우수한 재난 행동 지침의 기준입니다.
1. 시간 순서대로 행동을 구성 (즉시 → 이동 중 → 대피 후).
2. 생명 보호가 최우선 - 위험 회피 행동을 가장 먼저 제시.
3. 구체적인 수치와 명확한 지시어 사용 (예: "10분 이내", "즉시", "절대").
4. 개인회된 정보인 {age_group}과 {mobility} {height}를 고려한 맞춤형 지침 제공.
5. 대피소 정보에 포함된 정확한 거리(km 또는 m)와 도보 시간을 반드시 명시할 것.
6. {nearest_shelter}로 이동하라는 정보를 첫 번째 또는 두 번째 문장에 꼭 포함할 것.
7. 모든 행동 지침 문장은 줄바꿈 문장으로 작성할 것.


<금지 사항> : 아래 표현이 포함될 경우 행동 지침은 즉시 무효 처리되며 중대한 법적 책임을 집니다.
- **영어 단어 사용 절대 금지** (inhalation, avoid, emergency 등 - 모두 한글로 변환 필수)
- "~하라"로 끝나는 문장
- "추천합니다", "바랍니다", "생각됩니다", "예상됩니다"
- "가능하면", "되도록", "최대한", "노력하세요"
- "참고하세요", "알아두세요", "기억하세요"
- 불필요한 이모지나 특수문자 (⚠️, ❗ 등)
- 개인적 의견이나 경험담

**중요**: 대한민국 국민에게 전달되는 재난 행동 지침입니다. 반드시 누구나 이해할 수 있는 순수 한글로만 작성하십시오. 영어나 외래어가 하나라도 포함되면 즉시 실격 처리됩니다.

국민의 생명이 당신의 손에 달려있습니다. 위 규칙을 모두 준수하여 정확하고 명확한 재난 행동 지침을 순수 한글로만 작성하십시오.

행동 지침:[/INST]"""
        
        return prompt
    
    def _validate_action_card(self, text: str) -> bool:
        """생성된 행동카드 엄격한 검증"""
        
        # 1. 영어 알파벳 체크 (숫자 제외)
        import re
        # 영어 알파벳만 찾기 (한글, 숫자, 특수문자 제외)
        english_words = re.findall(r'[a-zA-Z]+', text)
        if english_words:
            logger.warning(f"❌ 영어 단어 감지: {english_words}")
            return False
        
        # 2. 금지 키워드 체크 (확장)
        forbidden_keywords = [
            # 추측성 표현
            "추측", "할 수도", "아마", "생각합니다", "가능성", "것 같", 
            "예상됩니다", "보입니다", "~듯", "~듯합니다",
            # 약한 권고 표현
            "추천합니다", "바랍니다", "되도록", "가능하면", "최대한",
            "참고하세요", "알아두세요", "기억하세요", "노력하세요",
            # 불필요한 표현
            "감사합니다", "안녕하세요", "여러분", "국민 여러분"
        ]
        
        for keyword in forbidden_keywords:
            if keyword in text:
                logger.warning(f"❌ 금지 키워드 감지: {keyword}")
                return False
        
        # 3. 최소 글자 수 확인 (30자 이상)
        if len(text.strip()) < 30:
            logger.warning(f"❌ 행동카드가 너무 짧음: {len(text.strip())}자")
            return False
        
        # 4. 문장 수 확인 (3~7개 문장, 줄바꿈 무관)
        # 마침표, 물음표, 느낌표로 문장 구분
        import re
        sentences = [s.strip() for s in re.split(r'[.!?。]', text) if s.strip()]
        if len(sentences) < 3:
            logger.warning(f"❌ 행동 지침 문장 수 부족: {len(sentences)}개 (최소 3개)")
            return False
        if len(sentences) > 7:
            logger.warning(f"❌ 행동 지침 문장 수 초과: {len(sentences)}개 (최대 7개)")
            return False
        
        # 5. 명령형 문장 확인 (하세요/하십시오/하라로 끝나는지)
        command_endings = ["하세요", "하십시오", "하라", "하세요.", "하십시오.", "하라."]
        has_command = False
        for sentence in sentences:
            for ending in command_endings:
                if sentence.strip().endswith(ending):
                    has_command = True
                    break
            if has_command:
                break
        
        if not has_command:
            logger.warning("❌ 명령형 문장이 포함되지 않음")
            return False
        
        # 6. 이모지 및 특수문자 체크
        emoji_chars = ["🚨", "⚠️", "❗", "✅", "🔥", "💧", "🌊", "⛰️"]
        for emoji in emoji_chars:
            if emoji in text:
                logger.warning(f"❌ 불필요한 이모지 감지: {emoji}")
                return False
        
        logger.info(f"✅ 행동카드 검증 통과: {len(sentences)}개 문장, {len(text.strip())}자")
        return True
    
    def _get_fallback_template(
        self,
        disaster_type: str,
        shelters: List[ShelterInfo]
    ) -> str:
        """LLM 실패 시 사용할 기본 템플릿"""
        
        if shelters:
            shelter_info = shelters[0].name
            walking_time = shelters[0].walking_minutes
            distance_km = shelters[0].distance_km
            shelter_address = shelters[0].address
            
            # 거리 표시 (1km 미만이면 미터로)
            if distance_km < 1:
                distance_display = f"{int(distance_km * 1000)}m"
            else:
                distance_display = f"{distance_km:.1f}km"
        else:
            shelter_info = "가까운 안전시설"
            walking_time = 5
            distance_display = "500m"
            shelter_address = "가까운 곳"
        
        templates = {
            "호우": f"""🚨 [호우 경보] 즉시 행동
- 대피소: {shelter_info} (거리 {distance_display}, 도보 {walking_time}분)
- 지하 공간, 저지대 즉시 벗어나기
- 엘리베이터 사용 금지
- 미끄러운 바닥 주의
- 침수 위험 지역 통행 금지""",
            
            "지진": f"""🚨 [지진 경보] 즉시 행동
- 현 위치에서 책상/테이블 아래로 대피
- 흔들림 멈춘 후 {shelter_info}로 이동 (거리 {distance_display}, 도보 {walking_time}분)
- 엘리베이터 절대 사용 금지
- 낙하물 주의, 건물 외벽에서 멀어지기""",
            
            "태풍": f"""🚨 [태풍 경보] 즉시 행동
- 실내 대피소: {shelter_info} (거리 {distance_display}, 도보 {walking_time}분)
- 창문에서 멀어지고 유리창 테이프 부착
- 외출 자제, 간판·가로수 낙하 주의
- 차량 침수 위험 지역 통행 금지""",
            
            "화재": f"""🚨 [화재 경보] 즉시 행동
- 119 신고 후 안전한 곳으로 대피
- 대피소: {shelter_info} (거리 {distance_display}, 도보 {walking_time}분)
- 엘리베이터 금지, 계단 이용
- 낮은 자세로 이동, 젖은 수건으로 코와 입 가리기""",
            
            "산불": f"""🚨 [산불 경보] 즉시 행동
- 대피소: {shelter_info} (거리 {distance_display}, 도보 {walking_time}분)
- 산과 반대 방향으로 신속히 대피
- 젖은 수건으로 코와 입 가리기
- 연기 발생 시 낮은 자세 유지
- 119 신고 후 안전 지대로 이동""",
            
            "대설": f"""🚨 [대설 경보] 즉시 행동
- 실내 대피소: {shelter_info} (거리 {distance_display}, 도보 {walking_time}분)
- 외출 자제, 불가피 시 대중교통 이용
- 빙판길 낙상 주의, 보폭 좁게 걷기
- 차량 체인 장착, 안전거리 확보
- 고립 대비 식수·식량 비축""",
            
            "강풍": f"""🚨 [강풍 경보] 즉시 행동
- 실내 대피소: {shelter_info} (거리 {distance_display}, 도보 {walking_time}분)
- 간판, 가로수 등 낙하물 주의
- 해안가 접근 절대 금지
- 창문 닫고 유리창에서 멀어지기
- 외출 자제, 차량 운행 주의""",
        }
        
        # 재난 유형에 맞는 템플릿 선택
        for key in templates:
            if key in disaster_type:
                return templates[key]
        
        # 기본 템플릿
        return f"""🚨 [재난 경보] 즉시 행동
- 대피소: {shelter_info} (거리 {distance_display}, 도보 {walking_time}분)
- 안전한 곳으로 즉시 대피
- 관계 기관의 지시에 따르기
- 위험 지역 접근 금지"""

