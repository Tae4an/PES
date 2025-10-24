import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// Google Maps 네이티브 초기화
class GoogleMapsInitializer {
  static const MethodChannel _channel = MethodChannel('com.pes.frontend/google_maps');

  /// iOS/Android에 Google Maps API 키 전달
  static Future<void> initialize(String apiKey) async {
    try {
      await _channel.invokeMethod('setGoogleMapsApiKey', {'apiKey': apiKey});
      AppLogger.i('Google Maps API 키 네이티브 전달 완료');
    } on PlatformException catch (e) {
      AppLogger.e('Google Maps API 키 전달 실패: ${e.message}');
    } catch (e) {
      AppLogger.e('Google Maps 초기화 오류: $e');
    }
  }
}

