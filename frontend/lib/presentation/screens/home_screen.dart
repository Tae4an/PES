import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/constants.dart';
import '../providers/location_provider.dart';
import '../providers/disaster_provider.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/error_card.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/main_layout.dart';
import '../../core/services/fcm_service.dart';
import '../../core/network/dio_client.dart';

/// 홈 화면
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(currentLocationProvider);
    final activeDisasterAsync = ref.watch(activeDisasterStreamProvider);

    return MainLayout(
      currentIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PES'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(currentLocationProvider);
                ref.invalidate(activeDisasterStreamProvider);
              },
            ),
          ],
        ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentLocationProvider);
          ref.invalidate(activeDisasterStreamProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 현재 위치 섹션
              locationAsync.when(
                data: (location) => location != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '현재 위치',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '마지막 업데이트: 방금 전',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.grey,
                                ),
                          ),
                        ],
                      )
                    : Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: const Padding(
                          padding: EdgeInsets.all(AppConstants.paddingLarge),
                          child: Row(
                            children: [
                              Icon(Icons.location_off),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text('위치 정보를 가져올 수 없습니다'),
                              ),
                            ],
                          ),
                        ),
                      ),
                loading: () => const LoadingSkeletonCard(height: 80),
                error: (e, st) => ErrorCard(
                  error: e.toString(),
                  onRetry: () => ref.invalidate(currentLocationProvider),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // 활성 재난 경보 섹션
              Text(
                '활성 재난 경보',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              activeDisasterAsync.when(
                data: (disaster) => disaster != null
                    ? Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: InkWell(
                          onTap: () => context.push('/action-card'),
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusMedium),
                          child: Padding(
                            padding: const EdgeInsets.all(AppConstants.paddingLarge),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      DisasterTypeConfig.getConfig(disaster.type)
                                          .icon,
                                      color: Theme.of(context).colorScheme.error,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DisasterTypeConfig.getConfig(
                                                    disaster.type)
                                                .displayName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .error,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '발생지: ${disaster.location}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          Text(
                                            '심각도: ${disaster.severity}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.borderRadiusSmall),
                                  ),
                                  child: Text(
                                    disaster.message,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () =>
                                        context.push('/action-card'),
                                    icon: const Icon(Icons.shield),
                                    label: const Text('행동 카드 보기'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppConstants.paddingLarge),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 48,
                                color: AppColors.safe,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '현재 지역에 활성 경보 없음',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '위치 기반 알림이 활성화되어 있습니다',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                loading: () => const LoadingSkeletonCard(height: 200),
                error: (e, st) => ErrorCard(
                  error: e.toString(),
                  onRetry: () => ref.invalidate(activeDisasterStreamProvider),
                ),
              ),

              const SizedBox(height: 24),

              // 빠른 액션 섹션
              Text(
                '빠른 액션',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // 빠른 액션 그리드
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _QuickActionCard(
                    icon: Icons.shield_outlined,
                    label: '행동카드',
                    color: AppColors.critical,
                    onTap: () => context.push('/action-card'),
                  ),
                  _QuickActionCard(
                    icon: Icons.phone,
                    label: '긴급전화',
                    color: AppColors.warning,
                    onTap: () => _showEmergencyContacts(context),
                  ),
                  _QuickActionCard(
                    icon: Icons.favorite_outline,
                    label: '안전수칙',
                    color: AppColors.safe,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('준비 중입니다')),
                      );
                    },
                  ),
                ],
              ),
              
              // FCM 테스트 섹션 (개발용)
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'FCM 알림 테스트',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _testLocalNotification(context),
                      icon: const Icon(Icons.notifications),
                      label: const Text('로컬 알림 테스트'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _testServerNotification(context),
                      icon: const Icon(Icons.cloud),
                      label: const Text('서버 알림 테스트'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  /// 긴급 연락처 다이얼로그
  static void _showEmergencyContacts(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone, color: AppColors.critical),
            SizedBox(width: 8),
            Text('긴급 연락처'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.local_hospital, color: AppColors.critical),
              title: const Text('화재/응급'),
              trailing: const Text('119', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              onTap: () {
                // TODO: 전화 걸기 기능
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_police, color: Colors.blue),
              title: const Text('범죄/재난'),
              trailing: const Text('112', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              onTap: () {
                // TODO: 전화 걸기 기능
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  /// 로컬 알림 테스트 (앱 내 오버레이)
  void _testLocalNotification(BuildContext context) {
    NotificationService.showNotification(
      title: 'PES 테스트 알림',
      body: '이것은 앱 내 알림 테스트입니다. 실제 재난 상황에서는 중요한 대피 정보가 표시됩니다.',
      data: {
        'type': 'test',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('로컬 알림이 표시되었습니다!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 서버 FCM 알림 테스트
  void _testServerNotification(BuildContext context) async {
    try {
      // FCM 서비스 초기화
      final fcmService = FCMService(DioClient());
      
      // 임시 FCM 토큰 (실제로는 앱에서 생성된 토큰 사용)
      const mockToken = 'test_fcm_token_for_simulator';
      
      // 서버에 테스트 알림 요청
      final success = await fcmService.sendTestNotification(
        TestNotificationRequest(
          fcmToken: mockToken,
          title: 'PES 서버 테스트',
          body: 'Firebase FCM을 통한 푸시 알림 테스트입니다!',
        ),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('서버 알림 전송 성공! (실제 기기에서 확인 가능)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('서버 알림 전송 실패'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// 빠른 액션 카드 위젯
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

