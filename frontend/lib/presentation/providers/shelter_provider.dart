import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/shelter.dart';
import '../../domain/repositories/shelter_repository.dart';
import '../../data/repositories/shelter_repository_impl.dart';
import 'disaster_provider.dart';

/// ShelterRepository Provider
final shelterRepositoryProvider = Provider<ShelterRepository>((ref) {
  final remoteDataSource = ref.watch(remoteDataSourceProvider);
  return ShelterRepositoryImpl(remoteDataSource);
});

/// 가까운 대피소 Provider
final nearestSheltersProvider =
    FutureProvider.family<List<Shelter>, NearestSheltersParams>((ref, params) async {
  final repository = ref.watch(shelterRepositoryProvider);
  return await repository.getNearestShelters(
    latitude: params.latitude,
    longitude: params.longitude,
    limit: params.limit,
  );
});

/// 대피소 상세 정보 Provider
final shelterDetailProvider = FutureProvider.family<Shelter, int>((ref, shelterId) async {
  final repository = ref.watch(shelterRepositoryProvider);
  return await repository.getShelterById(shelterId);
});

/// 대피소 검색 Provider
final shelterSearchProvider =
    FutureProvider.family<List<Shelter>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(shelterRepositoryProvider);
  return await repository.searchShelters(query);
});

class NearestSheltersParams {
  final double latitude;
  final double longitude;
  final int limit;

  const NearestSheltersParams({
    required this.latitude,
    required this.longitude,
    this.limit = 10,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearestSheltersParams &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          limit == other.limit;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode ^ limit.hashCode;
}

