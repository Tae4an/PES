// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shelter_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShelterModel _$ShelterModelFromJson(Map<String, dynamic> json) => ShelterModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String,
      address: json['address'] as String,
      type: json['shelter_type'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      phoneNumber: json['phone_number'] as String?,
      facilities: (json['facilities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isAccessible: json['is_accessible'] as bool?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      walkingMinutes: (json['walking_minutes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ShelterModelToJson(ShelterModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'shelter_type': instance.type,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'capacity': instance.capacity,
      'phone_number': instance.phoneNumber,
      'facilities': instance.facilities,
      'is_accessible': instance.isAccessible,
      'distance_km': instance.distanceKm,
      'walking_minutes': instance.walkingMinutes,
    };
