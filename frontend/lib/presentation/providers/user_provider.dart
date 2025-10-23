import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/sources/local_data_source.dart';
import 'disaster_provider.dart';

/// LocalDataSource Provider
final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  return LocalDataSource();
});

/// UserRepository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final localDataSource = ref.watch(localDataSourceProvider);
  final remoteDataSource = ref.watch(remoteDataSourceProvider);
  return UserRepositoryImpl(localDataSource, remoteDataSource);
});

/// 사용자 프로필 Provider
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return await repository.getUserProfile();
});

/// 사용자 프로필 StateNotifier
class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final UserRepository _repository;

  UserProfileNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getUserProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveUserProfile(profile);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateFcmToken(String token) async {
    try {
      await _repository.updateFcmToken(token);
      await _loadUserProfile();
    } catch (e) {
      // 에러 처리
    }
  }

  Future<void> deleteProfile() async {
    try {
      await _repository.deleteUserProfile();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadUserProfile();
  }
}

/// UserProfileNotifier Provider
final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UserProfileNotifier(repository);
});

