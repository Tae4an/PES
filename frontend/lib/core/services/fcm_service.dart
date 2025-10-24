import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';
import '../utils/logger.dart';

/// FCM 토큰 등록 요청 모델
class FCMTokenRequest {
  final String fcmToken;
  final String? userId;
  final String deviceType;
  final String? appVersion;

  FCMTokenRequest({
    required this.fcmToken,
    this.userId,
    this.deviceType = 'mobile',
    this.appVersion,
  });

  Map<String, dynamic> toJson() => {
        'fcm_token': fcmToken,
        if (userId != null) 'user_id': userId,
        'device_type': deviceType,
        if (appVersion != null) 'app_version': appVersion,
      };
}

/// FCM 토큰 등록 응답 모델
class FCMTokenResponse {
  final bool success;
  final String message;
  final String? tokenId;
  final DateTime registeredAt;

  FCMTokenResponse({
    required this.success,
    required this.message,
    this.tokenId,
    required this.registeredAt,
  });

  factory FCMTokenResponse.fromJson(Map<String, dynamic> json) {
    return FCMTokenResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      tokenId: json['token_id'],
      registeredAt: DateTime.parse(json['registered_at']),
    );
  }
}

/// 테스트 알림 요청 모델
class TestNotificationRequest {
  final String fcmToken;
  final String title;
  final String body;

  TestNotificationRequest({
    required this.fcmToken,
    this.title = 'PES 테스트 알림',
    this.body = 'Firebase 푸시 알림이 정상적으로 작동합니다!',
  });

  Map<String, dynamic> toJson() => {
        'fcm_token': fcmToken,
        'title': title,
        'body': body,
      };
}

/// FCM 서비스 클래스
class FCMService {
  final DioClient _dioClient;

  FCMService(this._dioClient);

  /// FCM 토큰을 서버에 등록
  Future<FCMTokenResponse> registerToken(FCMTokenRequest request) async {
    try {
      AppLogger.i('FCM 토큰 서버 등록 시작: ${request.fcmToken.substring(0, 20)}...');

      final response = await _dioClient.dio.post(
        ApiEndpoints.registerFcmToken,
        data: request.toJson(),
      );

      final result = FCMTokenResponse.fromJson(response.data);
      AppLogger.i('FCM 토큰 등록 성공: ${result.tokenId}');
      
      return result;
    } on DioException catch (e) {
      AppLogger.e('FCM 토큰 등록 실패 (DioException): ${e.message}');
      throw Exception('FCM 토큰 등록 실패: ${e.message}');
    } catch (e) {
      AppLogger.e('FCM 토큰 등록 실패: $e');
      throw Exception('FCM 토큰 등록 실패: $e');
    }
  }

  /// 테스트 푸시 알림 전송
  Future<bool> sendTestNotification(TestNotificationRequest request) async {
    try {
      AppLogger.i('테스트 알림 전송 시작: ${request.fcmToken.substring(0, 20)}...');

      final response = await _dioClient.dio.post(
        ApiEndpoints.testNotification,
        data: request.toJson(),
      );

      final success = response.data['success'] ?? false;
      if (success) {
        AppLogger.i('테스트 알림 전송 성공');
      } else {
        AppLogger.w('테스트 알림 전송 실패: ${response.data['message']}');
      }
      
      return success;
    } on DioException catch (e) {
      AppLogger.e('테스트 알림 전송 실패 (DioException): ${e.message}');
      return false;
    } catch (e) {
      AppLogger.e('테스트 알림 전송 실패: $e');
      return false;
    }
  }

  /// FCM 서비스 상태 확인
  Future<Map<String, dynamic>> getStatus() async {
    try {
      AppLogger.i('FCM 서비스 상태 확인');

      final response = await _dioClient.dio.get(ApiEndpoints.fcmStatus);
      
      AppLogger.i('FCM 상태: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      AppLogger.e('FCM 상태 확인 실패 (DioException): ${e.message}');
      return {
        'fcm_initialized': false,
        'firebase_available': false,
        'service_status': 'error',
        'error': e.message,
      };
    } catch (e) {
      AppLogger.e('FCM 상태 확인 실패: $e');
      return {
        'fcm_initialized': false,
        'firebase_available': false,
        'service_status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// 앱 정보 가져오기 (디버그용)
  String _getAppVersion() {
    // TODO: package_info_plus 사용하여 실제 앱 버전 가져오기
    return kDebugMode ? '1.0.0-debug' : '1.0.0';
  }

  /// 기기 타입 감지
  String _getDeviceType() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'android';
    } else {
      return 'mobile';
    }
  }

  /// 편의 메서드: 현재 기기 정보로 FCM 토큰 등록
  Future<FCMTokenResponse> registerCurrentDevice(String fcmToken, {String? userId}) async {
    final request = FCMTokenRequest(
      fcmToken: fcmToken,
      userId: userId,
      deviceType: _getDeviceType(),
      appVersion: _getAppVersion(),
    );

    return await registerToken(request);
  }
}
