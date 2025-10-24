import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/action_card.dart';
import 'disaster_provider.dart';
import 'user_provider.dart';
import 'location_provider.dart';

/// 행동 카드 생성 Provider
final actionCardProvider =
    FutureProvider.family<ActionCard?, _ActionCardParams>((ref, params) async {
  final repository = ref.watch(disasterRepositoryProvider);

  return await repository.generateActionCard(
    disasterId: params.disasterId,
    latitude: params.latitude,
    longitude: params.longitude,
    ageGroup: params.ageGroup,
    mobility: params.mobility,
  );
});

/// 현재 활성 재난 기반 행동 카드 Provider (자동 생성)
final currentActionCardProvider = FutureProvider<ActionCard?>((ref) async {
  // 1. 활성 재난 가져오기 (첫 번째 재난 사용)
  final disastersAsync = ref.watch(activeDisastersProvider);
  final disasters = disastersAsync.value;
  if (disasters == null || disasters.isEmpty) return null;
  final disaster = disasters.first;

  // 2. 현재 위치 가져오기
  final locationAsync = ref.watch(currentLocationProvider);
  final location = locationAsync.value;
  if (location == null) return null;

  // 3. 사용자 프로필 가져오기
  final userProfileAsync = ref.watch(userProfileProvider);
  final userProfile = userProfileAsync.value;

  // 4. 행동 카드 생성
  final repository = ref.watch(disasterRepositoryProvider);
  return await repository.generateActionCard(
    disasterId: disaster.id,
    latitude: location.latitude,
    longitude: location.longitude,
    ageGroup: userProfile?.ageGroup ?? '20~40대',
    mobility: userProfile?.mobility ?? 'normal',
  );
});

class _ActionCardParams {
  final int disasterId;
  final double latitude;
  final double longitude;
  final String ageGroup;
  final String mobility;

  const _ActionCardParams({
    required this.disasterId,
    required this.latitude,
    required this.longitude,
    required this.ageGroup,
    required this.mobility,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ActionCardParams &&
          runtimeType == other.runtimeType &&
          disasterId == other.disasterId &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          ageGroup == other.ageGroup &&
          mobility == other.mobility;

  @override
  int get hashCode =>
      disasterId.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      ageGroup.hashCode ^
      mobility.hashCode;
}

