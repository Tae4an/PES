import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/sources/training_api_service.dart';
import '../../core/utils/device_utils.dart';
import '../../core/utils/logger.dart';

/// 훈련 시스템 사용자 상태
class TrainingUserState {
  final String? userId;
  final String? deviceId;
  final String nickname;
  final String? ageGroup;
  final String mobility;
  final int totalPoints;
  final bool isNewUser;
  final bool isLoading;
  final String? error;

  TrainingUserState({
    this.userId,
    this.deviceId,
    this.nickname = '익명',
    this.ageGroup,
    this.mobility = '정상',
    this.totalPoints = 0,
    this.isNewUser = false,
    this.isLoading = false,
    this.error,
  });

  TrainingUserState copyWith({
    String? userId,
    String? deviceId,
    String? username,
    String? nickname,
    String? ageGroup,
    String? mobility,
    int? totalPoints,
    bool? isNewUser,
    bool? isLoading,
    String? error,
  }) {
    return TrainingUserState(
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      nickname: nickname ?? this.nickname,
      ageGroup: ageGroup ?? this.ageGroup,
      mobility: mobility ?? this.mobility,
      totalPoints: totalPoints ?? this.totalPoints,
      isNewUser: isNewUser ?? this.isNewUser,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 훈련 시스템 사용자 Provider
class TrainingUserProvider extends ChangeNotifier {
  final TrainingApiService _apiService = TrainingApiService();
  TrainingUserState _state = TrainingUserState();

  TrainingUserState get state => _state;

  /// ID/PW 로그인
  Future<void> login(String username, String password) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final response = await _apiService.login(
        username: username,
        password: password,
      );

      AppLogger.i('로그인 API 응답: $response');

      // SharedPreferences에 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', response['user_id']);
      await prefs.setString('username', response['username']);

      _state = TrainingUserState(
        userId: response['user_id'],
        deviceId: response['username'], // username을 deviceId처럼 사용
        nickname: response['nickname'] ?? '익명',
        ageGroup: response['age_group'],
        mobility: response['mobility'] ?? '정상',
        totalPoints: response['total_points'] ?? 0,
        isNewUser: false,
        isLoading: false,
      );

      AppLogger.i('로그인 성공 - userId: ${_state.userId}, username: $username');
      notifyListeners();
    } catch (e) {
      AppLogger.e('로그인 실패: $e');
      _state = _state.copyWith(
        isLoading: false,
        error: '로그인 실패: $e',
      );
      notifyListeners();
      rethrow;
    }
  }

  /// 자동 로그인 체크
  Future<bool> checkAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final username = prefs.getString('username');

      if (userId != null && username != null) {
        _state = _state.copyWith(
          userId: userId,
          deviceId: username,
        );
        AppLogger.i('자동 로그인 - userId: $userId, username: $username');
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.e('자동 로그인 체크 실패: $e');
      return false;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('device_id');
    
    _state = TrainingUserState();
    notifyListeners();
    AppLogger.i('로그아웃 완료');
  }

  /// 자동 로그인/회원가입
  Future<void> registerOrLogin({String? fcmToken}) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      // 1. 디바이스 ID 가져오기
      final deviceId = await DeviceUtils.getDeviceId();
      AppLogger.i('Device ID: $deviceId');

      // 2. API 호출
      final response = await _apiService.registerOrLogin(
        deviceId: deviceId,
        fcmToken: fcmToken,
      );
      
      AppLogger.i('로그인 API 응답: $response');

      // 3. 상태 업데이트
      _state = TrainingUserState(
        userId: response['user_id'],
        deviceId: response['device_id'],
        nickname: response['nickname'] ?? '익명',
        ageGroup: response['age_group'],
        mobility: response['mobility'] ?? '정상',
        totalPoints: response['total_points'] ?? 0,
        isNewUser: response['is_new_user'] ?? false,
        isLoading: false,
      );
      
      AppLogger.i('Provider 상태 업데이트 완료 - userId: ${_state.userId}, deviceId: ${_state.deviceId}');

      // 4. SharedPreferences에 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_id', deviceId);
      await prefs.setString('user_id', response['user_id']);

      AppLogger.i('로그인 성공: ${_state.nickname} (새 사용자: ${_state.isNewUser})');
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: '로그인 실패: $e',
      );
      AppLogger.e('로그인 실패: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// 내 정보 새로고침
  Future<void> refreshMyInfo() async {
    try {
      if (_state.deviceId == null) return;

      final response = await _apiService.getMyInfo(_state.deviceId!);

      _state = _state.copyWith(
        nickname: response['nickname'] ?? '익명',
        ageGroup: response['age_group'],
        mobility: response['mobility'] ?? '정상',
        totalPoints: response['total_points'] ?? 0,
      );

      notifyListeners();
    } catch (e) {
      AppLogger.e('정보 새로고침 실패: $e');
    }
  }

  /// 프로필 업데이트
  Future<void> updateProfile({
    String? nickname,
    String? ageGroup,
    String? mobility,
  }) async {
    try {
      if (_state.deviceId == null) {
        throw Exception('로그인이 필요합니다');
      }

      await _apiService.updateProfile(
        deviceId: _state.deviceId!,
        nickname: nickname,
        ageGroup: ageGroup,
        mobility: mobility,
      );

      // 상태 업데이트
      _state = _state.copyWith(
        nickname: nickname ?? _state.nickname,
        ageGroup: ageGroup ?? _state.ageGroup,
        mobility: mobility ?? _state.mobility,
      );

      AppLogger.i('프로필 업데이트 완료');
      notifyListeners();
    } catch (e) {
      AppLogger.e('프로필 업데이트 실패: $e');
      rethrow;
    }
  }

  /// 포인트 추가 (로컬 업데이트용)
  void addPoints(int points) {
    _state = _state.copyWith(totalPoints: _state.totalPoints + points);
    notifyListeners();
  }

  /// 포인트 차감 (로컬 업데이트용)
  void subtractPoints(int points) {
    _state = _state.copyWith(totalPoints: _state.totalPoints - points);
    notifyListeners();
  }

  /// 로그아웃 (로컬 데이터 삭제)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    _state = TrainingUserState();
    notifyListeners();
    
    AppLogger.i('로그아웃 완료');
  }
}

