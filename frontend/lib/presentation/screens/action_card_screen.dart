import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/constants.dart';
import '../providers/action_card_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/action_card_widget.dart';
import '../widgets/shelter_card_widget.dart';
import '../widgets/custom_buttons.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/error_card.dart';

/// 행동 카드 메인 화면
class ActionCardScreen extends ConsumerWidget {
  const ActionCardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionCardAsync = ref.watch(currentActionCardProvider);
    final locationAsync = ref.watch(currentLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('긴급 행동 카드'),
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      body: actionCardAsync.when(
        data: (actionCard) {
          if (actionCard == null) {
            return const Center(
              child: EmptyStateCard(
                message: '현재 활성화된 재난이 없습니다',
                icon: Icons.check_circle_outline,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentActionCardProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 행동 카드
                  ActionCardWidget(actionCard: actionCard),

                  const SizedBox(height: 24),

                  // 2. 지도
                  Text(
                    '🗺️ 주변 대피소',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),

                  locationAsync.when(
                    data: (location) => location != null
                        ? _MapWidget(
                            currentLocation: LatLng(
                              location.latitude,
                              location.longitude,
                            ),
                            shelters: actionCard.nearestShelters,
                          )
                        : const SizedBox.shrink(),
                    loading: () => Container(
                      height: AppConstants.mapHeight,
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, st) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),

                  // 3. 대피소 목록
                  Text(
                    '🚪 대피소 목록 (Top ${actionCard.nearestShelters.length})',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),

                  ...List.generate(
                    actionCard.nearestShelters.length,
                    (index) {
                      final shelter = actionCard.nearestShelters[index];
                      return ShelterCardWidget(
                        shelter: shelter,
                        index: index,
                        onNavigate: () => _launchNavigation(
                          shelter.latitude,
                          shelter.longitude,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // 4. 긴급 신고 버튼
                  EmergencyButton(
                    onPressed: () => _callEmergency(),
                  ),

                  const SizedBox(height: 12),

                  // 5. 돌아가기 버튼
                  const BackButtonCustom(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppConstants.paddingLarge),
            child: LoadingSkeletonList(),
          ),
        ),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: ErrorCard(
              error: e.toString(),
              onRetry: () => ref.invalidate(currentActionCardProvider),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchNavigation(double lat, double lng) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callEmergency() async {
    final url = Uri.parse('tel:${AppConstants.emergencyNumber}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

/// 지도 위젯
class _MapWidget extends StatefulWidget {
  final LatLng currentLocation;
  final List shelters;

  const _MapWidget({
    required this.currentLocation,
    required this.shelters,
  });

  @override
  State<_MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<_MapWidget> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  void _createMarkers() {
    // 현재 위치 마커
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: widget.currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: '현재 위치'),
      ),
    );

    // 대피소 마커
    for (int i = 0; i < widget.shelters.length; i++) {
      final shelter = widget.shelters[i];
      _markers.add(
        Marker(
          markerId: MarkerId('shelter_$i'),
          position: LatLng(shelter.latitude, shelter.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: shelter.name,
            snippet: '${shelter.walkingMinutes ?? 0}분',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.mapHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.currentLocation,
          zoom: AppConstants.defaultZoom,
        ),
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
        },
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

/// 빈 상태 카드 (재사용)
class EmptyStateCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyStateCard({
    Key? key,
    required this.message,
    this.icon = Icons.info_outline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingExtraLarge * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.safe,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

