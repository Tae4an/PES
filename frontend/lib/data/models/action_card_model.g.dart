// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_card_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionCardModel _$ActionCardModelFromJson(Map<String, dynamic> json) =>
    ActionCardModel(
      id: json['id'] as String,
      disaster:
          DisasterModel.fromJson(json['disaster'] as Map<String, dynamic>),
      nearestShelters: (json['nearest_shelters'] as List<dynamic>)
          .map((e) => ShelterModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      content: json['content'] as String,
      actionItems: (json['action_items'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      generatedAt: json['generated_at'] as String,
      userAge: json['user_age'] as String,
      userMobility: json['user_mobility'] as String,
    );

Map<String, dynamic> _$ActionCardModelToJson(ActionCardModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'disaster': instance.disaster,
      'nearest_shelters': instance.nearestShelters,
      'content': instance.content,
      'action_items': instance.actionItems,
      'generated_at': instance.generatedAt,
      'user_age': instance.userAge,
      'user_mobility': instance.userMobility,
    };
