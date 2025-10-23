import '../entities/user_profile.dart';

/// 사용자 리포지토리 인터페이스
abstract class UserRepository {
  /// 사용자 프로필 조회
  Future<UserProfile?> getUserProfile();

  /// 사용자 프로필 저장
  Future<void> saveUserProfile(UserProfile profile);

  /// FCM 토큰 업데이트
  Future<void> updateFcmToken(String token);

  /// 사용자 프로필 삭제
  Future<void> deleteUserProfile();
}

