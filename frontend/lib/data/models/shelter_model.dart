import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/shelter.dart';

part 'shelter_model.g.dart';

@JsonSerializable()
class ShelterModel {
  @JsonKey(defaultValue: 0)
  final int id;
  final String name;
  final String address;
  @JsonKey(name: 'shelter_type')
  final String type;
  final double latitude;
  final double longitude;
  @JsonKey(defaultValue: 0)
  final int capacity;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  final List<String>? facilities;
  @JsonKey(name: 'is_accessible')
  final bool? isAccessible;
  @JsonKey(name: 'distance_km')
  final double? distanceKm;
  @JsonKey(name: 'walking_minutes')
  final int? walkingMinutes;

  const ShelterModel({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.capacity,
    this.phoneNumber,
    this.facilities,
    this.isAccessible,
    this.distanceKm,
    this.walkingMinutes,
  });

  factory ShelterModel.fromJson(Map<String, dynamic> json) =>
      _$ShelterModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShelterModelToJson(this);

  Shelter toEntity() {
    return Shelter(
      id: id,
      name: name,
      address: address,
      type: type,
      latitude: latitude,
      longitude: longitude,
      capacity: capacity,
      phoneNumber: phoneNumber,
      facilities: facilities ?? [],
      isAccessible: isAccessible ?? true,
      distanceKm: distanceKm,
      walkingMinutes: walkingMinutes,
    );
  }

  factory ShelterModel.fromEntity(Shelter entity) {
    return ShelterModel(
      id: entity.id,
      name: entity.name,
      address: entity.address,
      type: entity.type,
      latitude: entity.latitude,
      longitude: entity.longitude,
      capacity: entity.capacity,
      phoneNumber: entity.phoneNumber,
      facilities: entity.facilities,
      isAccessible: entity.isAccessible,
      distanceKm: entity.distanceKm,
      walkingMinutes: entity.walkingMinutes,
    );
  }
}

