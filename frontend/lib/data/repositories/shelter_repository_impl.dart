import '../../domain/entities/shelter.dart';
import '../../domain/repositories/shelter_repository.dart';
import '../sources/remote_data_source.dart';

class ShelterRepositoryImpl implements ShelterRepository {
  final RemoteDataSource _remoteDataSource;

  ShelterRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Shelter>> getNearestShelters({
    required double latitude,
    required double longitude,
    int limit = 5,
  }) async {
    try {
      final response = await _remoteDataSource.getNearestShelters(
        latitude,
        longitude,
        limit,
      );
      return response.shelters.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get nearest shelters: $e');
    }
  }

  @override
  Future<Shelter> getShelterById(int shelterId) async {
    try {
      final model = await _remoteDataSource.getShelterById(shelterId);
      return model.toEntity();
    } catch (e) {
      throw Exception('Failed to get shelter by id: $e');
    }
  }

  @override
  Future<List<Shelter>> searchShelters(String query) async {
    try {
      final models = await _remoteDataSource.searchShelters(query);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to search shelters: $e');
    }
  }
}

