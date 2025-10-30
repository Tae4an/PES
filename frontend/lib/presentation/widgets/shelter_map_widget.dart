import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../providers/location_provider.dart';
import '../providers/shelter_provider.dart';

/// 대피소 지도 위젯 (재사용 가능)
class ShelterMapWidget extends ConsumerStatefulWidget {
  final bool showAppBar;
  
  const ShelterMapWidget({
    super.key,
    this.showAppBar = true,
  });

  @override
  ConsumerState<ShelterMapWidget> createState() => _ShelterMapWidgetState();
}

class _ShelterMapWidgetState extends ConsumerState<ShelterMapWidget> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  bool _markersInitialized = false;
  String _currentAddress = '주소를 불러오는 중...';

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    try {
      final placemarks = await placemarkFromCoordinates(
        37.295692,
        126.841425,
        localeIdentifier: 'ko_KR',
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _currentAddress = '${place.administrativeArea ?? ''} '
              '${place.locality ?? ''} '
              '${place.subLocality ?? ''}'
              .trim();
          
          if (_currentAddress.isEmpty) {
            _currentAddress = '경기도 안산시 상록구 사동';
          }
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = '경기도 안산시 상록구 사동';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(currentLocationProvider);

    return locationAsync.when(
      data: (location) {
        if (location == null) {
          return const Center(
            child: Text('위치 정보를 가져올 수 없습니다'),
          );
        }

        final currentLatLng = LatLng(location.latitude, location.longitude);

        final sheltersAsync = ref.watch(
          nearestSheltersProvider(NearestSheltersParams(
            latitude: 37.295692,
            longitude: 126.841425,
            limit: 10,
          )),
        );

        sheltersAsync.when(
          data: (shelters) {
            if (!_markersInitialized && shelters.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateMarkers(currentLatLng, shelters);
                _markersInitialized = true;
              });
            }
            return null;
          },
          loading: () => null,
          error: (_, __) => null,
        );

        return Column(
          children: [
            // 현재 위치 정보
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 20, color: AppColors.safe),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentAddress,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // 지도 영역
            Expanded(
              flex: 45,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(37.2970, 126.8373),
                      zoom: 15.0,
                    ),
                    markers: _markers,
                    circles: _circles,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      Future.delayed(const Duration(milliseconds: 500), () {
                        controller.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            const LatLng(37.2970, 126.8373),
                            15.0,
                          ),
                        );
                      });
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                  // 줌 컨트롤 버튼
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ZoomCircleButton(
                            icon: Icons.add,
                            onPressed: _zoomIn,
                          ),
                          const SizedBox(height: 10),
                          _ZoomCircleButton(
                            icon: Icons.remove,
                            onPressed: _zoomOut,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 대피소 목록 영역
            Expanded(
              flex: 40,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: sheltersAsync.when(
                  data: (shelters) {
                    if (shelters.isEmpty) {
                      return const Center(
                        child: Text('주변에 대피소가 없습니다'),
                      );
                    }
                    
                    final sortedShelters = List.from(shelters)
                      ..sort((a, b) => 
                        (a.distanceKm ?? double.infinity)
                          .compareTo(b.distanceKm ?? double.infinity));
                    final topShelters = sortedShelters.take(5).toList();
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            '가까운 대피소',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: topShelters.length,
                            itemBuilder: (context, index) {
                              final shelter = topShelters[index];
                              return _ShelterListItem(
                                shelter: shelter,
                                rank: index + 1,
                                onTap: () => _showShelterBottomSheet(shelter),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, st) => Center(
                    child: Text('대피소 정보를 불러올 수 없습니다\n$e'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (e, st) => Center(
        child: Text('오류: $e'),
      ),
    );
  }

  void _updateMarkers(LatLng currentLocation, List shelters) {
    setState(() {
      _markers.clear();

      // 현재 위치 마커
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentLocation,
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: const InfoWindow(title: '현재 위치'),
        ),
      );

      // 한양대 ERICA 마커
      _markers.add(
        Marker(
          markerId: const MarkerId('custom_location'),
          position: const LatLng(37.2970, 126.8373),
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: const InfoWindow(
            title: '한양대 ERICA',
            snippet: '탭하여 길찾기',
          ),
          onTap: () {
            _showCustomLocationBottomSheet(
              name: '한양대학교 ERICA 캠퍼스',
              address: '안산시 상록구 한양대학로 55',
              latitude: 37.2970,
              longitude: 126.8373,
            );
          },
        ),
      );

      // 대피소 마커
      for (int i = 0; i < shelters.length; i++) {
        final shelter = shelters[i];
        final uniqueId = 'shelter_${shelter.latitude}_${shelter.longitude}';
        _markers.add(
          Marker(
            markerId: MarkerId(uniqueId),
            position: LatLng(shelter.latitude, shelter.longitude),
            icon: BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: shelter.name,
              snippet:
                  '${shelter.type} · ${(shelter.distanceKm ?? 0).toStringAsFixed(2)}km · ${shelter.walkingMinutes ?? 0}분',
            ),
            onTap: () {
              _showShelterBottomSheet(shelter);
            },
          ),
        );
      }
    });
  }

  void _showShelterBottomSheet(shelter) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shelter.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              shelter.address,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(
                  icon: Icons.schedule,
                  label: '${shelter.walkingMinutes ?? 0}분',
                ),
                _InfoItem(
                  icon: Icons.people,
                  label: '${shelter.capacity}명',
                ),
                _InfoItem(
                  icon: Icons.location_on,
                  label: shelter.type,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _startNavigation(shelter.latitude, shelter.longitude);
                },
                icon: const Icon(Icons.navigation),
                label: const Text('네비게이션 시작'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomLocationBottomSheet({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.place,
                    color: Colors.purple,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _startNavigation(latitude, longitude);
                },
                icon: const Icon(Icons.navigation),
                label: const Text('길찾기 시작'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startNavigation(double latitude, double longitude) async {
    final currentLocation = await ref.read(currentLocationProvider.future);

    if (currentLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현재 위치를 가져올 수 없습니다')),
        );
      }
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${currentLocation.latitude},${currentLocation.longitude}'
      '&destination=$latitude,$longitude'
      '&travelmode=walking',
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('길찾기 실행 실패: $e')),
        );
      }
    }
  }

  Future<void> _zoomIn() async {
    if (_mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.zoomIn());
    }
  }

  Future<void> _zoomOut() async {
    if (_mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.zoomOut());
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _ZoomCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ZoomCircleButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ShelterListItem extends StatelessWidget {
  final shelter;
  final int rank;
  final VoidCallback onTap;

  const _ShelterListItem({
    required this.shelter,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final distanceKm = shelter.distanceKm ?? 0.0;
    final walkingMinutes = shelter.walkingMinutes ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: rank <= 3 
                    ? AppColors.safe.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: rank <= 3 ? AppColors.safe : Colors.grey[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shelter.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shelter.type,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.near_me,
                        size: 14,
                        color: AppColors.safe,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distanceKm.toStringAsFixed(2)}km',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.safe,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.directions_walk,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '도보 ${walkingMinutes}분',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

