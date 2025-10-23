import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/constants.dart';
import '../providers/location_provider.dart';
import '../providers/shelter_provider.dart';
import '../providers/disaster_provider.dart';

/// 지도 전체보기 화면
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(currentLocationProvider);
    final activeDisastersAsync = ref.watch(activeDisastersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('지도'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              locationAsync.whenData((location) {
                if (location != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(location.latitude, location.longitude),
                      AppConstants.defaultZoom,
                    ),
                  );
                }
              });
            },
          ),
        ],
      ),
      body: locationAsync.when(
        data: (location) {
          if (location == null) {
            return const Center(
              child: Text('위치 정보를 가져올 수 없습니다'),
            );
          }

          final currentLatLng = LatLng(location.latitude, location.longitude);

          // 대피소 정보 가져오기
          final sheltersAsync = ref.watch(
            nearestSheltersProvider(NearestSheltersParams(
              latitude: location.latitude,
              longitude: location.longitude,
              limit: 20,
            )),
          );

          sheltersAsync.whenData((shelters) {
            _updateMarkers(currentLatLng, shelters);
          });

          // 재난 위험 지역 표시
          activeDisastersAsync.whenData((disasters) {
            if (disasters.isNotEmpty) {
              _updateDisasterCircle(disasters.first);
            }
          });

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentLatLng,
              zoom: AppConstants.defaultZoom,
            ),
            markers: _markers,
            circles: _circles,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: true,
            onTap: (latLng) {
              // 지도 탭 시 마커 정보 닫기
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, st) => Center(
          child: Text('오류: $e'),
        ),
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
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
          infoWindow: const InfoWindow(title: '현재 위치'),
        ),
      );

      // 대피소 마커
      for (int i = 0; i < shelters.length; i++) {
        final shelter = shelters[i];
        _markers.add(
          Marker(
            markerId: MarkerId('shelter_${shelter.id}'),
            position: LatLng(shelter.latitude, shelter.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              i < 3 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: shelter.name,
              snippet: '${shelter.type} | ${shelter.walkingMinutes ?? 0}분',
            ),
            onTap: () {
              _showShelterBottomSheet(shelter);
            },
          ),
        );
      }
    });
  }

  void _updateDisasterCircle(disaster) {
    setState(() {
      _circles.clear();
      _circles.add(
        Circle(
          circleId: CircleId('disaster_${disaster.id}'),
          center: LatLng(disaster.latitude, disaster.longitude),
          radius: disaster.radiusKm * 1000, // km to meters
          fillColor: AppColors.critical.withValues(alpha: 0.2),
          strokeColor: AppColors.critical,
          strokeWidth: 2,
        ),
      );
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
                  // 네비게이션 실행
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
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
