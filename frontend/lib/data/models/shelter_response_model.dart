import 'package:json_annotation/json_annotation.dart';
import 'shelter_model.dart';

part 'shelter_response_model.g.dart';

@JsonSerializable()
class ShelterResponseModel {
  final List<ShelterModel> shelters;
  @JsonKey(name: 'total_count')
  final int totalCount;
  @JsonKey(name: 'search_radius_km')
  final double searchRadiusKm;

  const ShelterResponseModel({
    required this.shelters,
    required this.totalCount,
    required this.searchRadiusKm,
  });

  factory ShelterResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ShelterResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShelterResponseModelToJson(this);
}

