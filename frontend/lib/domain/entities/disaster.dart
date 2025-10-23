/// 재난 정보 엔티티
class Disaster {
  final int id;
  final String type;
  final String location;
  final String message;
  final String severity;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final DateTime createdAt;
  final bool isActive;

  const Disaster({
    required this.id,
    required this.type,
    required this.location,
    required this.message,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.createdAt,
    required this.isActive,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Disaster &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

