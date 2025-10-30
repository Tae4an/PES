/// 사용자 프로필 엔티티 (기본값 하드코딩 포함)
class UserProfile {
  final String? userId;

  // 👤 기본 프로필 정보
  final String gender;        // 'male' 또는 'female'
  final String ageGroup;      // '어린이', '청소년', '성인', '노인'
  final String mobility;      // 'normal', 'limited', 'wheelchair'

  // 🔔 알림 관련
  final bool notificationsEnabled;
  final bool highPriorityNotifications;
  final bool soundEnabled;

  // 🩺 건강 관련
  final bool isPregnant;
  final String medication;    // 복용약 정보
  final String allergy;       // 알레르기
  final String disease;       // 질환 정보

  // 🔗 기타
  final String? fcmToken;
  final DateTime? lastUpdated;

  const UserProfile({
    this.userId,
    this.gender = 'male',                    // 기본 남성
    this.ageGroup = '성인',                  // 기본 성인
    this.mobility = 'normal',                // 정상 이동
    this.notificationsEnabled = true,        // 알림 활성화
    this.highPriorityNotifications = true,   // 중요 알림 우선
    this.soundEnabled = true,                // 소리 켜짐
    this.isPregnant = false,                 // 기본 임신 아님
    this.medication = '없음',                // 복용약 없음
    this.allergy = '없음',                   // 알레르기 없음
    this.disease = '없음',                   // 질환 없음
    this.fcmToken,
    this.lastUpdated,
  });

  UserProfile copyWith({
    String? userId,
    String? gender,
    String? ageGroup,
    String? mobility,
    bool? notificationsEnabled,
    bool? highPriorityNotifications,
    bool? soundEnabled,
    bool? isPregnant,
    String? medication,
    String? allergy,
    String? disease,
    String? fcmToken,
    DateTime? lastUpdated,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      gender: gender ?? this.gender,
      ageGroup: ageGroup ?? this.ageGroup,
      mobility: mobility ?? this.mobility,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      highPriorityNotifications:
          highPriorityNotifications ?? this.highPriorityNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      isPregnant: isPregnant ?? this.isPregnant,
      medication: medication ?? this.medication,
      allergy: allergy ?? this.allergy,
      disease: disease ?? this.disease,
      fcmToken: fcmToken ?? this.fcmToken,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'gender': gender,
      'age_group': ageGroup,
      'mobility': mobility,
      'notifications_enabled': notificationsEnabled,
      'high_priority_notifications': highPriorityNotifications,
      'sound_enabled': soundEnabled,
      'is_pregnant': isPregnant,
      'medication': medication,
      'allergy': allergy,
      'disease': disease,
      'fcm_token': fcmToken,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String?,
      gender: json['gender'] as String? ?? 'male',
      ageGroup: json['age_group'] as String? ?? '성인',
      mobility: json['mobility'] as String? ?? 'normal',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      highPriorityNotifications:
          json['high_priority_notifications'] as bool? ?? true,
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      isPregnant: json['is_pregnant'] as bool? ?? false,
      medication: json['medication'] as String? ?? '없음',
      allergy: json['allergy'] as String? ?? '없음',
      disease: json['disease'] as String? ?? '없음',
      fcmToken: json['fcm_token'] as String?,
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}
