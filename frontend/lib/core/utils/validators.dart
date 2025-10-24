/// 유효성 검사 유틸리티
class Validators {
  Validators._();

  /// 이메일 유효성 검사
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// 전화번호 유효성 검사 (한국)
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(
      r'^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$',
    );
    return phoneRegex.hasMatch(phone);
  }

  /// 빈 문자열 검사
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// 최소 길이 검사
  static bool hasMinLength(String? value, int minLength) {
    return value != null && value.length >= minLength;
  }

  /// 최대 길이 검사
  static bool hasMaxLength(String? value, int maxLength) {
    return value != null && value.length <= maxLength;
  }

  /// 숫자만 포함 검사
  static bool isNumeric(String? value) {
    if (value == null) return false;
    return double.tryParse(value) != null;
  }

  /// 위도 유효성 검사
  static bool isValidLatitude(double? latitude) {
    if (latitude == null) return false;
    return latitude >= -90 && latitude <= 90;
  }

  /// 경도 유효성 검사
  static bool isValidLongitude(double? longitude) {
    if (longitude == null) return false;
    return longitude >= -180 && longitude <= 180;
  }
}

