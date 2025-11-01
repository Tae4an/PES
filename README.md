# PES (Personal Emergency Siren)

재난 상황에서 사용자 위치 기반으로 **30초 내** 맞춤형 대피 행동 카드를 제공하고, 평상시 대피소 찾기 훈련을 통해 재난 대응 능력을 향상시키는 모바일 애플리케이션입니다.
<img width="1069" height="606" alt="스크린샷 2025-11-01 오후 6 31 19" src="https://github.com/user-attachments/assets/8fdf12d2-3571-4661-be08-43aedf76a585" />

## 프로젝트 개요

PES는 실시간 재난 정보를 수집하고, 사용자의 위치와 개인 정보(연령대, 이동성 등)를 고려하여 AI 기반의 개인화된 대피 지침을 제공합니다. 또한 **게이미피케이션 훈련 시스템**을 통해 평상시 대피소 위치를 숙지하고, 포인트를 모아 실제 쿠폰으로 교환할 수 있습니다.

## 시스템 아키텍처
<img width="1087" height="504" alt="image" src="https://github.com/user-attachments/assets/317ee00d-2eb5-4247-8280-ade802c210c5" />
<p align="center">
  <img src="https://img.shields.io/badge/FastAPI-0.115.0-009688?logo=fastapi&logoColor=white" alt="FastAPI" />
  <img src="https://img.shields.io/badge/PostgreSQL-15+-336791?logo=postgresql&logoColor=white" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/PostGIS-Supported-0081C9?logo=postgresql&logoColor=white" alt="PostGIS" />
  <img src="https://img.shields.io/badge/SQLite-3+-003B57?logo=sqlite&logoColor=white" alt="SQLite" />
  <img src="https://img.shields.io/badge/Ollama-LLM%20Qwen3:8b-2F8AE2?logo=ollama&logoColor=white" alt="Ollama" />
  <img src="https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Riverpod-2.4+-5C7CFA?logo=riverpod&logoColor=white" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Dio-5.4+-009688" alt="Dio" />
  <img src="https://img.shields.io/badge/Retrofit-4.1+-009688" alt="Retrofit" />
  <img src="https://img.shields.io/badge/Google%20Maps%20API-Used-4285F4?logo=googlemaps&logoColor=white" alt="Google Maps API" />
  <img src="https://img.shields.io/badge/Firebase%20SDK-Admin%20%26%20Messaging-FFCA28?logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/APScheduler-%7CCelery-FF3A4E" alt="APScheduler/Celery" />
  <img src="https://img.shields.io/badge/Material%20Design-3-757575?logo=materialdesign&logoColor=white" alt="Material Design" />
  <img src="https://img.shields.io/badge/Lottie-Animation-FD8A31?logo=lottie&logoColor=white" alt="Lottie" />
  <img src="https://img.shields.io/badge/Hive-2.2+-FFDD00?logo=hive&logoColor=black" alt="Hive" />
</p>


## 주요 기능
<img width="2044" height="1166" alt="image" src="https://github.com/user-attachments/assets/85a075e3-855a-4668-9c8a-a7a2ae43c243" />
<img width="2044" height="1166" alt="image" src="https://github.com/user-attachments/assets/9357d7ae-17a6-4207-afdb-0f8a187c8cca" />

#### 재난 대응
- **실시간 재난 모니터링**: 행정안전부 재난 문자 API 연동
- **위치 기반 대피소 안내**: 사용자 위치에서 가장 가까운 대피소 TOP 3 제공
- **AI 기반 행동 카드**: LLM(Qwen3)을 활용한 개인 맞춤형 대피 지침 생성
- **푸시 알림**: Firebase FCM을 통한 실시간 재난 알림
- **지도 시각화**: Google Maps 기반 대피소 및 재난 위치 표시

#### 훈련 & 리워드 시스템
- **대피소 찾기 훈련**: 주변 대피소 선택 후 실제로 찾아가는 훈련
- **포인트 적립**: 훈련 완료 시 100 포인트 지급
- **포인트 교환**: 적립된 포인트로 제휴 업체 쿠폰 교환
  - 올리브영, 스타벅스, GS25, CU, 배달의민족 등
- **훈련 기록**: 완료한 훈련 내역 조회

## 주요 화면 구성
| 로그인 화면 | 메인 화면 | 대피소 안내 화면 | 설정 화면 |
|:---:|:---:|:---:|:---:|
| <img width="245" alt="image" src="https://github.com/user-attachments/assets/b42e53de-de3c-4e37-b933-cb4d10bf936c" /> | <img width="245" alt="image" src="https://github.com/user-attachments/assets/5b199057-1b5a-43c5-9e29-711ac61526b3" /> | <img width="245" alt="image" src="https://github.com/user-attachments/assets/6e432dbc-0f9e-4f8f-b4cb-2bba4e38786b" /> | <img width="245" alt="image" src="https://github.com/user-attachments/assets/c4e212bd-8d9b-43bf-a886-2960a65afcb4" /> |

| 대피소 훈련 화면 | 대피소 훈련 진행 화면 | 대피소 훈련 완료 화면 | 포인트 교환 화면 |
|:---:|:---:|:---:|:---:|
| <img width="245" alt="image" src="https://github.com/user-attachments/assets/4b88621f-06e4-4676-9d0d-2ca062b2025a" /> | <img width="245" alt="image" src="https://github.com/user-attachments/assets/afba46a6-72e3-4672-9519-4aeffdf2de3b" /> | <img width="245" alt="image" src="https://github.com/user-attachments/assets/9fc6d237-bce4-46c0-be38-d89dc0a53c62" /> | <img width="245" alt="image" src="https://github.com/user-attachments/assets/d279dd66-7562-4ed5-96f3-9deefbf58300" /> |

