import 'package:flutter/foundation.dart';
import '../../data/sources/training_api_service.dart';
import '../../core/utils/logger.dart';

/// 보상 모델
class Reward {
  final String id;
  final String partner;
  final String name;
  final int points;
  final String image;
  final String description;

  Reward({
    required this.id,
    required this.partner,
    required this.name,
    required this.points,
    required this.image,
    required this.description,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      partner: json['partner'],
      name: json['name'],
      points: json['points'] as int,
      image: json['image'],
      description: json['description'] ?? '',
    );
  }
}

/// 교환 코드 모델
class RedemptionCode {
  final int id;
  final String rewardName;
  final String code;
  final int pointsSpent;
  final DateTime redeemedAt;

  RedemptionCode({
    required this.id,
    required this.rewardName,
    required this.code,
    required this.pointsSpent,
    required this.redeemedAt,
  });

  factory RedemptionCode.fromJson(Map<String, dynamic> json) {
    return RedemptionCode(
      id: json['id'] as int,
      rewardName: json['reward_name'],
      code: json['redemption_code'],
      pointsSpent: json['points_spent'] as int,
      redeemedAt: DateTime.parse(json['redeemed_at']),
    );
  }
}

/// 보상 상태
class RewardsState {
  final List<Reward> rewards;
  final List<RedemptionCode> myCodes;
  final int totalPoints;
  final int completedTrainings;
  final bool isLoading;
  final String? error;

  RewardsState({
    this.rewards = const [],
    this.myCodes = const [],
    this.totalPoints = 0,
    this.completedTrainings = 0,
    this.isLoading = false,
    this.error,
  });

  RewardsState copyWith({
    List<Reward>? rewards,
    List<RedemptionCode>? myCodes,
    int? totalPoints,
    int? completedTrainings,
    bool? isLoading,
    String? error,
  }) {
    return RewardsState(
      rewards: rewards ?? this.rewards,
      myCodes: myCodes ?? this.myCodes,
      totalPoints: totalPoints ?? this.totalPoints,
      completedTrainings: completedTrainings ?? this.completedTrainings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 보상 Provider
class RewardsProvider extends ChangeNotifier {
  final TrainingApiService _apiService = TrainingApiService();
  RewardsState _state = RewardsState();

  RewardsState get state => _state;

  /// 보상 목록 로드
  Future<void> loadRewards() async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final rewards = await _apiService.getRewardsList();

      _state = _state.copyWith(
        rewards: rewards.map((r) => Reward.fromJson(r)).toList(),
        isLoading: false,
      );

      AppLogger.i('보상 ${_state.rewards.length}개 로드 완료');
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: '보상 목록 로드 실패: $e',
      );
      AppLogger.e('보상 목록 로드 실패: $e');
      notifyListeners();
    }
  }

  /// 포인트 잔액 조회
  Future<void> loadPointsBalance(String deviceId) async {
    try {
      final response = await _apiService.getPointsBalance(deviceId);

      _state = _state.copyWith(
        totalPoints: response['total_points'] as int,
        completedTrainings: response['completed_trainings'] as int,
      );

      notifyListeners();
    } catch (e) {
      AppLogger.e('포인트 조회 실패: $e');
    }
  }

  /// 보상 교환
  Future<String> redeemReward({
    required String deviceId,
    required String rewardId,
  }) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final response = await _apiService.redeemReward(
        deviceId: deviceId,
        rewardId: rewardId,
      );

      // 포인트 업데이트
      _state = _state.copyWith(
        totalPoints: response['remaining_points'] as int,
        isLoading: false,
      );

      AppLogger.i('보상 교환 성공: ${response['redemption_code']}');
      notifyListeners();

      // 내 코드 목록 새로고침
      await loadMyCodes(deviceId);

      return response['redemption_code'] as String;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: '보상 교환 실패: $e',
      );
      AppLogger.e('보상 교환 실패: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// 내 교환 코드 조회
  Future<void> loadMyCodes(String deviceId) async {
    try {
      final codes = await _apiService.getMyCodes(deviceId);

      _state = _state.copyWith(
        myCodes: codes.map((c) => RedemptionCode.fromJson(c)).toList(),
      );

      AppLogger.i('교환 코드 ${_state.myCodes.length}개 로드 완료');
      notifyListeners();
    } catch (e) {
      AppLogger.e('교환 코드 조회 실패: $e');
    }
  }

  /// 포인트 추가 (로컬 업데이트)
  void addPoints(int points) {
    _state = _state.copyWith(totalPoints: _state.totalPoints + points);
    notifyListeners();
  }
}

