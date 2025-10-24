# PES Frontend 설정 가이드

## 📋 사전 준비

### 1. Google Maps API 키 발급

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 새 프로젝트 생성 또는 기존 프로젝트 선택
3. "APIs & Services" → "Credentials" 이동
4. "Create Credentials" → "API Key" 선택
5. API 키 제한 설정 (선택 사항)
6. Maps SDK for Android/iOS 활성화

### 2. Firebase 프로젝트 설정

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. "Add project" 클릭
3. 프로젝트 이름 입력 (예: PES)
4. Google Analytics 설정 (선택 사항)

#### Android 앱 추가

1. Android 아이콘 클릭
2. 패키지 명: `com.pes.frontend`
3. `google-services.json` 다운로드
4. `android/app/` 디렉토리에 배치

#### iOS 앱 추가

1. iOS 아이콘 클릭
2. Bundle ID: `com.pes.frontend`
3. `GoogleService-Info.plist` 다운로드
4. `ios/Runner/` 디렉토리에 배치

### 3. Firebase Cloud Messaging (FCM) 설정

1. Firebase Console → "Cloud Messaging"
2. "Server key" 복사 (백엔드에서 사용)
3. iOS: APNs 인증 키 업로드 (Apple Developer 계정 필요)

## 🔧 설정 단계

### 1단계: API 키 설정

#### Android

`android/app/src/main/AndroidManifest.xml` 파일에서:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

`YOUR_GOOGLE_MAPS_API_KEY`를 실제 키로 교체하세요.

#### iOS

`ios/Runner/AppDelegate.swift` 파일 생성 및 수정:

```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 2단계: 백엔드 URL 설정

`lib/config/constants.dart` 파일에서:

```dart
static const String baseUrl = 'http://localhost:8000'; // 개발 환경
// static const String baseUrl = 'https://api.yourserver.com'; // 프로덕션
```

### 3단계: 의존성 설치

```bash
cd frontend
flutter pub get
```

### 4단계: 코드 생성

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

이 명령어는 다음 파일들을 생성합니다:
- `*.g.dart` (JSON serialization)
- `remote_data_source.g.dart` (Retrofit API)

## 🚀 실행

### 개발 모드

```bash
# Android
flutter run

# iOS (맥 필요)
flutter run
```

### 릴리즈 빌드

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Google Play)
flutter build appbundle --release

# iOS (맥 필요)
flutter build ios --release
```

## 🐛 일반적인 문제 해결

### 문제 1: 코드 생성 파일이 없음

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 문제 2: Firebase 초기화 실패

- `google-services.json` (Android) 파일 위치 확인
- `GoogleService-Info.plist` (iOS) 파일 위치 확인
- Firebase 프로젝트에서 앱이 올바르게 등록되었는지 확인

### 문제 3: Google Maps 표시 안 됨

- API 키가 올바르게 설정되었는지 확인
- Google Cloud Console에서 Maps SDK가 활성화되었는지 확인
- Android: SHA-1 키 등록 확인

### 문제 4: 위치 권한 오류

Android (`AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

iOS (`Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>현재 위치를 기반으로 대피소를 안내합니다.</string>
```

## 📱 테스트 시나리오

### 1. 위치 기반 기능 테스트

1. 앱 실행
2. 위치 권한 허용
3. 홈 화면에서 현재 위치 확인
4. 지도 화면에서 주변 대피소 확인

### 2. 재난 알림 테스트

1. 백엔드에서 재난 등록
2. 홈 화면에서 활성 재난 확인
3. "행동 카드 보기" 클릭
4. 행동 카드 및 대피소 정보 확인

### 3. FCM 푸시 알림 테스트

1. Firebase Console → Cloud Messaging
2. "Send your first message" 클릭
3. 테스트 메시지 작성 및 전송
4. 앱에서 알림 수신 확인

## 🔐 보안 고려사항

1. **API 키 보호**
   - 프로덕션 환경에서는 API 키 제한 설정
   - 환경 변수 사용 권장

2. **민감 정보 암호화**
   - `flutter_secure_storage` 사용
   - 로컬 저장소에 민감 정보 저장 금지

3. **네트워크 보안**
   - HTTPS 사용
   - Certificate Pinning 고려

## 📊 성능 최적화

1. **이미지 최적화**
   - `cached_network_image` 사용
   - 적절한 이미지 크기 사용

2. **상태 관리**
   - Riverpod의 `autoDispose` 활용
   - 불필요한 위젯 리빌드 방지

3. **지도 성능**
   - 마커 수 제한 (최대 20개)
   - 클러스터링 고려

## 📞 지원

문제가 발생하면 다음을 확인하세요:

1. Flutter Doctor: `flutter doctor -v`
2. 로그 확인: `flutter logs`
3. 빌드 오류: `flutter clean && flutter pub get`

추가 도움이 필요하면 GitHub Issues를 통해 문의하세요.

