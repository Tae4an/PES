import '../entities/disaster.dart';
import '../entities/action_card.dart';

/// 재난 정보 리포지토리 인터페이스
abstract class DisasterRepository {
  /// 현재 활성화된 재난 정보 조회
  Future<List<Disaster>> getActiveDisasters();

  /// 특정 위치 기반 재난 정보 조회
  Future<List<Disaster>> getDisastersByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  });

  /// 행동 카드 생성 요청
  Future<ActionCard> generateActionCard({
    required int disasterId,
    required double latitude,
    required double longitude,
    required String ageGroup,
    required String mobility,
  });

  /// 재난 정보 실시간 스트림
  Stream<Disaster?> watchActiveDisaster();
}

