import 'dart:convert';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../config/env_config.dart';

class DirectionsService {
  // Google Maps API 키는 .env 파일에서 로드
  String get _apiKey => EnvConfig.googleMapsApiKey;
  
  final PolylinePoints _polylinePoints = PolylinePoints();

  /// 두 지점 간의 경로를 가져옵니다.
  /// 
  /// [origin] 출발지
  /// [destination] 목적지
  /// 
  /// Returns: 경로를 구성하는 LatLng 리스트, 실패 시 직선 경로 반환
  Future<List<LatLng>> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      // Directions API 호출
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=walking' // 걷기 모드
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          // Polyline 인코딩된 경로 데이터 추출
          final encodedPolyline = data['routes'][0]['overview_polyline']['points'];
          
          // Polyline 디코딩
          final decodedPoints = _polylinePoints.decodePolyline(encodedPolyline);
          
          // LatLng 리스트로 변환
          return decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        }
      }
      
      // API 실패 시 직선 경로 반환
      print('⚠️ Directions API 실패, 직선 경로 사용: ${response.statusCode}');
      return [origin, destination];
    } catch (e) {
      print('❌ Directions API 오류: $e');
      // 오류 발생 시 직선 경로 반환
      return [origin, destination];
    }
  }

  /// 경로의 총 거리(미터)를 계산합니다.
  double calculateDistance(List<LatLng> route) {
    if (route.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += _calculatePointDistance(route[i], route[i + 1]);
    }
    return totalDistance;
  }

  /// 두 점 사이의 거리를 계산합니다 (Haversine formula).
  double _calculatePointDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // 미터 단위
    
    final lat1Rad = point1.latitude * (math.pi / 180.0);
    final lat2Rad = point2.latitude * (math.pi / 180.0);
    final deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180.0);
    final deltaLonRad = (point2.longitude - point1.longitude) * (math.pi / 180.0);

    final a = math.sin(deltaLatRad / 2.0) * math.sin(deltaLatRad / 2.0) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLonRad / 2.0) * math.sin(deltaLonRad / 2.0);
    
    final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
    
    return earthRadius * c;
  }
}

