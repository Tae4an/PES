import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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

/// 현재 위치의 주소 Provider
final currentAddressProvider = FutureProvider<String?>((ref) async {
  final location = await ref.watch(currentLocationProvider.future);
  
  if (location == null) return null;
  
  try {
    final placemarks = await placemarkFromCoordinates(
      location.latitude,
      location.longitude,
      localeIdentifier: 'ko_KR',
    );
    
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      
      // 한국식 주소 형식으로 조합
      final parts = <String>[];
      
      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        parts.add(place.administrativeArea!); // 시/도
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        parts.add(place.locality!); // 시/군/구
      }
      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        parts.add(place.subLocality!); // 동/읍/면
      }
      
      return parts.isNotEmpty ? parts.join(' ') : '주소를 찾을 수 없음';
    }
    
    return '주소를 찾을 수 없음';
  } catch (e) {
    print('주소 변환 오류: $e');
    return '주소를 찾을 수 없음';
  }
});

