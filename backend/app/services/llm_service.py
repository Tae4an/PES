"""
Qwen3 8B 로컬 LLM 서비스 (행동카드 생성)
"""
import httpx
import asyncio
import json
from pathlib import Path
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
        self.landmarks_data = self._load_landmarks()
    
    def _load_landmarks(self) -> List[Dict]:
        """랜드마크 정보 JSON 파일 로드"""
        try:
            landmarks_file = Path(__file__).parent.parent / "metadata" / "landmarks_jeju.json"
            with open(landmarks_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return data.get('landmarks', [])
        except Exception as e:
            logger.warning(f"랜드마크 파일 로드 실패: {e}")
            return []
    
    async def generate_action_card(
        self,
        disaster_type: str,
        location: str,
        user_profile: Dict,
        shelters: List[ShelterInfo],
        max_retries: int = 3
    ) -> tuple[str, str]:
        """
        Qwen3 8B로 개인화 행동카드 생성 (검증 실패 시 재시도)
        
        Args:
            disaster_type: 재난 유형
            location: 재난 발생 지역
            user_profile: 사용자 프로필 (age_group, mobility 등)
            shelters: 주변 대피소 목록
            max_retries: 최대 재시도 횟수 (기본값: 3)
        
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
        
        # 재시도 로직
        for attempt in range(max_retries):
            try:
                logger.info(f"🔄 LLM 요청 시도 {attempt + 1}/{max_retries}")
                
                # Ollama API 호출
                logger.info(f"🔍 Ollama Request: model={self.model}, prompt_length={len(prompt)}, endpoint={self.ollama_endpoint}")
                logger.debug(f"🔍 Full prompt:\n{prompt[:200]}...")
                
                async with httpx.AsyncClient(timeout=self.timeout) as client:
                    response = await client.post(
                        f"{self.ollama_endpoint}/api/generate",
                        json={
                            "model": self.model,
                            "prompt": prompt,
                            "stream": False,
                            "options": {
                                "temperature": 0.7 + (attempt * 0.1)  # 재시도마다 temperature 증가
                            }
                        }
                    )
                
                if response.status_code == 200:
                    result = response.json()
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
                        logger.info(f"✅ LLM action card generated successfully for {disaster_type} (attempt {attempt + 1})")
                        return action_card, "llm"
                    else:
                        logger.warning(f"❌ LLM response validation failed (attempt {attempt + 1}): {action_card[:100] if action_card else 'empty'}")
                        if attempt < max_retries - 1:
                            logger.info(f"🔄 재시도합니다...")
                            continue
                        else:
                            error_msg = f"⚠️ LLM 검증 실패: {max_retries}번 시도 후에도 올바른 행동카드를 생성하지 못했습니다."
                            logger.error(error_msg)
                            raise ValueError(error_msg)
                
                else:
                    logger.error(f"Ollama API error: {response.status_code} (attempt {attempt + 1})")
                    if attempt < max_retries - 1:
                        continue
                    else:
                        error_msg = f"⚠️ Ollama API 오류: {max_retries}번 시도 후에도 API 호출 실패 (status: {response.status_code})"
                        logger.error(error_msg)
                        raise RuntimeError(error_msg)
            
            except asyncio.TimeoutError:
                logger.warning(f"LLM request timeout (attempt {attempt + 1})")
                if attempt < max_retries - 1:
                    continue
                else:
                    error_msg = f"⚠️ LLM 타임아웃: {max_retries}번 시도 모두 타임아웃"
                    logger.error(error_msg)
                    raise asyncio.TimeoutError(error_msg)
            except ValueError:
                # 검증 실패 예외는 그대로 전파
                raise
            except Exception as e:
                logger.error(f"LLM service error (attempt {attempt + 1}): {str(e)}")
                if attempt < max_retries - 1:
                    continue
                else:
                    error_msg = f"⚠️ LLM 서비스 오류: {max_retries}번 시도 후 실패 - {str(e)}"
                    logger.error(error_msg)
                    raise RuntimeError(error_msg)
        
        # 여기까지 도달하면 모든 재시도 실패 (일반적으로 도달하지 않음)
        error_msg = "⚠️ 알 수 없는 오류: 모든 재시도 실패"
        logger.error(error_msg)
        raise RuntimeError(error_msg)
    
    def _get_disaster_specific_rules(self, disaster_type: str) -> str:
        """재난 유형별 특화 규칙 반환"""
        
        disaster_rules = {
            "지진": """
<지진 특화 행동 지침 규칙>
1. 첫 번째 문장: 즉시 책상/테이블 아래로 몸을 숨기라는 지시 (Drop, Cover, Hold on)
2. 두 번째 문장: 흔들림이 멈춘 후 지진대피소로 이동하라는 지시 (내진 설계 건물 강조)
3. 엘리베이터 절대 사용 금지 명시
4. 낙하물 주의 및 건물 외벽에서 멀어지기 강조
5. 여진 가능성 경고 포함""",
            
            "해일": """
<해일 특화 행동 지침 규칙>
1. 첫 번째 문장: 즉시 고지대/해일대피소로 수직 대피 지시 (1분 1초가 생명)
2. 해안가에서 최대한 멀어지기 강조
3. 차량보다 도보 대피가 더 빠를 수 있음 안내
4. 1차 해일 후 2차, 3차 해일 올 수 있음 경고
5. 해발 높은 곳에 위치한 대피소 특성 강조""",
            
            "산불": """
<산불 특화 행동 지침 규칙>
1. 첫 번째 문장: 산과 반대 방향으로 즉시 대피 지시
2. 산불대피소(개활지, 비산림 지역)로 신속히 이동
3. 바람 방향을 고려한 대피 경로 선택 강조
4. 젖은 수건/마스크로 호흡기 보호 필수
5. 연기 발생 시 낮은 자세 유지 및 시야 확보""",
            
            "전쟁": """
<전쟁 특화 행동 지침 규칙>
1. 첫 번째 문장: 즉시 지하 대피소/전쟁대피소로 이동 지시
2. 창문과 외벽에서 멀어지기 강조
3. 방호 시설(지하, 콘크리트 건물)의 중요성 명시
4. 정부 및 관계 기관의 지시 대기
5. 비상식량과 식수 확보 안내"""
        }
        
        return disaster_rules.get(disaster_type, "")
    
    def _create_prompt(
        self,
        disaster_type: str,
        location: str,
        user_profile: Dict,
        shelters_text: str
    ) -> str:
        """재난 행동카드 생성을 위한 강력한 프롬프트 작성 (재난 유형별 특화)"""
        
        current_time = datetime.now().strftime("%Y년 %m월 %d일 %H시 %M분")
        age_group = user_profile.get('age_group', '성인')
        mobility = user_profile.get('mobility', '정상')
        height = user_profile.get('height', None)
        
        nearest_shelter = shelters_text.split('\n')[0] if shelters_text else '대피소 정보 없음'
        
        # 주변 랜드마크 정보 (JSON 파일에서 로드)
        landmarks_text = "\n".join([
            f"  {i+1}. {lm['name']} (위도: {lm['latitude']:.6f}, 경도: {lm['longitude']:.6f})"
            for i, lm in enumerate(self.landmarks_data)
        ]) if self.landmarks_data else "  정보 없음"
        
        # 재난 유형별 특화 규칙
        disaster_specific_rules = self._get_disaster_specific_rules(disaster_type)
        
        # 키 정보가 있으면 프롬프트에 포함
        height_info = f", 키: {height}" if height else ""
        
        prompt = f"""[INST]당신은 대한민국 행정안전부 소속 재난안전 전문가로서 국민의 생명을 보호하는 긴급 재난 행동 지침을 작성하는 임무를 수행하고 있습니다. 
        
⚠️ 경고: 번호 매기기(1. 2. 3.)를 사용하면 즉시 실격됩니다. 문장은 번호 없이 바로 시작하십시오.
⚠️ 경고: 3~5개 문장만 작성하십시오. 6개 이상 작성 시 즉시 실격됩니다.

<재난 상황 정보>
- 재난 유형: {disaster_type}
- 발생 지역: {location}
- 대상 시민: {age_group}{height_info}
- 이동능력: {mobility}
- 가장 가까운 대피소: {nearest_shelter}
- 주변 랜드마크 정보:{landmarks_text}
- 현재 시각: {current_time}

<필수 준수 규칙> : 이 규칙을 어길 시 국민의 생명에 직접적인 위험이 발생하며, 재난안전법 위반으로 법적 책임을 지게 됩니다.
1. **[절대 엄수]** 행동 지침은 정확히 3개, 4개, 또는 5개 문장만 작성. 6개 이상 작성 시 즉시 실격. 각 문장은 마침표(.)로 끝나야 함.
2. **[절대 금지]** 번호 매기기(1. 2. 3.) 사용 금지. 문장은 번호 없이 바로 시작할 것.
3. 모든 문장은 "~하세요", "~하십시오"로 작성할 것.
4. 즉시 실행 가능한 구체적 행동만 포함할 것.
5. 추측성 표현("아마", "~할 수도", "~것 같습니다", "~일 수 있습니다") 사용 시 즉시 실격.
6. 불확실한 정보나 검증되지 않은 행동 지침은 절대 포함하지 말 것.
7. 대피소 정보에 포함된 정확한 거리(km 또는 m)와 도보 시간을 반드시 명시할 것
8. 숫자는 허용됨 (예: "119", "10분").
9. 불필요한 인사말, 서론, 결론, 부가 설명은 일체 제외하고 핵심 행동만 기술할 것.
10. 대피소 정보가 제공된 경우 반드시 해당 대피소로의 이동 지침을 첫 번째 또는 두 번째 문장에 포함할 것.
11. 방향 안내 시 "북쪽", "남쪽", "동쪽", "서쪽" 같은 추상적 표현 대신 주변 랜드마크를 활용할 것 (예: "안산 스타디움 방향으로", "롯데마트 상록점 쪽으로").

<행동 지침 작성 기준> : 우수한 재난 행동 지침의 기준입니다.
1. 시간 순서대로 행동을 구성 (즉시 → 이동 중 → 대피 후).
2. 생명 보호가 최우선 - 위험 회피 행동을 가장 먼저 제시.
3. 구체적인 수치와 명확한 지시어 사용 (예: "10분 이내", "즉시", "절대").
4. 개인화된 정보인 {age_group}과 {mobility} {height}를 고려한 맞춤형 지침 제공.
5. 대피소 정보에 포함된 정확한 거리(km 또는 m)와 도보 시간을 반드시 명시할 것.
6. {nearest_shelter}로 이동하라는 정보를 첫 번째 또는 두 번째 문장에 꼭 포함할 것.
7. 모든 행동 지침 문장은 줄바꿈 문장으로 작성할 것.
8. {landmarks_text} 정보를 활용하여 구체적인 이동 경로를 안내할 것.

{disaster_specific_rules}


<금지 사항> : 아래 표현이 포함될 경우 행동 지침은 즉시 무효 처리되며 중대한 법적 책임을 집니다.
- **번호 매기기 절대 금지** (1. 2. 3. 또는 ①②③ 형식 등 모든 번호 표시)
- "~하라"로 끝나는 문장
- "추천합니다", "바랍니다", "생각됩니다", "예상됩니다"
-  "노력하세요"
- "참고하세요", "알아두세요", "기억하세요"
- 불필요한 이모지나 특수문자 (⚠️, ❗ 등)
- 개인적 의견이나 경험담

**중요**: 대한민국 국민에게 전달되는 재난 행동 지침입니다. 반드시 누구나 이해할 수 있는 순수 한글로만 작성하십시오. 
**예외**: 측정 단위(km, m, cm 등)와 숫자(119 등)는 허용됩니다. 그 외 영어나 외래어는 즉시 실격 처리됩니다.

<올바른 행동 지침 예시 - 번호 없이 4개 문장>
즉시 건물 내부로 대피하십시오.
창문과 출입문을 모두 닫고 외부 공기 유입을 차단하십시오.
{nearest_shelter}로 이동하여 안전을 확보하십시오.
대피 완료 후 119에 신고하여 추가 지시를 받으십시오.

❌ 잘못된 예시 (번호 사용 금지):
1. 즉시 대피하십시오.
2. 119에 신고하십시오.

국민의 생명이 당신의 손에 달려있습니다. 반드시 번호 없이 3~5개 문장만 작성하십시오.

행동 지침:[/INST]"""
        
        return prompt
    
    def _validate_action_card(self, text: str) -> bool:
        """생성된 행동카드 엄격한 검증"""
        
        # 1. 영어 알파벳 체크 (측정 단위 제외)
        import re
        # 영어 알파벳만 찾기 (한글, 숫자, 특수문자 제외)
        english_words = re.findall(r'[a-zA-Z]+', text)
        # 허용된 측정 단위 제외
        allowed_units = ['km', 'KM', 'm', 'M', 'cm', 'CM', 'mm', 'MM', 'kg', 'KG', 'g', 'G']
        filtered_english = [word for word in english_words if word not in allowed_units]
        if filtered_english:
            logger.warning(f"❌ 영어 단어 감지: {filtered_english}")
            return False
        
        # 2. 번호 매기기 체크 (절대 금지)
        # 문장 시작 부분에 "1.", "2.", "①", "②" 등의 번호가 있는지 확인
        numbered_pattern = re.compile(r'^\s*[\d①②③④⑤⑥⑦⑧⑨⑩]+[\.\)]\s*', re.MULTILINE)
        if numbered_pattern.search(text):
            logger.warning(f"❌ 번호 매기기 감지 (금지됨)")
            return False
        
        # 3. 금지 키워드 체크 (확장)
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
        
        # 4. 최소 글자 수 확인 (30자 이상)
        if len(text.strip()) < 30:
            logger.warning(f"❌ 행동카드가 너무 짧음: {len(text.strip())}자")
            return False
        
        # 5. 문장 수 확인 (3~5개 문장, 줄바꿈 무관)
        # 마침표, 물음표, 느낌표로 문장 구분
        import re
        sentences = [s.strip() for s in re.split(r'[.!?。]', text) if s.strip()]
        if len(sentences) < 3:
            logger.warning(f"❌ 행동 지침 문장 수 부족: {len(sentences)}개 (최소 3개 필요)")
            return False
        if len(sentences) > 5:
            logger.warning(f"❌ 행동 지침 문장 수 초과: {len(sentences)}개 (최대 5개)")
            return False
        
        # 6. 명령형 문장 확인 (하세요/하십시오/하라로 끝나는지)
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
        
        # 7. 이모지 및 특수문자 체크
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
        """LLM 실패 시 사용할 기본 템플릿 (재난별 특화, shelter_type 반영)"""
        
        if shelters:
            shelter_info = shelters[0].name
            walking_time = shelters[0].walking_minutes
            distance_km = shelters[0].distance_km
            shelter_address = shelters[0].address
            shelter_type = shelters[0].shelter_type
            
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
            shelter_type = "대피소"
        
        templates = {
            "지진": f"즉시 책상이나 테이블 아래로 몸을 숨기십시오.\n흔들림이 멈추면 {shelter_info} 지진대피소로 이동하십시오. 거리는 {distance_display}, 도보 {walking_time}분입니다.\n엘리베이터 사용을 절대 금지하고 계단을 이용하십시오.\n여진에 대비하여 건물 외벽과 낙하물을 조심하십시오.",
            
            "해일": f"즉시 고지대나 {shelter_info} 해일대피소로 수직 대피하십시오. 거리는 {distance_display}, 도보 {walking_time}분입니다.\n해안가에서 최대한 멀어지고 차량보다 도보가 더 빠를 수 있습니다.\n1차 해일 후에도 2차, 3차 해일이 올 수 있으니 계속 대피하십시오.\n관계 기관의 안전 확인이 있을 때까지 해안가로 돌아가지 마십시오.",
            
            "산불": f"즉시 산과 반대 방향으로 {shelter_info} 산불대피소로 대피하십시오. 거리는 {distance_display}, 도보 {walking_time}분입니다.\n바람 방향을 고려하여 연기를 피해 이동하십시오.\n젖은 수건이나 마스크로 코와 입을 막고 낮은 자세를 유지하십시오.\n119에 신고하고 개활지나 비산림 지역으로 이동하십시오.",
            
            "전쟁": f"즉시 지하 또는 {shelter_info} 전쟁대피소로 이동하십시오. 거리는 {distance_display}, 도보 {walking_time}분입니다.\n창문과 외벽에서 멀어지고 콘크리트 건물 내부로 대피하십시오.\n정부 및 관계 기관의 지시를 기다리고 비상식량과 식수를 확보하십시오.\n대피 완료 후 가족 및 지인에게 안전 상황을 알리십시오.",
            
            # 기타 재난 유형 (호환성 유지)
            "호우": f"즉시 고지대나 안전한 건물로 대피하십시오.\n{shelter_info}로 이동하십시오. 거리는 {distance_display}, 도보 {walking_time}분입니다.\n지하 공간과 저지대를 즉시 벗어나고 엘리베이터 사용을 금지하십시오.\n침수 위험 지역 통행을 금지하고 미끄러운 바닥을 조심하십시오.",
            
            "태풍": f"즉시 견고한 건물 내부로 대피하십시오.\n{shelter_info}로 이동하십시오. 거리는 {distance_display}, 도보 {walking_time}분입니다.\n창문에서 멀어지고 외출을 자제하십시오.\n간판과 가로수 낙하를 주의하고 차량 침수 위험 지역 통행을 금지하십시오.",
            
            "화재": f"즉시 119에 신고하고 안전한 곳으로 대피하십시오.\n{shelter_info}로 이동하십시오. 거리는 {distance_display}, 도보 {walking_time}분입니다.\n엘리베이터를 금지하고 계단을 이용하십시오.\n낮은 자세로 이동하고 젖은 수건으로 코와 입을 가리십시오."
        }
        
        # 재난 유형에 맞는 템플릿 반환 (기본은 지진)
        return templates.get(disaster_type, templates["지진"])

