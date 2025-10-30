import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// 디바이스 ID 유틸리티
class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// 디바이스 고유 ID 가져오기
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown-ios-${DateTime.now().millisecondsSinceEpoch}';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      }
      return 'unknown-device-${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      return 'error-device-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// 디바이스 정보 가져오기 (선택사항)
  static Future<Map<String, String>> getDeviceInfo() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'model': iosInfo.model,
          'systemVersion': iosInfo.systemVersion,
          'name': iosInfo.name,
        };
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
        };
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}

