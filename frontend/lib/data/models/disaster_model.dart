import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/disaster.dart';

part 'disaster_model.g.dart';

@JsonSerializable()
class DisasterModel {
  @JsonKey(name: 'serial_number')
  final int serialNumber;
  final String date;
  final String time;
  final String category;
  final String message;
  @JsonKey(name: 'issued_at')
  final String issuedAt;

  const DisasterModel({
    required this.serialNumber,
    required this.date,
    required this.time,
    required this.category,
    required this.message,
    required this.issuedAt,
  });

  factory DisasterModel.fromJson(Map<String, dynamic> json) =>
      _$DisasterModelFromJson(json);

  Map<String, dynamic> toJson() => _$DisasterModelToJson(this);

  Disaster toEntity() {
    return Disaster(
      id: serialNumber,
      type: category,
      location: '제주도', // 백엔드 데이터에 위치 정보가 없으므로 기본값
      message: message,
      severity: 'high', // 기본값
      latitude: 37.3219, // 안산시청 위도
      longitude: 126.8309, // 안산시청 경도
      radiusKm: 5.0, // 기본 반경 (안산 시내)
      createdAt: DateTime.parse(issuedAt),
      isActive: true, // 활성 재난으로 간주
    );
  }

  factory DisasterModel.fromEntity(Disaster entity) {
    return DisasterModel(
      serialNumber: entity.id,
      date: entity.createdAt.toIso8601String().split('T')[0],
      time: entity.createdAt.toIso8601String().split('T')[1].split('.')[0],
      category: entity.type,
      message: entity.message,
      issuedAt: entity.createdAt.toIso8601String(),
    );
  }
}

