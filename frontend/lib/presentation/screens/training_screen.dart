import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:confetti/confetti.dart';
import '../providers/training_provider.dart';
import '../providers/training_user_provider.dart';
import '../providers/rewards_provider.dart';
import '../widgets/main_layout.dart';
import '../../config/constants.dart';
import '../../core/utils/logger.dart';
import '../../data/sources/training_api_service.dart';
import '../../core/services/directions_service.dart';

/// 훈련 화면
class TrainingScreen extends StatefulWidget {
  const TrainingScreen({Key? key}) : super(key: key);

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  late ConfettiController _confettiController;
  final TrainingApiService _apiService = TrainingApiService();
  final DirectionsService _directionsService = DirectionsService();
  Timer? _autoMoveTimer;
  bool _isAutoMoving = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _autoMoveTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _currentLocation = const LatLng(37.295692, 126.841425);
      _isLoadingLocation = false;
    });
    
    if (mounted) {
      await context.read<TrainingProvider>().loadNearbyShelters(_currentLocation!);
      _updateMarkers();
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        final isInKorea = position.latitude >= 33 && position.latitude <= 43 &&
                          position.longitude >= 124 && position.longitude <= 132;
        
        if (isInKorea) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLng(_currentLocation!),
          );

          if (mounted) {
            await context.read<TrainingProvider>().loadNearbyShelters(_currentLocation!);
            _updateMarkers();
          }
          
          AppLogger.i('실제 GPS 위치로 업데이트: ${position.latitude}, ${position.longitude}');
        } else {
          AppLogger.i('GPS 위치가 한국 범위를 벗어남. 기본 위치(한양대 ERICA) 유지');
        }
      }
    } catch (e) {
      AppLogger.e('GPS 위치 가져오기 실패 (기본 위치 유지): $e');
    }
  }

  void _updateMarkers() {
    final trainingProvider = context.read<TrainingProvider>();
    final shelters = trainingProvider.state.nearbyShelters;

    setState(() {
      _markers = {
        if (_currentLocation != null)
          Marker(
            markerId: const MarkerId('current'),
            position: _currentLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: '내 위치'),
          ),
        ...shelters.map((shelter) => Marker(
              markerId: MarkerId(shelter.id),
              position: shelter.position,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              infoWindow: InfoWindow(
                title: shelter.name,
                snippet: '${shelter.distance.toStringAsFixed(0)}m',
              ),
            )),
      };
    });
  }

  Future<void> _updateTrainingRoute(LatLng destination) async {
    if (_currentLocation == null) return;

    // 마커 먼저 설정
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('current'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: '내 위치'),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: '목표 대피소'),
        ),
      };
    });

    try {
      // Google Directions API로 실제 도로 경로 가져오기
      AppLogger.i('🗺️ 실제 도로 경로 가져오는 중...');
      final routePoints = await _directionsService.getRoute(
        origin: _currentLocation!,
        destination: destination,
      );
      
      final distance = _directionsService.calculateDistance(routePoints);
      AppLogger.i('✅ 경로 로드 완료: ${routePoints.length}개 포인트, 총 ${distance.toStringAsFixed(0)}m');

      setState(() {
        // 실제 도로 경로를 따라 Polyline 표시
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: AppColors.safe,
            width: 6,
            patterns: [PatternItem.dash(20), PatternItem.gap(15)],
            geodesic: true,
          ),
        };
      });

      // 지도 카메라를 경로가 모두 보이도록 조정
      if (routePoints.length >= 2) {
        final bounds = _calculateBounds(routePoints);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 80),
        );
      }
    } catch (e) {
      AppLogger.e('❌ 경로 로드 실패: $e');
      // 실패 시 직선 경로 표시
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [_currentLocation!, destination],
            color: AppColors.safe,
            width: 5,
            patterns: [PatternItem.dash(30), PatternItem.gap(20)],
          ),
        };
      });
    }
  }

  /// 경로의 모든 지점을 포함하는 LatLngBounds 계산
  LatLngBounds _calculateBounds(List<LatLng> points) {
    double south = points.first.latitude;
    double north = points.first.latitude;
    double west = points.first.longitude;
    double east = points.first.longitude;

    for (var point in points) {
      if (point.latitude < south) south = point.latitude;
      if (point.latitude > north) north = point.latitude;
      if (point.longitude < west) west = point.longitude;
      if (point.longitude > east) east = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  Future<void> _startTraining(Shelter shelter) async {
    final trainingUserProvider = context.read<TrainingUserProvider>();
    final trainingProvider = context.read<TrainingProvider>();

    AppLogger.i('훈련 시작 시도 - userId: ${trainingUserProvider.state.userId}, deviceId: ${trainingUserProvider.state.deviceId}');
    
    if (trainingUserProvider.state.userId == null) {
      AppLogger.e('로그인 정보 없음');
      _showMessage('로그인이 필요합니다');
      return;
    }

    try {
      const hanyangLocation = LatLng(37.295692, 126.841425);
      
      await trainingProvider.startTraining(
        deviceId: trainingUserProvider.state.deviceId ?? trainingUserProvider.state.userId!,
        shelter: shelter,
        currentLocation: hanyangLocation,
        onLocationCheck: (sessionId) => _checkLocation(sessionId),
      );

      // 경로 표시
      _updateTrainingRoute(shelter.position);
      
      _showMessage('훈련을 시작했습니다!');
    } catch (e) {
      AppLogger.e('훈련 시작 실패: $e');
      _showMessage('훈련 시작 실패: $e');
    }
  }

  Future<void> _checkLocation(int sessionId) async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final currentLocation = LatLng(position.latitude, position.longitude);

      if (mounted) {
        await context.read<TrainingProvider>().checkCompletion(
              sessionId: sessionId,
              currentLocation: currentLocation,
            );

        final trainingProvider = context.read<TrainingProvider>();
        if (trainingProvider.state.isCompleted) {
          _showCompletionDialog();
        }
      }
    } catch (e) {
      AppLogger.e('위치 확인 실패: $e');
    }
  }

  // 자동 완료 트리거
  Future<void> _devAutoComplete() async {
    final trainingProvider = context.read<TrainingProvider>();
    final session = trainingProvider.state.currentSession;

    if (session == null) {
      _showMessage('진행 중인 훈련이 없습니다');
      return;
    }

    if (_isAutoMoving) {
      _showMessage('이미 자동 이동 중입니다');
      return;
    }

    setState(() {
      _isAutoMoving = true;
    });

    _showMessage('목적지까지 자동 이동을 시작합니다 (5m/초)');

    // 목적지 위치
    final destination = session.shelter.position;
    
    // 0.5초마다 5m씩 이동
    _autoMoveTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!mounted || !_isAutoMoving) {
        timer.cancel();
        return;
      }

      if (_currentLocation == null) {
        timer.cancel();
        setState(() {
          _isAutoMoving = false;
        });
        return;
      }

      // 현재 위치에서 목적지까지의 거리 계산
      final distance = _directionsService.calculateDistance([
        _currentLocation!,
        destination,
      ]);

      AppLogger.i('🚶 자동 이동 중: 남은 거리 ${distance.toStringAsFixed(0)}m');

      // 목적지에 거의 도착했으면 (10m 이내) 정확히 목적지로 이동하고 완료
      if (distance <= 10) {
        timer.cancel();
        setState(() {
          _currentLocation = destination;
          _isAutoMoving = false;
        });

        // 마커 업데이트
        _updateMarkersForSimulation(destination);

        // 완료 처리
        await _completeTrainingSimulation();
        return;
      }

      // 5m 이동 (목적지 방향으로)
      final bearing = _calculateBearing(_currentLocation!, destination);
      final newLocation = _moveTowards(_currentLocation!, bearing, 5.0);

      setState(() {
        _currentLocation = newLocation;
      });

      // 마커 업데이트
      _updateMarkersForSimulation(destination);

      // 지도 카메라 이동
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(newLocation),
      );
    });
  }

  /// 시뮬레이션용 마커 업데이트
  void _updateMarkersForSimulation(LatLng destination) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('current'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: '내 위치'),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: '목표 대피소'),
        ),
      };
    });
  }

  /// 시뮬레이션 훈련 완료
  Future<void> _completeTrainingSimulation() async {
    final trainingProvider = context.read<TrainingProvider>();
    final trainingUserProvider = context.read<TrainingUserProvider>();
    final sessionId = trainingProvider.state.currentSession?.sessionId;

    if (sessionId == null) return;

    try {
      final result = await _apiService.devAutoComplete(sessionId);
      
      trainingProvider.resetTraining();
      trainingUserProvider.addPoints(result['points_earned']);
      context.read<RewardsProvider>().addPoints(result['points_earned']);
      
      _confettiController.play();
      _showCompletionDialogWithData(result);
      
      _showMessage('훈련 완료!');
    } catch (e) {
      AppLogger.e('자동 완료 실패: $e');
      _showMessage('자동 완료 실패: $e');
    }
  }

  /// 두 지점 간의 방위각 계산 (degrees)
  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * (math.pi / 180.0);
    final lat2 = to.latitude * (math.pi / 180.0);
    final dLon = (to.longitude - from.longitude) * (math.pi / 180.0);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    return (bearing * 180.0 / math.pi + 360.0) % 360.0;
  }

  /// 특정 방향으로 일정 거리만큼 이동한 새 위치 계산
  LatLng _moveTowards(LatLng from, double bearing, double distanceMeters) {
    const double earthRadius = 6371000.0; // 미터
    final double lat1 = from.latitude * (math.pi / 180.0);
    final double lon1 = from.longitude * (math.pi / 180.0);
    final double brng = bearing * (math.pi / 180.0);

    final double lat2 = math.asin(
      math.sin(lat1) * math.cos(distanceMeters / earthRadius) +
      math.cos(lat1) * math.sin(distanceMeters / earthRadius) * math.cos(brng),
    );

    final double lon2 = lon1 +
        math.atan2(
          math.sin(brng) * math.sin(distanceMeters / earthRadius) * math.cos(lat1),
          math.cos(distanceMeters / earthRadius) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(
      lat2 * (180.0 / math.pi),
      lon2 * (180.0 / math.pi),
    );
  }

  void _showCompletionDialog() {
    final trainingProvider = context.read<TrainingProvider>();
    final pointsEarned = trainingProvider.state.pointsEarned ?? 0;
    final session = trainingProvider.state.currentSession;
    
    // 실제 이동한 거리 = 초기 거리 (시작점에서 대피소까지의 거리)
    final distance = session?.initialDistance ?? 0;
    final duration = session?.duration ?? const Duration(seconds: 0);
    
    AppLogger.i('훈련 완료 다이얼로그 - 거리: ${distance}m, 포인트: $pointsEarned');

    context.read<TrainingUserProvider>().addPoints(pointsEarned);
    context.read<RewardsProvider>().addPoints(pointsEarned);

    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.safe.withOpacity(0.1),
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 성공 아이콘
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.safe, AppColors.safe.withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.safe.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                // 제목
                const Text(
                  '훈련 완료! 🎉',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '대피소에 무사히 도착했습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // 통계 카드
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.directions_walk,
                        label: '이동 거리',
                        value: '${distance.toStringAsFixed(0)}m',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.timer,
                        label: '소요 시간',
                        value: duration.inMinutes > 0
                            ? '${duration.inMinutes}분 ${duration.inSeconds % 60}초'
                            : '${duration.inSeconds}초',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // 포인트 획득
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.safe, AppColors.safe.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.safe.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '획득 포인트',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.diamond, color: Colors.white, size: 32),
                          const SizedBox(width: 8),
                          Text(
                            '+$pointsEarned P',
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // 확인 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      trainingProvider.resetTraining();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safe,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '완료',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialogWithData(Map<String, dynamic> result) {
    final pointsEarned = result['points_earned'] ?? 0;
    final distance = result['distance'] ?? 0.0;
    final durationSeconds = result['duration'] ?? 0;
    final duration = Duration(seconds: durationSeconds is int ? durationSeconds : 0);
    
    // 세션이 있으면 실제 경과 시간 사용
    final session = context.read<TrainingProvider>().state.currentSession;
    final actualDuration = session?.duration ?? duration;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.safe.withOpacity(0.1),
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 성공 아이콘
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.safe, AppColors.safe.withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.safe.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                // 제목
                const Text(
                  '훈련 완료!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '대피소에 무사히 도착했습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // 통계 카드
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.directions_walk,
                        label: '이동 거리',
                        value: '${distance.toStringAsFixed(0)}m',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.timer,
                        label: '소요 시간',
                        value: actualDuration.inMinutes > 0
                            ? '${actualDuration.inMinutes}분 ${actualDuration.inSeconds % 60}초'
                            : '${actualDuration.inSeconds}초',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // 포인트 획득
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.safe, AppColors.safe.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.safe.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '획득 포인트',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.diamond, color: Colors.white, size: 32),
                          const SizedBox(width: 8),
                          Text(
                            '+$pointsEarned P',
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // 확인 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<TrainingProvider>().resetTraining();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safe,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '완료',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStartTrainingDialog(Shelter shelter) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.safe, AppColors.safe.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_run,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              
              // 제목
              const Text(
                '훈련을 시작하시겠습니까?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // 대피소 정보
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.safe.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shelter.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.directions_walk, size: 14, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${shelter.distance.toStringAsFixed(0)}m',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.home_outlined, size: 14, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            shelter.type,
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 버튼
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startTraining(shelter);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.safe,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '시작',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 1,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('대피소 훈련'),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            Consumer<TrainingUserProvider>(
              builder: (context, trainingUserProvider, _) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.danger.withOpacity(0.8), AppColors.dangerDark],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.diamond, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${trainingUserProvider.state.totalPoints}P',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: _isLoadingLocation
            ? const Center(child: CircularProgressIndicator())
            : Consumer<TrainingProvider>(
                builder: (context, trainingProvider, _) {
                  final state = trainingProvider.state;

                  if (state.isTraining) {
                    return _buildTrainingView(state);
                  } else {
                    return _buildShelterListView(state);
                  }
                },
              ),
      ),
    );
  }

  Widget _buildShelterListView(TrainingState state) {
    return Stack(
      children: [
        Column(
          children: [
            // 지도 (상단 35%)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: _currentLocation != null
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentLocation!,
                        zoom: 15,
                      ),
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                    )
                  : const Center(child: Text('위치 로딩 중...')),
            ),

            // 대피소 목록
            Expanded(
              child: _buildShelterList(state),
            ),
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange],
            numberOfParticles: 30,
            emissionFrequency: 0.05,
          ),
        ),
      ],
    );
  }

  Widget _buildShelterList(TrainingState state) {
    final shelters = state.nearbyShelters;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (shelters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('주변에 대피소가 없습니다', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.safe.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on, color: AppColors.safe, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                '가까운 대피소 ${shelters.length}곳',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shelters.length,
            itemBuilder: (context, index) {
              final shelter = shelters[index];
              return _buildModernShelterCard(shelter, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernShelterCard(Shelter shelter, int rank) {
    final isTopRanked = rank <= 3;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showStartTrainingDialog(shelter),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 순위 배지
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isTopRanked
                          ? [AppColors.safe, AppColors.safe.withOpacity(0.8)]
                          : [Colors.grey[400]!, Colors.grey[300]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shelter.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.directions_walk, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${shelter.distance.toStringAsFixed(0)}m',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.home_outlined, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shelter.type,
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 화살표
                Icon(Icons.chevron_right, color: AppColors.safe),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingView(TrainingState state) {
    return Stack(
      children: [
        Column(
          children: [
            // 지도 (상단 40%)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: _currentLocation != null
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentLocation!,
                        zoom: 15,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),

            // 진행 정보 카드
            Expanded(
              child: Container(
                color: const Color(0xFFF5F7FA),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 목표 대피소 카드
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.safe, AppColors.safe.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '목표 대피소',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    state.currentSession?.shelter.name ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 거리 정보 카드
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text('남은 거리', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text(
                              '${state.currentDistance.toStringAsFixed(0)}m',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppColors.safe,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: 1 - (state.currentDistance / (state.currentSession?.initialDistance ?? 1)),
                                minHeight: 10,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.safe),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '시작: ${state.currentSession?.initialDistance.toStringAsFixed(0)}m',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const Text(
                                  '목표: 0m',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 포기 버튼
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final trainingProvider = context.read<TrainingProvider>();
                            await trainingProvider.abandonTraining();
                            setState(() {
                              _polylines.clear();
                            });
                            _updateMarkers();
                            _showMessage('훈련을 포기했습니다');
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('훈련 포기', style: TextStyle(fontSize: 16)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.red, width: 1.5),
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 테스트용 자동 완료 버튼 (작게)
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _devAutoComplete,
                          icon: const Icon(Icons.flash_on, size: 16),
                          label: const Text('[테스트] 자동 완료', style: TextStyle(fontSize: 13)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange],
            numberOfParticles: 30,
            emissionFrequency: 0.05,
          ),
        ),
      ],
    );
  }
}
