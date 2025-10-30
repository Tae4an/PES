import 'package:flutter/material.dart';
import 'env_config.dart';

/// PES 앱의 모든 상수 정의
class AppConstants {
  AppConstants._();

  // 앱 정보
  static const String appName = 'PES';
  static const String appFullName = 'Personal Emergency Siren';
  static const String appVersion = '1.0.0';

  // API 엔드포인트
  static String get baseUrl => EnvConfig.apiBaseUrl; // 환경변수에서 로드
  static const String apiVersion = 'v1';

  // 타임아웃
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // 위치 관련
  static const double defaultLatitude = 37.2970; // 한양대 ERICA
  static const double defaultLongitude = 126.8373; // 한양대 ERICA
  static const double defaultZoom = 15.0; // 마커가 잘 보이도록 조금 더 확대
  static const int maxSheltersToShow = 3;
  static const double shelterSearchRadiusKm = 5.0;

  // 애니메이션 지속시간
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 400);
  static const Duration extraLongAnimationDuration = Duration(milliseconds: 600);

  // UI 상수
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 20.0;
  static const double borderRadiusExtraLarge = 28.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingExtraLarge = 20.0;

  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;

  static const double minTouchTargetSize = 48.0;

  // 지도 높이
  static const double mapHeight = 300.0;

  // 긴급 연락처
  static const String emergencyNumber = '112';
  static const String fireNumber = '119';
}

/// 앱 색상 정의
class AppColors {
  AppColors._();

  // Seed Color (Material 3 기반)
  static const Color seedColor = Color(0xFF1F54A0);

  // 긴급도별 색상
  static const Color critical = Color(0xFFE74C3C); // 위험
  static const Color warning = Color(0xFFFB8C00); // 주의
  static const Color caution = Color(0xFFF39C12); // 조심
  static const Color safe = Color(0xFF27AE60); // 안전
  
  // UI 강조 색상 (빨강 계열 통일)
  static const Color danger = Color(0xFFDC3545); // 세련된 레드
  static const Color dangerLight = Color(0xFFFF6B7A); // 밝은 레드
  static const Color dangerDark = Color(0xFFC82333); // 진한 레드

  // 추가 색상
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF424242);
}

/// 텍스트 스타일 확장
class AppTextStyles {
  AppTextStyles._();

  // 행동카드용 강조 텍스트
  static TextStyle actionCardTitle(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontWeight: FontWeight.bold,
          height: 1.2,
        );
  }

  static TextStyle actionCardContent(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
          fontWeight: FontWeight.w500,
          height: 1.6,
        );
  }

  // 대피소 카드용 텍스트
  static TextStyle shelterName(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.bold,
        );
  }

  static TextStyle shelterInfo(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: AppColors.grey,
        );
  }

  // 버튼용 텍스트
  static TextStyle buttonText(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!.copyWith(
          fontWeight: FontWeight.bold,
        );
  }

  // 에러 메시지
  static TextStyle errorText(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Theme.of(context).colorScheme.error,
        );
  }
}

/// 재난 유형별 아이콘 및 색상
class DisasterTypeConfig {
  final IconData icon;
  final Color color;
  final String displayName;

  const DisasterTypeConfig({
    required this.icon,
    required this.color,
    required this.displayName,
  });

  static const Map<String, DisasterTypeConfig> configs = {
    'flood': DisasterTypeConfig(
      icon: Icons.water,
      color: Color(0xFF2196F3),
      displayName: '홍수',
    ),
    'heavy_rain': DisasterTypeConfig(
      icon: Icons.water_drop,
      color: Color(0xFF03A9F4),
      displayName: '호우',
    ),
    'typhoon': DisasterTypeConfig(
      icon: Icons.cyclone,
      color: Color(0xFF9C27B0),
      displayName: '태풍',
    ),
    'earthquake': DisasterTypeConfig(
      icon: Icons.landscape,
      color: Color(0xFF795548),
      displayName: '지진',
    ),
    'fire': DisasterTypeConfig(
      icon: Icons.local_fire_department,
      color: Color(0xFFE74C3C),
      displayName: '화재',
    ),
    'heavy_snow': DisasterTypeConfig(
      icon: Icons.ac_unit,
      color: Color(0xFF00BCD4),
      displayName: '대설',
    ),
    'landslide': DisasterTypeConfig(
      icon: Icons.terrain,
      color: Color(0xFF8D6E63),
      displayName: '산사태',
    ),
    'thunderstorm': DisasterTypeConfig(
      icon: Icons.thunderstorm,
      color: Color(0xFFFF9800),
      displayName: '뇌우',
    ),
  };

  static DisasterTypeConfig getConfig(String type) {
    return configs[type.toLowerCase()] ??
        const DisasterTypeConfig(
          icon: Icons.warning,
          color: AppColors.warning,
          displayName: '재난',
        );
  }
}

