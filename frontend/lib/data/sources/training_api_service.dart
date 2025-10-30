import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';

/// 훈련 시스템 API 서비스
class TrainingApiService {
  final Dio _dio;

  TrainingApiService() : _dio = DioClient.createDio();

  // ===== User API =====
  
  /// ID/PW 로그인
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/v1/users/login',
      data: {
        'username': username,
        'password': password,
      },
    );
    return response.data;
  }

  /// 회원가입 또는 로그인 (자동)
  Future<Map<String, dynamic>> registerOrLogin({
    required String deviceId,
    String? fcmToken,
  }) async {
    final response = await _dio.post(
      '/api/v1/users/register-or-login',
      data: {
        'device_id': deviceId,
        if (fcmToken != null) 'fcm_token': fcmToken,
      },
    );
    return response.data;
  }

  /// 내 정보 조회
  Future<Map<String, dynamic>> getMyInfo(String deviceId) async {
    final response = await _dio.get('/api/v1/users/me/$deviceId');
    return response.data;
  }

  /// 프로필 업데이트
  Future<void> updateProfile({
    required String deviceId,
    String? nickname,
    String? ageGroup,
    String? mobility,
  }) async {
    await _dio.put(
      '/api/v1/users/profile',
      data: {
        'device_id': deviceId,
        if (nickname != null) 'nickname': nickname,
        if (ageGroup != null) 'age_group': ageGroup,
        if (mobility != null) 'mobility': mobility,
      },
    );
  }

  // ===== Training API =====
  
  /// 가까운 대피소 조회
  Future<List<dynamic>> getNearbyShelters({
    required double latitude,
    required double longitude,
    int limit = 5,
  }) async {
    final response = await _dio.get(
      '/api/v1/training/nearby-shelters',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'limit': limit,
      },
    );
    return response.data['shelters'];
  }

  /// 훈련 시작
  Future<Map<String, dynamic>> startTraining({
    required String deviceId,
    required String shelterId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.post(
      '/api/v1/training/start',
      data: {
        'device_id': deviceId,
        'shelter_id': shelterId,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return response.data;
  }

  /// 완료 확인
  Future<Map<String, dynamic>> checkCompletion({
    required int sessionId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.post(
      '/api/v1/training/check',
      data: {
        'session_id': sessionId,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return response.data;
  }

  /// 훈련 기록 조회
  Future<List<dynamic>> getTrainingHistory(String deviceId) async {
    final response = await _dio.get('/api/v1/training/history/$deviceId');
    return response.data['history'];
  }

  /// 훈련 포기
  Future<void> abandonTraining(int sessionId) async {
    await _dio.post('/api/v1/training/abandon/$sessionId');
  }

  // ===== Rewards API =====
  
  /// 보상 목록 조회
  Future<List<dynamic>> getRewardsList() async {
    final response = await _dio.get('/api/v1/rewards/list');
    return response.data['rewards'];
  }

  /// 포인트 조회
  Future<Map<String, dynamic>> getPointsBalance(String deviceId) async {
    final response = await _dio.get('/api/v1/rewards/points/$deviceId');
    return response.data;
  }

  /// 보상 교환
  Future<Map<String, dynamic>> redeemReward({
    required String deviceId,
    required String rewardId,
  }) async {
    final response = await _dio.post(
      '/api/v1/rewards/redeem',
      data: {
        'device_id': deviceId,
        'reward_id': rewardId,
      },
    );
    return response.data;
  }

  /// 내 교환 코드 조회
  Future<List<dynamic>> getMyCodes(String deviceId) async {
    final response = await _dio.get('/api/v1/rewards/my-codes/$deviceId');
    return response.data['codes'];
  }

  /// [개발자용] 훈련 자동 완료
  Future<Map<String, dynamic>> devAutoComplete(int sessionId) async {
    final response = await _dio.post('/api/v1/training/dev/auto-complete/$sessionId');
    return response.data;
  }
}

