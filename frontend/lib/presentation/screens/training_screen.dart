import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/training_provider.dart';
import '../providers/training_user_provider.dart';
import '../providers/rewards_provider.dart';
import '../widgets/main_layout.dart';
import '../../core/utils/logger.dart';

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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    // 먼저 기본 위치(한양대 ERICA)로 설정
    setState(() {
      _currentLocation = const LatLng(37.295692, 126.841425);
      _isLoadingLocation = false;
    });
    
    // 대피소 로드
    if (mounted) {
      await context.read<TrainingProvider>().loadNearbyShelters(_currentLocation!);
      _updateMarkers();
    }

    // 그 다음 실제 GPS 위치 가져오기 시도 (한국 내에서만)
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
        
        // 한국 범위 내에 있는지 확인 (위도: 33-43, 경도: 124-132)
        final isInKorea = position.latitude >= 33 && position.latitude <= 43 &&
                          position.longitude >= 124 && position.longitude <= 132;
        
        if (isInKorea) {
          // GPS 위치로 업데이트 (한국 내에서만)
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
          });

          // 카메라 이동
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(_currentLocation!),
          );

          // 새 위치 기반 대피소 로드
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
        // 현재 위치 마커
        if (_currentLocation != null)
          Marker(
            markerId: const MarkerId('current'),
            position: _currentLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: '내 위치'),
          ),
        // 대피소 마커들
        ...shelters.map((shelter) => Marker(
              markerId: MarkerId(shelter.id),
              position: shelter.position,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(
                title: shelter.name,
                snippet: '${shelter.distance.toStringAsFixed(0)}m',
              ),
              onTap: () => _showShelterBottomSheet(shelter),
            )),
      };
    });
  }

  void _showShelterBottomSheet(Shelter shelter) {
    final trainingProvider = context.read<TrainingProvider>();
    final isTraining = trainingProvider.state.isTraining;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shelter.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(shelter.address),
            const SizedBox(height: 4),
            Text(
              '${shelter.distance.toStringAsFixed(0)}m 떨어짐',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isTraining
                    ? null
                    : () {
                        Navigator.pop(context);
                        _startTraining(shelter);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isTraining ? '훈련 진행 중...' : '훈련 시작',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startTraining(Shelter shelter) async {
    final trainingUserProvider = context.read<TrainingUserProvider>();
    final trainingProvider = context.read<TrainingProvider>();

    if (trainingUserProvider.state.deviceId == null || _currentLocation == null) {
      _showMessage('로그인이 필요합니다');
      return;
    }

    try {
      await trainingProvider.startTraining(
        deviceId: trainingUserProvider.state.deviceId!,
        shelter: shelter,
        currentLocation: _currentLocation!,
        onLocationCheck: (sessionId) => _checkLocation(sessionId),
      );

      _showMessage('훈련을 시작했습니다!');
    } catch (e) {
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

        // 완료 여부 확인
        final trainingProvider = context.read<TrainingProvider>();
        if (trainingProvider.state.isCompleted) {
          _showCompletionDialog();
        }
      }
    } catch (e) {
      AppLogger.e('위치 확인 실패: $e');
    }
  }

  void _showCompletionDialog() {
    final trainingProvider = context.read<TrainingProvider>();
    final pointsEarned = trainingProvider.state.pointsEarned ?? 0;

    // 포인트 업데이트
    context.read<TrainingUserProvider>().addPoints(pointsEarned);
    context.read<RewardsProvider>().addPoints(pointsEarned);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 훈련 완료!'),
        content: Text('축하합니다!\n$pointsEarned 포인트를 획득했습니다!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              trainingProvider.resetTraining();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 1, // 훈련 탭
      child: Scaffold(
        appBar: AppBar(
          title: const Text('대피소 훈련'),
          automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
          actions: [
            Consumer<TrainingUserProvider>(
              builder: (context, trainingUserProvider, _) {
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Center(
                    child: Text(
                      '💎 ${trainingUserProvider.state.totalPoints}P',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // 지도
                if (_currentLocation != null)
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation!,
                      zoom: 16, // 더 가까운 줌 레벨
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                  ),

                // 훈련 상태 표시
                Consumer<TrainingProvider>(
                  builder: (context, trainingProvider, _) {
                    final state = trainingProvider.state;

                    if (!state.isTraining) return const SizedBox.shrink();

                    return Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '🎯 목표: ${state.currentSession?.shelter.name}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '남은 거리: ${state.currentDistance.toStringAsFixed(0)}m',
                                style: const TextStyle(fontSize: 24, color: Colors.blue),
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: 1 - (state.currentDistance / (state.currentSession?.initialDistance ?? 1)),
                                minHeight: 8,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await trainingProvider.abandonTraining();
                                        _showMessage('훈련을 포기했습니다');
                                      },
                                      child: const Text('포기하기'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
      ),
    );
  }
}

