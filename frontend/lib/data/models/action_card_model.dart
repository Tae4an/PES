import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/action_card.dart';
import '../../domain/entities/disaster.dart';
import 'disaster_model.dart';
import 'shelter_model.dart';

part 'action_card_model.g.dart';

@JsonSerializable()
class ActionCardModel {
  final String id;
  @JsonKey(name: 'disaster_id')
  final int disasterId;
  final String title;
  final String description;
  final String? priority;
  @JsonKey(name: 'estimated_time')
  final int estimatedTime;
  final List<String> steps;
  @JsonKey(name: 'emergency_contacts')
  final List<String> emergencyContacts;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const ActionCardModel({
    required this.id,
    required this.disasterId,
    required this.title,
    required this.description,
    this.priority,
    required this.estimatedTime,
    required this.steps,
    required this.emergencyContacts,
    required this.createdAt,
  });

  factory ActionCardModel.fromJson(Map<String, dynamic> json) =>
      _$ActionCardModelFromJson(json);

  Map<String, dynamic> toJson() => _$ActionCardModelToJson(this);

  ActionCard toEntity() {
    return ActionCard(
      id: id,
      disaster: Disaster(
        id: disasterId,
        type: '재난', // 기본값
        location: '경기도 안산시', // 안산시 기본값
        message: description,
        severity: priority ?? 'high',
        latitude: 37.2970, // 한양대 ERICA 캠퍼스 위도
        longitude: 126.8373, // 한양대 ERICA 캠퍼스 경도
        radiusKm: 3.0, // 기본 반경 (캠퍼스 주변)
        createdAt: DateTime.parse(createdAt),
        isActive: true,
      ),
      nearestShelters: [], // 빈 배열로 초기화
      content: description,
      actionItems: steps,
      generatedAt: DateTime.parse(createdAt),
      userAge: '20~40대', // 기본값
      userMobility: 'normal', // 기본값
    );
  }

  factory ActionCardModel.fromEntity(ActionCard entity) {
    return ActionCardModel(
      id: entity.id,
      disasterId: entity.disaster.id,
      title: '재난 대피 행동 지침',
      description: entity.content,
      priority: entity.disaster.severity,
      estimatedTime: 15, // 기본값
      steps: entity.actionItems,
      emergencyContacts: ['119', '112'],
      createdAt: entity.generatedAt.toIso8601String(),
    );
  }
}
