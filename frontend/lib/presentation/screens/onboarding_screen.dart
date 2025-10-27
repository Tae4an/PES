import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  void initState() {
    super.initState();
    _checkPermissionsStatus();
  }

  /// 초기 상태에서 권한 상태 확인
  Future<void> _checkPermissionsStatus() async {
    final locationStatus = await Permission.location.status;
    final notificationStatus = await Permission.notification.status;
    
    setState(() {
      _locationGranted = locationStatus.isGranted;
      _notificationGranted = notificationStatus.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingExtraLarge,
            vertical: AppConstants.paddingMedium,
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          MediaQuery.of(context).padding.bottom - 
                          AppConstants.paddingMedium * 2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // 아이콘
                  Icon(
                    Icons.shield_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 32),

                  // 제목
                  Text(
                    '긴급재난알림을 위해\n다음 권한이 필요합니다',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 56),

                  // 위치 권한
                  _PermissionCard(
                    icon: Icons.location_on,
                    title: '위치 권한',
                    description: '현재 위치 기반 대피소 안내',
                    isGranted: _locationGranted,
                  ),
                  const SizedBox(height: 20),

                  // 알림 권한
                  _PermissionCard(
                    icon: Icons.notifications,
                    title: '알림 권한',
                    description: '긴급 대피 알림 수신',
                    isGranted: _notificationGranted,
                  ),
                  const SizedBox(height: 60),

                  // 권한 요청 버튼
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _requestPermissions,
                      icon: const Icon(Icons.check),
                      label: const Text('권한 요청 및 계속'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 나중에 버튼
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('나중에'),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    try {
      // 위치 권한 요청
      final locationStatus = await Permission.location.request();
      _locationGranted = locationStatus.isGranted;

      // 알림 권한 요청
      final notificationStatus = await Permission.notification.request();
      _notificationGranted = notificationStatus.isGranted;

      // 권한 허용 여부를 SharedPreferences에 저장
      await _savePermissionsStatus();

      setState(() => _isLoading = false);

      // 권한이 모두 승인되면 홈으로 이동
      if (_locationGranted && _notificationGranted) {
        if (mounted) {
          context.go('/home');
        }
      } else {
        // 일부 권한만 승인된 경우 안내 다이얼로그
        if (mounted) {
          _showPermissionDialog();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('권한 요청 중 오류 발생: $e')),
        );
      }
    }
  }

  /// 권한 허용 상태를 저장
  Future<void> _savePermissionsStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setBool('location_permission_granted', _locationGranted);
    await prefs.setBool('notification_permission_granted', _notificationGranted);
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('권한 필요'),
        content: const Text(
          '일부 권한이 거부되었습니다.\n'
          '앱의 모든 기능을 사용하려면 권한을 허용해주세요.\n\n'
          '원하시면 설정으로 이동하여 권한을 변경할 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child: const Text('나중에'),
          ),
          FilledButton(
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isGranted
                    ? AppColors.safe.withOpacity(0.1)
                    : Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isGranted
                    ? AppColors.safe
                    : Theme.of(context).colorScheme.primary,
              ),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (isGranted)
              Icon(
                Icons.check_circle,
                color: AppColors.safe,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

