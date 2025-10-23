import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 환경 변수 설정
class EnvConfig {
  /// Google Maps API Key
  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  /// Backend API Base URL
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  /// 환경 변수가 제대로 로드되었는지 확인
  static bool get isConfigured {
    return googleMapsApiKey.isNotEmpty && apiBaseUrl.isNotEmpty;
  }
}

