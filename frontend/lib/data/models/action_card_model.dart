import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/action_card.dart';
import 'disaster_model.dart';
import 'shelter_model.dart';

part 'action_card_model.g.dart';

@JsonSerializable()
class ActionCardModel {
  final String id;
  final DisasterModel disaster;
  @JsonKey(name: 'nearest_shelters')
  final List<ShelterModel> nearestShelters;
  final String content;
  @JsonKey(name: 'action_items')
  final List<String> actionItems;
  @JsonKey(name: 'generated_at')
  final String generatedAt;
  @JsonKey(name: 'user_age')
  final String userAge;
  @JsonKey(name: 'user_mobility')
  final String userMobility;

  const ActionCardModel({
    required this.id,
    required this.disaster,
    required this.nearestShelters,
    required this.content,
    required this.actionItems,
    required this.generatedAt,
    required this.userAge,
    required this.userMobility,
  });

  factory ActionCardModel.fromJson(Map<String, dynamic> json) =>
      _$ActionCardModelFromJson(json);

  Map<String, dynamic> toJson() => _$ActionCardModelToJson(this);

  ActionCard toEntity() {
    return ActionCard(
      id: id,
      disaster: disaster.toEntity(),
      nearestShelters: nearestShelters.map((s) => s.toEntity()).toList(),
      content: content,
      actionItems: actionItems,
      generatedAt: DateTime.parse(generatedAt),
      userAge: userAge,
      userMobility: userMobility,
    );
  }

  factory ActionCardModel.fromEntity(ActionCard entity) {
    return ActionCardModel(
      id: entity.id,
      disaster: DisasterModel.fromEntity(entity.disaster),
      nearestShelters: entity.nearestShelters
          .map((s) => ShelterModel.fromEntity(s))
          .toList(),
      content: entity.content,
      actionItems: entity.actionItems,
      generatedAt: entity.generatedAt.toIso8601String(),
      userAge: entity.userAge,
      userMobility: entity.userMobility,
    );
  }
}

