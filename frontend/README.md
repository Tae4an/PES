# PES Frontend (Flutter)

Personal Emergency Siren - 재난 대피 행동 카드 앱

## 프로젝트 개요

사용자 위치 기반으로 재난 대피 행동 카드를 **30초 내** 제공하고, 즉시 대피 결정을 돕는 모바일 앱입니다.

### 주요 기능

- **실시간 재난 알림**: FCM 기반 푸시 알림
- **위치 기반 대피소 안내**: 가장 가까운 대피소 TOP 3 제공
- **지도 뷰**: Google Maps 기반 대피소 위치 표시
- **개인화 행동 카드**: LLM 기반 맞춤형 대피 지침
- **사용자 설정**: 연령대, 이동성 등 개인 정보 설정

## 기술 스택

- **Flutter**: 3.22+
- **State Management**: Riverpod 2.4+
- **API 통신**: Dio 5.3+, Retrofit 4.1+
- **지도**: google_maps_flutter 2.5+
- **위치**: geolocator 11.0+
- **푸시 알림**: Firebase FCM
- **로컬 저장소**: Hive 2.2+
- **디자인**: Material Design 3 (Material You)

## 📂 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점
├── config/
│   ├── theme.dart                     # Material 3 테마
│   ├── constants.dart                 # 상수 정의
│   └── router_config.dart             # GoRouter 라우팅
├── presentation/
│   ├── screens/                       # 모든 화면
│   ├── widgets/                       # 공통 위젯
│   └── providers/                     # Riverpod 프로바이더
├── domain/
│   ├── entities/                      # 도메인 엔티티
│   └── repositories/                  # 리포지토리 인터페이스
├── data/
│   ├── models/                        # 데이터 모델
│   ├── sources/                       # 데이터 소스
│   └── repositories/                  # 리포지토리 구현
└── core/
    ├── network/                       # API 클라이언트
    ├── location/                      # 위치 관리자
    ├── notifications/                 # 알림 핸들러
    └── utils/                         # 유틸리티
```

## 시작하기

### 사전 요구사항

- Flutter SDK 3.22 이상
- Dart SDK 3.2 이상
- Android Studio / Xcode
- Firebase 프로젝트 설정

### 설치

1. **의존성 설치**

```bash
cd frontend
flutter pub get
```

2. **코드 생성 (JSON Serialization, Retrofit 등)**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. **Firebase 설정**

- `google-services.json` (Android) → `android/app/`
- `GoogleService-Info.plist` (iOS) → `ios/Runner/`

### 실행

```bash
# 개발 모드
flutter run

# 특정 디바이스
flutter run -d <device_id>

# 프로덕션 빌드
flutter build apk --release    # Android
flutter build ios --release    # iOS
```

### Firebase 설정

1. Firebase Console에서 프로젝트 생성
2. Android/iOS 앱 추가
3. 구성 파일 다운로드 및 배치
4. FCM 활성화

## 화면 구성

1. **Splash Screen**: 앱 로딩
2. **Onboarding Screen**: 권한 요청
3. **Home Screen**: 현재 위치 + 활성 재난
4. **Action Card Screen**: 행동 카드 + 대피소 + 지도
5. **Map Screen**: 전체 지도 뷰
6. **Settings Screen**: 사용자 설정

## 테스트

```bash
# 유닛 테스트
flutter test

# 위젯 테스트
flutter test test/widget_test.dart

# 통합 테스트
flutter drive --target=test_driver/app.dart
```

## 빌드

### Android

```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

## 문제 해결

### 일반적인 문제

1. **코드 생성 파일 오류**

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

2. **Firebase 초기화 실패**

- `google-services.json` / `GoogleService-Info.plist` 확인
- Firebase Console에서 앱 등록 확인

3. **위치 권한 오류**

- `AndroidManifest.xml` 및 `Info.plist` 권한 설정 확인
