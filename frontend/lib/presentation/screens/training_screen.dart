import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:confetti/confetti.dart';
import '../providers/training_provider.dart';
import '../providers/training_user_provider.dart';
import '../providers/rewards_provider.dart';
import '../widgets/main_layout.dart';
import '../../core/utils/logger.dart';
import '../../data/sources/training_api_service.dart';

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
  late ConfettiController _confettiController;
  final TrainingApiService _apiService = TrainingApiService();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
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
            )),
      };
    });
  }


  Future<void> _startTraining(Shelter shelter) async {
    final trainingUserProvider = context.read<TrainingUserProvider>();
    final trainingProvider = context.read<TrainingProvider>();

    AppLogger.i('훈련 시작 시도 - userId: ${trainingUserProvider.state.userId}, deviceId: ${trainingUserProvider.state.deviceId}');
    
    if (trainingUserProvider.state.userId == null) {
      AppLogger.e('로그인 정보 없음 - userId: ${trainingUserProvider.state.userId}');
      _showMessage('로그인이 필요합니다. 설정에서 로그아웃 후 다시 로그인하세요.');
      return;
    }

    try {
      // 한양대 ERICA 위치로 훈련 시작 (샌프란시스코 위치 무시)
      const hanyangLocation = LatLng(37.295692, 126.841425);
      
      // userId를 deviceId처럼 사용 (백엔드에서 device_id 파라미터로 받음)
      await trainingProvider.startTraining(
        deviceId: trainingUserProvider.state.deviceId ?? trainingUserProvider.state.userId!,
        shelter: shelter,
        currentLocation: hanyangLocation,
        onLocationCheck: (sessionId) => _checkLocation(sessionId),
      );

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

  // [개발자용] 자동 완료 트리거
  Future<void> _devAutoComplete() async {
    final trainingProvider = context.read<TrainingProvider>();
    final trainingUserProvider = context.read<TrainingUserProvider>();
    final sessionId = trainingProvider.state.currentSession?.sessionId;

    if (sessionId == null) {
      _showMessage('진행 중인 훈련이 없습니다');
      return;
    }

    try {
      final result = await _apiService.devAutoComplete(sessionId);
      
      // 상태 업데이트
      trainingProvider.resetTraining();
      trainingUserProvider.addPoints(result['points_earned']);
      context.read<RewardsProvider>().addPoints(result['points_earned']);
      
      // 축하 애니메이션 표시
      _confettiController.play();
      
      // 완료 다이얼로그 표시 (result 전달)
      _showCompletionDialogWithData(result);
    } catch (e) {
      AppLogger.e('자동 완료 실패: $e');
      _showMessage('자동 완료 실패: $e');
    }
  }

  void _showCompletionDialog() {
    final trainingProvider = context.read<TrainingProvider>();
    final pointsEarned = trainingProvider.state.pointsEarned ?? 0;

    // 포인트 업데이트
    context.read<TrainingUserProvider>().addPoints(pointsEarned);
    context.read<RewardsProvider>().addPoints(pointsEarned);

    // 축하 애니메이션
    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.celebration, size: 60, color: Colors.amber),
            const SizedBox(height: 8),
            const Text(
              '훈련 완료!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '대피소에 도착했습니다!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    '획득 포인트',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+$pointsEarned P',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                trainingProvider.resetTraining();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialogWithData(Map<String, dynamic> result) {
    final pointsEarned = result['points_earned'] ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.celebration, size: 60, color: Colors.amber),
            const SizedBox(height: 8),
            const Text(
              '훈련 완료!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '대피소에 도착했습니다!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    '획득 포인트',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+$pointsEarned P',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
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

  // 대피소 목록 UI
  Widget _buildShelterList(TrainingState state) {
    final shelters = state.nearbyShelters;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (shelters.isEmpty) {
      return const Center(
        child: Text(
          '주변에 대피소가 없습니다',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                '가까운 대피소 ${shelters.length}곳',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // 대피소 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: shelters.length,
            itemBuilder: (context, index) {
              final shelter = shelters[index];
              return _buildShelterCard(shelter, index + 1);
            },
          ),
        ),
      ],
    );
  }

  // 대피소 카드 (기존 UI 참고)
  Widget _buildShelterCard(Shelter shelter, int rank) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 순위 표시
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rank <= 3 ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: rank <= 3 ? Colors.green[700] : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // 대피소 정보
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
                      const SizedBox(height: 4),
                      Text(
                        shelter.address,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 거리 및 유형 정보
            Row(
              children: [
                Icon(Icons.directions_walk, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${shelter.distance.toStringAsFixed(0)}m',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.home, size: 16, color: Colors.grey[600]),
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
            
            const SizedBox(height: 12),
            
            // 훈련 시작 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startTraining(shelter),
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text(
                  '훈련 시작',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 훈련 상태 UI
  Widget _buildTrainingStatus(TrainingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_run, size: 60, color: Colors.blue),
          const SizedBox(height: 16),
          
          Text(
            '목표 대피소',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 6),
          Text(
            state.currentSession?.shelter.name ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            '남은 거리',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 6),
          Text(
            '${state.currentDistance.toStringAsFixed(0)}m',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 진행률
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 1 - (state.currentDistance / (state.currentSession?.initialDistance ?? 1)),
              minHeight: 16,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // [개발자용] 자동 완료 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _devAutoComplete,
              icon: const Icon(Icons.flash_on, color: Colors.white),
              label: const Text(
                '[DEV] 자동 완료',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 포기 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final trainingProvider = context.read<TrainingProvider>();
                await trainingProvider.abandonTraining();
                _showMessage('훈련을 포기했습니다');
              },
              icon: const Icon(Icons.close),
              label: const Text('훈련 포기'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
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
                Column(
                  children: [
                    // 상단: 지도 (화면의 40%)
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
                    
                    // 하단: 대피소 목록 또는 훈련 상태
                    Expanded(
                      child: Consumer<TrainingProvider>(
                        builder: (context, trainingProvider, _) {
                          final state = trainingProvider.state;

                          if (state.isTraining) {
                            // 훈련 중일 때
                            return _buildTrainingStatus(state);
                          } else {
                            // 대피소 목록
                            return _buildShelterList(state);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                
                // 축하 confetti
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.red,
                      Colors.blue,
                      Colors.green,
                      Colors.yellow,
                      Colors.purple,
                      Colors.orange,
                    ],
                    numberOfParticles: 30,
                    emissionFrequency: 0.05,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

