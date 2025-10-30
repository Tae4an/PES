import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/sources/training_api_service.dart';
import '../../core/utils/logger.dart';

/// 대피소 모델
class Shelter {
  final String id;
  final String name;
  final String address;
  final String type;
  final double latitude;
  final double longitude;
  final double distance;

  Shelter({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.distance,
  });

  factory Shelter.fromJson(Map<String, dynamic> json) {
    return Shelter(
      id: json['id'].toString(),
      name: json['name'],
      address: json['address'],
      type: json['shelter_type'] ?? json['type'] ?? '대피소',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
    );
  }

  LatLng get position => LatLng(latitude, longitude);
}

/// 훈련 세션 상태
class TrainingSession {
  final int sessionId;
  final String userId;
  final Shelter shelter;
  final double initialDistance;

  TrainingSession({
    required this.sessionId,
    required this.userId,
    required this.shelter,
    required this.initialDistance,
  });
}

/// 훈련 상태
class TrainingState {
  final List<Shelter> nearbyShelters;
  final TrainingSession? currentSession;
  final bool isTraining;
  final double currentDistance;
  final bool isCompleted;
  final int? pointsEarned;
  final bool isLoading;
  final String? error;

  TrainingState({
    this.nearbyShelters = const [],
    this.currentSession,
    this.isTraining = false,
    this.currentDistance = 0,
    this.isCompleted = false,
    this.pointsEarned,
    this.isLoading = false,
    this.error,
  });

  TrainingState copyWith({
    List<Shelter>? nearbyShelters,
    TrainingSession? currentSession,
    bool? isTraining,
    double? currentDistance,
    bool? isCompleted,
    int? pointsEarned,
    bool? isLoading,
    String? error,
  }) {
    return TrainingState(
      nearbyShelters: nearbyShelters ?? this.nearbyShelters,
      currentSession: currentSession ?? this.currentSession,
      isTraining: isTraining ?? this.isTraining,
      currentDistance: currentDistance ?? this.currentDistance,
      isCompleted: isCompleted ?? this.isCompleted,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 훈련 Provider
class TrainingProvider extends ChangeNotifier {
  final TrainingApiService _apiService = TrainingApiService();
  TrainingState _state = TrainingState();
  Timer? _locationCheckTimer;

  TrainingState get state => _state;

  /// 가까운 대피소 조회
  Future<void> loadNearbyShelters(LatLng currentLocation) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final shelters = await _apiService.getNearbyShelters(
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
        limit: 5,
      );

      _state = _state.copyWith(
        nearbyShelters: shelters.map((s) => Shelter.fromJson(s)).toList(),
        isLoading: false,
      );

      AppLogger.i('대피소 ${_state.nearbyShelters.length}개 로드 완료');
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: '대피소 조회 실패: $e',
      );
      AppLogger.e('대피소 조회 실패: $e');
      notifyListeners();
    }
  }

  /// 훈련 시작
  Future<void> startTraining({
    required String deviceId,
    required Shelter shelter,
    required LatLng currentLocation,
    required Function(int sessionId) onLocationCheck,
  }) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final response = await _apiService.startTraining(
        deviceId: deviceId,
        shelterId: shelter.id,
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
      );

      final session = TrainingSession(
        sessionId: response['session_id'],
        userId: response['user_id'],
        shelter: Shelter.fromJson(response['shelter']),
        initialDistance: (response['initial_distance'] as num).toDouble(),
      );

      _state = _state.copyWith(
        currentSession: session,
        isTraining: true,
        currentDistance: session.initialDistance,
        isCompleted: false,
        isLoading: false,
      );

      AppLogger.i('훈련 시작: session_id=${session.sessionId}');
      notifyListeners();

      // 1초마다 위치 체크 시작
      _startLocationTracking(session.sessionId, onLocationCheck);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: '훈련 시작 실패: $e',
      );
      AppLogger.e('훈련 시작 실패: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// 위치 추적 시작
  void _startLocationTracking(int sessionId, Function(int) onLocationCheck) {
    _locationCheckTimer?.cancel();
    _locationCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      onLocationCheck(sessionId);
    });
  }

  /// 완료 확인
  Future<void> checkCompletion({
    required int sessionId,
    required LatLng currentLocation,
  }) async {
    try {
      final response = await _apiService.checkCompletion(
        sessionId: sessionId,
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
      );

      final isCompleted = response['is_completed'] as bool;
      final distance = (response['distance'] as num).toDouble();

      if (isCompleted) {
        // 훈련 완료!
        _locationCheckTimer?.cancel();

        _state = _state.copyWith(
          isTraining: false,
          isCompleted: true,
          currentDistance: distance,
          pointsEarned: response['points_earned'] as int?,
        );

        AppLogger.i('훈련 완료! 포인트: ${response['points_earned']}');
        notifyListeners();
      } else {
        // 아직 진행 중
        _state = _state.copyWith(currentDistance: distance);
        notifyListeners();
      }
    } catch (e) {
      AppLogger.e('완료 확인 실패: $e');
    }
  }

  /// 훈련 포기
  Future<void> abandonTraining() async {
    try {
      if (_state.currentSession == null) return;

      await _apiService.abandonTraining(_state.currentSession!.sessionId);

      _locationCheckTimer?.cancel();
      _state = _state.copyWith(
        currentSession: null,
        isTraining: false,
        currentDistance: 0,
        isCompleted: false,
        pointsEarned: null,
      );

      AppLogger.i('훈련 포기');
      notifyListeners();
    } catch (e) {
      AppLogger.e('훈련 포기 실패: $e');
    }
  }

  /// 훈련 완료 후 초기화
  void resetTraining() {
    _locationCheckTimer?.cancel();
    _state = _state.copyWith(
      currentSession: null,
      isTraining: false,
      currentDistance: 0,
      isCompleted: false,
      pointsEarned: null,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _locationCheckTimer?.cancel();
    super.dispose();
  }
}

