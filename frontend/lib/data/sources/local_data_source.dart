import 'package:hive/hive.dart';
import '../../domain/entities/user_profile.dart';

/// 로컬 데이터 소스 (Hive)
class LocalDataSource {
  static const String _userBoxName = 'user_data';
  static const String _userProfileKey = 'user_profile';

  Future<Box> _getUserBox() async {
    if (!Hive.isBoxOpen(_userBoxName)) {
      return await Hive.openBox(_userBoxName);
    }
    return Hive.box(_userBoxName);
  }

  /// 사용자 프로필 저장
  Future<void> saveUserProfile(UserProfile profile) async {
    final box = await _getUserBox();
    await box.put(_userProfileKey, profile.toJson());
  }

  /// 사용자 프로필 조회
  Future<UserProfile?> getUserProfile() async {
    final box = await _getUserBox();
    final data = box.get(_userProfileKey);
    if (data == null) return null;
    
    // Map<dynamic, dynamic>을 Map<String, dynamic>으로 변환
    final Map<String, dynamic> jsonData = Map<String, dynamic>.from(data as Map);
    return UserProfile.fromJson(jsonData);
  }

  /// 사용자 프로필 삭제
  Future<void> deleteUserProfile() async {
    final box = await _getUserBox();
    await box.delete(_userProfileKey);
  }

  /// 특정 키 저장
  Future<void> saveValue(String key, dynamic value) async {
    final box = await _getUserBox();
    await box.put(key, value);
  }

  /// 특정 키 조회
  Future<T?> getValue<T>(String key) async {
    final box = await _getUserBox();
    return box.get(key) as T?;
  }

  /// 특정 키 삭제
  Future<void> deleteValue(String key) async {
    final box = await _getUserBox();
    await box.delete(key);
  }

  /// 모든 데이터 삭제
  Future<void> clearAll() async {
    final box = await _getUserBox();
    await box.clear();
  }
}

