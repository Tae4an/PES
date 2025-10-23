// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_card_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionCardModel _$ActionCardModelFromJson(Map<String, dynamic> json) =>
    ActionCardModel(
      id: json['id'] as String,
      disasterId: (json['disaster_id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String,
      estimatedTime: (json['estimated_time'] as num).toInt(),
      steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
      emergencyContacts: (json['emergency_contacts'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$ActionCardModelToJson(ActionCardModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'disaster_id': instance.disasterId,
      'title': instance.title,
      'description': instance.description,
      'priority': instance.priority,
      'estimated_time': instance.estimatedTime,
      'steps': instance.steps,
      'emergency_contacts': instance.emergencyContacts,
      'created_at': instance.createdAt,
    };
