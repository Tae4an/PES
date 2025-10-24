import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/constants.dart';
import '../widgets/custom_buttons.dart';

/// 온보딩 화면 (권한 요청)
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _locationGranted = false;
  bool _notificationGranted = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingExtraLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // 아이콘
              Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // 제목
              Text(
                '🚨 긴급재난알림을 위해\n다음 권한이 필요합니다',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // 위치 권한
              _PermissionCard(
                icon: Icons.location_on,
                title: '📍 위치 권한',
                description: '현재 위치 기반 대피소 안내',
                isGranted: _locationGranted,
              ),
              const SizedBox(height: 16),

              // 알림 권한
              _PermissionCard(
                icon: Icons.notifications,
                title: '🔔 알림 권한',
                description: '긴급 대피 알림 수신',
                isGranted: _notificationGranted,
              ),
              const SizedBox(height: 48),

              // 권한 요청 버튼
              PrimaryActionButton(
                onPressed: _requestPermissions,
                label: '권한 요청 및 계속',
                icon: Icons.check,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 12),

              // 나중에 버튼
              SecondaryActionButton(
                onPressed: () => context.go('/home'),
                label: '나중에',
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    // 위치 권한 요청
    final locationStatus = await Permission.location.request();
    _locationGranted = locationStatus.isGranted;

    // 알림 권한 요청
    final notificationStatus = await Permission.notification.request();
    _notificationGranted = notificationStatus.isGranted;

    setState(() => _isLoading = false);

    // 모든 권한이 승인되면 홈으로 이동
    if (_locationGranted && _notificationGranted) {
      if (mounted) {
        context.go('/home');
      }
    } else {
      // 권한이 거부된 경우 안내 다이얼로그
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('권한 필요'),
        content: const Text(
          '일부 권한이 거부되었습니다.\n'
          '앱의 모든 기능을 사용하려면 권한을 허용해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isGranted
                  ? AppColors.safe
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isGranted)
              const Icon(
                Icons.check_circle,
                color: AppColors.safe,
              ),
          ],
        ),
      ),
    );
  }
}

