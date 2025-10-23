import 'disaster.dart';
import 'shelter.dart';

/// 개인화된 행동 카드 엔티티
class ActionCard {
  final String id;
  final Disaster disaster;
  final List<Shelter> nearestShelters;
  final String content; // LLM이 생성한 3~5줄 행동 카드
  final List<String> actionItems; // 주요 행동 지침
  final DateTime generatedAt;
  final String userAge;
  final String userMobility;

  const ActionCard({
    required this.id,
    required this.disaster,
    required this.nearestShelters,
    required this.content,
    required this.actionItems,
    required this.generatedAt,
    this.userAge = 'unknown',
    this.userMobility = 'normal',
  });

  String get disasterType => disaster.type;
  String get location => disaster.location;

  Shelter? get closestShelter =>
      nearestShelters.isNotEmpty ? nearestShelters.first : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionCard &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

