/// API 엔드포인트 상수
class ApiEndpoints {
  ApiEndpoints._();

  // Base
  static const String apiVersion = 'v1';
  static const String base = '/api/$apiVersion';

  // Disasters
  static const String disasters = '$base/disasters';
  static const String activeDisaster = '$disasters/active';
  static const String nearbyDisasters = '$disasters/nearby';

  // Shelters
  static const String shelters = '$base/shelters';
  static const String nearestShelters = '$shelters/nearest';
  static const String shelterById = '$shelters/{id}';
  static const String searchShelters = '$shelters/search';

  // Action Cards
  static const String actionCards = '$base/action-cards';
  static const String generateActionCard = '$actionCards/generate';

  // FCM
  static const String fcm = '$base/fcm';
  static const String registerFcmToken = '$fcm/token/register';
  static const String testNotification = '$fcm/test/notification';
  static const String fcmStatus = '$fcm/status';

  // Users
  static const String users = '$base/users';
  static const String registerUser = '$users/register';
  static const String updateUser = '$users/{userId}';
  static const String updateFcmToken = '$users/{userId}/fcm-token';

  // Health
  static const String health = '$base/health';
}

