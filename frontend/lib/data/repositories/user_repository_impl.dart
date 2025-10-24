import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../sources/local_data_source.dart';
import '../sources/remote_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final LocalDataSource _localDataSource;
  final RemoteDataSource _remoteDataSource;

  UserRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Future<UserProfile?> getUserProfile() async {
    try {
      return await _localDataSource.getUserProfile();
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _localDataSource.saveUserProfile(profile);
      
      // 서버에도 동기화 (선택적)
      if (profile.userId != null) {
        await _remoteDataSource.updateUser(
          profile.userId!,
          profile.toJson(),
        );
      }
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  @override
  Future<void> updateFcmToken(String token) async {
    try {
      final profile = await getUserProfile();
      if (profile == null) return;

      final updatedProfile = profile.copyWith(fcmToken: token);
      await saveUserProfile(updatedProfile);

      // 서버에 FCM 토큰 업데이트
      if (profile.userId != null) {
        await _remoteDataSource.updateFcmToken(
          profile.userId!,
          {'fcm_token': token},
        );
      }
    } catch (e) {
      throw Exception('Failed to update FCM token: $e');
    }
  }

  @override
  Future<void> deleteUserProfile() async {
    try {
      await _localDataSource.deleteUserProfile();
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }
}

