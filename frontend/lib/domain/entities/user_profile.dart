/// 사용자 프로필 엔티티
class UserProfile {
  final String? userId;
  final String ageGroup; // '10대', '20~40대', '50~60대', '70대+'
  final String mobility; // 'normal', 'limited', 'wheelchair'
  final bool notificationsEnabled;
  final bool highPriorityNotifications;
  final bool soundEnabled;
  final String? fcmToken;
  final DateTime? lastUpdated;

  const UserProfile({
    this.userId,
    this.ageGroup = '20~40대',
    this.mobility = 'normal',
    this.notificationsEnabled = true,
    this.highPriorityNotifications = true,
    this.soundEnabled = true,
    this.fcmToken,
    this.lastUpdated,
  });

  UserProfile copyWith({
    String? userId,
    String? ageGroup,
    String? mobility,
    bool? notificationsEnabled,
    bool? highPriorityNotifications,
    bool? soundEnabled,
    String? fcmToken,
    DateTime? lastUpdated,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      ageGroup: ageGroup ?? this.ageGroup,
      mobility: mobility ?? this.mobility,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      highPriorityNotifications:
          highPriorityNotifications ?? this.highPriorityNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      fcmToken: fcmToken ?? this.fcmToken,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'age_group': ageGroup,
      'mobility': mobility,
      'notifications_enabled': notificationsEnabled,
      'high_priority_notifications': highPriorityNotifications,
      'sound_enabled': soundEnabled,
      'fcm_token': fcmToken,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String?,
      ageGroup: json['age_group'] as String? ?? '20~40대',
      mobility: json['mobility'] as String? ?? 'normal',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      highPriorityNotifications:
          json['high_priority_notifications'] as bool? ?? true,
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      fcmToken: json['fcm_token'] as String?,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
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

