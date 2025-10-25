# PES (Personal Emergency Siren)

재난 상황에서 사용자 위치 기반으로 30초 내에 맞춤형 대피 행동 카드를 제공하는 모바일 애플리케이션입니다.

## 프로젝트 개요

PES는 실시간 재난 정보를 수집하고, 사용자의 위치와 개인 정보(연령대, 이동성 등)를 고려하여 AI 기반의 개인화된 대피 지침을 제공합니다. 재난 발생 시 신속한 대피 결정을 돕는 것이 주요 목표입니다.

### 핵심 기능

- **실시간 재난 모니터링**: 행정안전부 재난 문자 API 연동
- **위치 기반 대피소 안내**: 사용자 위치에서 가장 가까운 대피소 TOP 3 제공
- **AI 기반 행동 카드**: LLM을 활용한 개인 맞춤형 대피 지침 생성
- **푸시 알림**: Firebase FCM을 통한 실시간 재난 알림
- **지도 시각화**: Google Maps 기반 대피소 및 재난 위치 표시

## 시스템 아키텍처

### 백엔드 (FastAPI)
- **프레임워크**: FastAPI 0.109+
- **데이터베이스**: PostgreSQL + PostGIS (공간 데이터)
- **캐시**: Redis
- **AI/LLM**: OpenAI API
- **외부 API**: 행정안전부 재난문자 API, Google Maps API
- **알림**: Firebase Admin SDK

### 프론트엔드 (Flutter)
- **프레임워크**: Flutter 3.22+
- **상태 관리**: Riverpod 2.4+
- **API 통신**: Dio + Retrofit
- **지도**: Google Maps Flutter
- **로컬 저장소**: Hive + Flutter Secure Storage
- **디자인**: Material Design 3

