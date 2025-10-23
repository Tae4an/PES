/// 대피소 정보 엔티티
class Shelter {
  final int id;
  final String name;
  final String address;
  final String type;
  final double latitude;
  final double longitude;
  final int capacity;
  final String? phoneNumber;
  final List<String> facilities;
  final bool isAccessible;

  // 계산된 필드 (사용자 위치 기반)
  final double? distanceKm;
  final int? walkingMinutes;

  const Shelter({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.capacity,
    this.phoneNumber,
    this.facilities = const [],
    this.isAccessible = true,
    this.distanceKm,
    this.walkingMinutes,
  });

  Shelter copyWith({
    int? id,
    String? name,
    String? address,
    String? type,
    double? latitude,
    double? longitude,
    int? capacity,
    String? phoneNumber,
    List<String>? facilities,
    bool? isAccessible,
    double? distanceKm,
    int? walkingMinutes,
  }) {
    return Shelter(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capacity: capacity ?? this.capacity,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      facilities: facilities ?? this.facilities,
      isAccessible: isAccessible ?? this.isAccessible,
      distanceKm: distanceKm ?? this.distanceKm,
      walkingMinutes: walkingMinutes ?? this.walkingMinutes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Shelter &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

