import '../entities/shelter.dart';

/// 대피소 리포지토리 인터페이스
abstract class ShelterRepository {
  /// 현재 위치 기반 가까운 대피소 조회
  Future<List<Shelter>> getNearestShelters({
    required double latitude,
    required double longitude,
    int limit = 5,
  });

  /// 특정 대피소 상세 정보 조회
  Future<Shelter> getShelterById(int shelterId);

  /// 대피소 검색 (이름, 주소)
  Future<List<Shelter>> searchShelters(String query);
}

