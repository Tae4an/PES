import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/disaster.dart';

/// 테스트 재난 Provider
final testDisasterProvider = StateNotifierProvider<TestDisasterNotifier, Disaster?>((ref) {
  return TestDisasterNotifier();
});

class TestDisasterNotifier extends StateNotifier<Disaster?> {
  TestDisasterNotifier() : super(null);

  /// 재난 시나리오 생성 (안산 지역 기준)
  void createScenario(String disasterType, double latitude, double longitude) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final scenarios = {
      'earthquake': Disaster(
        id: 9001,
        type: '지진',
        severity: '심각',
        location: '경기도 안산시',
        message: '[긴급재난문자] 금일 $timeStr 안산시 상록구 서쪽 2km 지역 규모 5.4 지진 발생. 여진이 계속될 수 있으니 튼튼한 탁자 아래로 대피하고, 추가 지진 발생에 유의해 주시기 바랍니다. 엘리베이터 이용을 금지하고 계단을 이용하여 대피하시기 바랍니다.[안산시]',
        latitude: latitude,
        longitude: longitude,
        createdAt: now,
        radiusKm: 10.0,
        isActive: true,
      ),
      'tsunami': Disaster(
        id: 9002,
        type: '해일',
        severity: '위험',
        location: '안산시 대부도 연안',
        message: '[긴급재난문자] 안산시 대부도 및 시화방조제 일대 해일특보 발효. 해안가 주민 및 방문객은 즉시 고지대로 대피하시기 바라며, 해안도로 통제 중입니다. 선박은 긴급 귀항 또는 먼바다 대피 바랍니다. 해안가 접근을 금지합니다.[안산시]',
        latitude: latitude,
        longitude: longitude,
        createdAt: now,
        radiusKm: 15.0,
        isActive: true,
      ),
      'fire': Disaster(
        id: 9003,
        type: '화재',
        severity: '위험',
        location: '안산시 단원구 고잔동',
        message: '[긴급재난문자] 현재 안산시 단원구 고잔동 소재 상가건물 화재로 인한 다량의 연기 발생 중. 인근 주민은 창문을 닫고 실내 대피하시기 바라며, 차량 등은 우회 및 주의하시기 바랍니다. 호흡기 질환자는 외출을 자제하고 젖은 수건으로 코와 입을 막으시기 바랍니다.[안산시]',
        latitude: latitude,
        longitude: longitude,
        createdAt: now,
        radiusKm: 5.0,
        isActive: true,
      ),
      'war': Disaster(
        id: 9004,
        type: '민방공',
        severity: '심각',
        location: '경기도 전역',
        message: '[민방위 경보발령] 경기도 전역에 공습경보가 발령되었습니다. 즉시 가까운 지하대피소나 건물 지하로 대피하시기 바랍니다. ▲모든 차량 운행 즉시 중지 ▲실외 활동 금지 ▲TV/라디오로 상황 확인 ▲추가 안내가 있을 때까지 대피소에서 대기하시기 바랍니다.[안산시]',
        latitude: latitude,
        longitude: longitude,
        createdAt: now,
        radiusKm: 50.0,
        isActive: true,
      ),
    };

    state = scenarios[disasterType];
  }

  /// 재난 초기화
  void clear() {
    state = null;
  }
}

