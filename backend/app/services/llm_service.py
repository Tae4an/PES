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
            landmarks_file = Path(__file__).parent.parent / "data" / "landmarks_jeju.json"
            with open(landmarks_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return data.get('landmarks', [])
        except Exception as e:
            logger.warning(f"랜드마크 파일 로드 실패: {e}")
            return []
    
    def _load_user_health_data(self, user_id: str) -> Dict:
        """사용자 건강 정보 JSON 파일 로드"""
        try:
            health_file = Path(__file__).parent.parent / "data" / "user_health_data.json"
            with open(health_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                users = data.get('users', [])
                for user in users:
                    if user.get('user_id') == user_id:
                        return user
                return {}
        except Exception as e:
            logger.warning(f"건강 데이터 파일 로드 실패: {e}")
            return {}
    
    def _get_health_specific_advice(self, condition: str, medications: List[str], disaster_type: str) -> str:
        """질환별 재난 상황 맞춤형 필수 물품 권고사항 생성"""
        
        # 질환별 필수 물품 (일반적인 용어 사용, 구체적인 약명 제외)
        health_items_map = {
            "고혈압": "혈압약, 혈압계",
            "당뇨병": "당뇨약, 혈당측정기",
            "천식": "천식약(흡입기)",
            "간질": "간질약",
            "심장병": "심장약",
            "파킨슨병": "파킨슨병약, 보행보조기"
        }
        
        items = health_items_map.get(condition)
        if items:
            return f"{items} 챙기"
        
        # 기본 권고사항 (질환이 매핑에 없는 경우)
        if medications:
            # medications는 리스트 형태
            if isinstance(medications, list) and len(medications) > 0:
                # 구체적인 약명 대신 "복용 중인 약"으로 표현
                return "복용 중인 약 챙기"
        
        return ""
    
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
                    
                    # 번호 매기기 제거 (예: "1. ", "2. " 제거 - 각 줄마다)
                    import re
                    lines = action_card.split('\n')
                    cleaned_lines = []
                    for line in lines:
                        # 각 줄의 시작 부분에서 번호 제거
                        cleaned_line = re.sub(r'^\s*[\d①②③④⑤⑥⑦⑧⑨⑩]+[\.\)]\s*', '', line)
                        if cleaned_line.strip():
                            cleaned_lines.append(cleaned_line)
                    action_card = '\n'.join(cleaned_lines)
                    
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
        

        
        
        # 랜드마크 이름만 추출 (첫 번째 랜드마크 사용)
        landmark_name = self.landmarks_data[0]['name'] if self.landmarks_data else "주요 랜드마크"
        
        # 대피소 이름과 거리 추출
        shelter_parts = nearest_shelter.split(' - ')
        shelter_name = shelter_parts[0].strip() if shelter_parts else "대피소"
        
        # 거리 추출 (예: "거리: 3.5km" 형식에서)
        distance = "0km"
        if len(shelter_parts) > 1:
            distance_part = shelter_parts[1]
            if '거리:' in distance_part:
                distance = distance_part.split('거리:')[1].split(',')[0].strip()
        
        # 사용자 건강 정보 로드 (user_profile에 user_id가 있는 경우)
        user_id = user_profile.get('user_id', None)
        health_precaution = ""
        has_health_info = False
        
        if user_id:
            health_data = self._load_user_health_data(user_id)
            if health_data and health_data.get('health_conditions'):
                # 가장 심각한 건강 상태의 약물/장비 정보 추출
                conditions = health_data.get('health_conditions', [])
                if conditions:
                    primary_condition = conditions[0]  # 첫 번째 질환
                    condition_name = primary_condition.get('condition', '')
                    medications = primary_condition.get('medication', [])
                    
                    # 재난 상황별 필수 약물/장비 권고사항 생성
                    if medications:
                        # 질환별 맞춤형 장비/약물 권고
                        disaster_specific_advice = self._get_health_specific_advice(
                            condition_name, medications, disaster_type
                        )
                        if disaster_specific_advice:
                            health_precaution = disaster_specific_advice
                            has_health_info = True
        
        # 건강 정보 유무에 따라 프롬프트 다르게 생성
        if has_health_info:
            prompt = f"""[INST]다음 내용을 번호나 레이블 없이 2개 문장으로만 작성하세요:

첫 번째: {shelter_name}({landmark_name} 방향)로 {distance} 이동하십시오.
두 번째: {health_precaution}십시오.

[출력 예시]
{shelter_name}({landmark_name} 방향)로 {distance} 이동하십시오.
{health_precaution}십시오.

위 형식 그대로 출력하세요:[/INST]"""
        else:
            prompt = f"""[INST]다음 문장만 그대로 출력하세요:

{shelter_name}({landmark_name} 방향)로 {distance} 이동하십시오.

다른 내용 추가 금지:[/INST]"""
        
        return prompt
    
    def _validate_action_card(self, text: str) -> bool:
        """생성된 행동카드 간단한 검증"""
        import re
        
        # 1. 문장 수 확인 (1개 또는 2개 문장)
        # 소수점은 문장 구분자에서 제외 (예: 32.76km은 하나의 단어)
        # 문장 끝의 마침표, 물음표, 느낌표만 문장 구분자로 인식
        sentences = [s.strip() for s in re.split(r'(?<!\d)[.!?。](?!\d)', text) if s.strip()]
        if len(sentences) < 1 or len(sentences) > 2:
            logger.warning(f"❌ 행동 지침 문장 수: {len(sentences)}개 (1~2개 필요)")
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

