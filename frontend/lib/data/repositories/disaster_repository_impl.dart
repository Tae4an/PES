import 'dart:async';
import '../../domain/entities/disaster.dart';
import '../../domain/entities/action_card.dart';
import '../../domain/repositories/disaster_repository.dart';
import '../sources/remote_data_source.dart';

class DisasterRepositoryImpl implements DisasterRepository {
  final RemoteDataSource _remoteDataSource;

  DisasterRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Disaster>> getActiveDisasters() async {
    try {
      final models = await _remoteDataSource.getActiveDisasters();
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get active disasters: $e');
    }
  }

  @override
  Future<List<Disaster>> getDisastersByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      final models = await _remoteDataSource.getNearbyDisasters(
        latitude,
        longitude,
        radiusKm,
      );
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get disasters by location: $e');
    }
  }

  @override
  Future<ActionCard> generateActionCard({
    required int disasterId,
    required double latitude,
    required double longitude,
    required String ageGroup,
    required String mobility,
  }) async {
    try {
      final request = {
        'disaster_id': disasterId,
        'latitude': latitude,
        'longitude': longitude,
        'age_group': ageGroup,
        'mobility': mobility,
      };
      final model = await _remoteDataSource.generateActionCard(request);
      return model.toEntity();
    } catch (e) {
      throw Exception('Failed to generate action card: $e');
    }
  }

  @override
  Stream<Disaster?> watchActiveDisaster() {
    // 폴링 기반 실시간 스트림 (5초마다)
    return Stream.periodic(
      const Duration(seconds: 5),
      (_) => getActiveDisasters(),
    ).asyncMap((future) async {
      final disasters = await future;
      return disasters.isNotEmpty ? disasters.first : null;
    });
  }
}

