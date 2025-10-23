import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

/// 위치 관리자
class LocationManager {
  final Logger _logger = Logger();

  /// 위치 권한 확인
  Future<bool> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// 위치 권한 요청
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _logger.w('위치 권한이 거부되었습니다');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _logger.e('위치 권한이 영구적으로 거부되었습니다');
      return false;
    }

    return true;
  }

  /// 위치 서비스 활성화 확인
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// 현재 위치 가져오기
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        final granted = await requestPermission();
        if (!granted) return null;
      }

      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('위치 서비스가 비활성화되어 있습니다');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _logger.e('현재 위치를 가져오는데 실패했습니다: $e');
      return null;
    }
  }

  /// 위치 스트림 (실시간 위치 추적)
  Stream<Position> getPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // 10미터 이상 이동 시 업데이트
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// 두 지점 간 거리 계산 (미터)
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// 두 지점 간 거리 계산 (킬로미터)
  double calculateDistanceInKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    final distanceInMeters = calculateDistance(
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
    );
    return distanceInMeters / 1000;
  }

  /// 걸어서 이동 시간 계산 (분)
  /// 평균 걷기 속도: 5km/h (약 83m/min)
  int calculateWalkingMinutes(double distanceKm) {
    const walkingSpeedKmPerHour = 5.0;
    final hours = distanceKm / walkingSpeedKmPerHour;
    final minutes = (hours * 60).ceil();
    return minutes;
  }
}

