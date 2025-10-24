import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/disaster.dart';
import '../../domain/repositories/disaster_repository.dart';
import '../../data/repositories/disaster_repository_impl.dart';
import '../../data/sources/remote_data_source.dart';
import '../../core/network/dio_client.dart';
import '../../config/constants.dart';

/// RemoteDataSource Provider
final remoteDataSourceProvider = Provider<RemoteDataSource>((ref) {
  final dio = DioClient.createDio();
  return RemoteDataSource(dio, baseUrl: AppConstants.baseUrl);
});

/// DisasterRepository Provider
final disasterRepositoryProvider = Provider<DisasterRepository>((ref) {
  final remoteDataSource = ref.watch(remoteDataSourceProvider);
  return DisasterRepositoryImpl(remoteDataSource);
});

/// 활성 재난 정보 Provider (목록 조회)
final activeDisastersProvider = FutureProvider<List<Disaster>>((ref) async {
  final repository = ref.watch(disasterRepositoryProvider);
  return await repository.getActiveDisasters();
});

/// 활성 재난 정보 Provider (자동 새로고침 - 5초마다)
final activeDisasterStreamProvider = StreamProvider<Disaster?>((ref) {
  final repository = ref.watch(disasterRepositoryProvider);
  return repository.watchActiveDisaster();
});

/// 위치 기반 재난 정보 Provider
final nearbyDisastersProvider =
    FutureProvider.family<List<Disaster>, _NearbyDisastersParams>((ref, params) async {
  final repository = ref.watch(disasterRepositoryProvider);
  return await repository.getDisastersByLocation(
    latitude: params.latitude,
    longitude: params.longitude,
    radiusKm: params.radiusKm,
  );
});

class _NearbyDisastersParams {
  final double latitude;
  final double longitude;
  final double radiusKm;

  const _NearbyDisastersParams({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _NearbyDisastersParams &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          radiusKm == other.radiusKm;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode ^ radiusKm.hashCode;
}

