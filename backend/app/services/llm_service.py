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
        
        # 대피소 정보 포맷팅
        if shelters:
            shelters_text = "\n".join([
                f"  {i+1}. {s.name} (도보 {s.walking_minutes}분, {s.address})"
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
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.ollama_endpoint}/api/generate",
                    json={
                        "model": self.model,
                        "prompt": prompt,
                        "stream": False,
                        "options": {
                            "temperature": self.temperature,
                            "top_p": 0.9,
                            "top_k": 40,
                            "num_predict": 200
                        }
                    }
                )
            
            if response.status_code == 200:
                result = response.json()
                action_card = result.get('response', '').strip()
                
                # 검증
                if self._validate_action_card(action_card):
                    logger.info(f"LLM action card generated successfully for {disaster_type}")
                    return action_card, "llm"
                else:
                    logger.warning(f"LLM response validation failed: {action_card}")
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
        """행동카드 생성 프롬프트 작성"""
        
        current_time = datetime.now().strftime("%Y년 %m월 %d일 %H시 %M분")
        age_group = user_profile.get('age_group', '성인')
        mobility = user_profile.get('mobility', '정상')
        
        prompt = f"""당신은 대한민국 정부의 재난안전 전문가입니다.
현재 재난 상황에서 시민이 즉시 실행할 수 있는 구체적이고 명확한 행동 지침을 작성하세요.

[재난 정보]
- 재난 유형: {disaster_type}
- 발생 지역: {location}
- 현재 시각: {current_time}

[사용자 정보]
- 연령대: {age_group}
- 이동성: {mobility}

[주변 대피소]
{shelters_text}

[작성 규칙]
1. 정확히 3~5줄 이내로 작성
2. 즉시 실행 가능한 구체적 행동만 포함
3. 금지 사항을 명확히 명시 (예: "엘리베이터 사용 금지")
4. 안전 주의사항 포함 (예: "미끄러운 바닥 주의")
5. 행정안전부 공식 지침만 참고
6. 불필요한 설명, 인사말, 추측 절대 금지
7. 반말 또는 명령형 어투 사용

행동 카드:"""
        
        return prompt
    
    def _validate_action_card(self, text: str) -> bool:
        """생성된 행동카드 검증"""
        
        # 금지 키워드 체크
        forbidden_keywords = ["추측", "할 수도", "아마", "생각합니다", "가능성", "것 같"]
        
        for keyword in forbidden_keywords:
            if keyword in text:
                logger.warning(f"Forbidden keyword detected: {keyword}")
                return False
        
        # 최소 글자 수 확인
        if len(text.strip()) < 30:
            logger.warning("Action card too short")
            return False
        
        # 최대 줄 수 확인 (5줄 초과 금지)
        lines = [l for l in text.split('\n') if l.strip()]
        if len(lines) > 7:  # 제목 포함해서 7줄까지 허용
            logger.warning(f"Action card too many lines: {len(lines)}")
            return False
        
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
            shelter_address = shelters[0].address
        else:
            shelter_info = "가까운 안전시설"
            walking_time = 5
            shelter_address = "가까운 곳"
        
        templates = {
            "호우": f"""🚨 [호우 경보] 즉시 행동
- 대피소: {shelter_info} (도보 {walking_time}분)
- 지하 공간, 저지대 즉시 벗어나기
- 엘리베이터 사용 금지
- 미끄러운 바닥 주의
- 침수 위험 지역 통행 금지""",
            
            "지진": f"""🚨 [지진 경보] 즉시 행동
- 현 위치에서 책상/테이블 아래로 대피
- 흔들림 멈춘 후 {shelter_info}로 이동 (도보 {walking_time}분)
- 엘리베이터 절대 사용 금지
- 낙하물 주의, 건물 외벽에서 멀어지기""",
            
            "태풍": f"""🚨 [태풍 경보] 즉시 행동
- 실내 대피소: {shelter_info} (도보 {walking_time}분)
- 창문에서 멀어지고 유리창 테이프 부착
- 외출 자제, 간판·가로수 낙하 주의
- 차량 침수 위험 지역 통행 금지""",
            
            "화재": f"""🚨 [화재 경보] 즉시 행동
- 119 신고 후 안전한 곳으로 대피
- 대피소: {shelter_info} (도보 {walking_time}분)
- 엘리베이터 금지, 계단 이용
- 낮은 자세로 이동, 젖은 수건으로 코와 입 가리기""",
        }
        
        # 재난 유형에 맞는 템플릿 선택
        for key in templates:
            if key in disaster_type:
                return templates[key]
        
        # 기본 템플릿
        return f"""🚨 [재난 경보] 즉시 행동
- 대피소: {shelter_info} (도보 {walking_time}분)
- 안전한 곳으로 즉시 대피
- 관계 기관의 지시에 따르기
- 위험 지역 접근 금지"""

