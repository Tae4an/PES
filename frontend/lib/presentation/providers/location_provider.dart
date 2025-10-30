import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/location/location_manager.dart';

/// LocationManager Provider
final locationManagerProvider = Provider<LocationManager>((ref) {
  return LocationManager();
});

/// 현재 위치 Provider (FutureProvider) - 한양대 ERICA 고정
final currentLocationProvider = FutureProvider<Position?>((ref) async {
  // 테스트용 고정 위치: 한양대 ERICA
  return Position(
    latitude: 37.295692,
    longitude: 126.841425,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
  
  // 실제 위치 사용 시:
  // final locationManager = ref.watch(locationManagerProvider);
  // return await locationManager.getCurrentPosition();
});

/// 위치 스트림 Provider (실시간 위치)
final locationStreamProvider = StreamProvider<Position>((ref) {
  final locationManager = ref.watch(locationManagerProvider);
  return locationManager.getPositionStream();
});

/// 위치 권한 상태 Provider
final locationPermissionProvider = FutureProvider<bool>((ref) async {
  final locationManager = ref.watch(locationManagerProvider);
  return await locationManager.checkPermission();
});

/// 위치 서비스 활성화 여부 Provider
final locationServiceEnabledProvider = FutureProvider<bool>((ref) async {
  final locationManager = ref.watch(locationManagerProvider);
  return await locationManager.isLocationServiceEnabled();
});

