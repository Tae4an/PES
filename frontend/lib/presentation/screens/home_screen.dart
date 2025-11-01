import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../providers/location_provider.dart';
import '../providers/disaster_provider.dart';
import '../providers/test_mode_provider.dart';
import '../providers/test_disaster_provider.dart';
import '../providers/action_card_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/error_card.dart';
import '../widgets/main_layout.dart';
import '../widgets/action_card_widget.dart';
import '../widgets/shelter_map_widget.dart';
import '../../core/notifications/notification_handler.dart';

/// 홈 화면
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDisasterAsync = ref.watch(activeDisasterStreamProvider);
    final testMode = ref.watch(testModeProvider);
    final testDisaster = ref.watch(testDisasterProvider);
    final locationAsync = ref.watch(currentLocationProvider);
    final addressAsync = ref.watch(currentAddressProvider);

    // 테스트 모드일 때는 testActionCardProvider, 아니면 currentActionCardProvider
    final actionCardAsync = testMode
        ? ref.watch(testActionCardProvider)
        : ref.watch(currentActionCardProvider);

    return MainLayout(
      currentIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PES'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push('/notifications'),
            ),
            // Mock Push 버튼 (시뮬레이터에서 로컬 알림 테스트)
            IconButton(
              tooltip: 'Mock Push',
              icon: const Icon(Icons.notifications_active),
              onPressed: () async {
                await NotificationHandler.showLocalNotification(
                  title: '🚨 [테스트] 재난 경보',
                  body: '시뮬레이터용 Mock Push입니다. 실제 FCM처럼 표시됩니다.',
                );
              },
            ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 상단 상태 헤더 (그라데이션 배경)
                _buildStatusHeader(
                  context,
                  activeDisasterAsync,
                  locationAsync,
                  addressAsync,
                  testMode,
                  testDisaster,
                ),

                // 메인 컨텐츠 영역
                Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 테스트 모드 시나리오 버튼
                      if (testMode) ...[
                        _buildTestModeControls(context, ref),
                        const SizedBox(height: 16),
                      ],

                      // 테스트 모드 재난 정보 표시
                      if (testMode && testDisaster != null) ...[
                        _buildTestDisasterCard(context, testDisaster),
                        const SizedBox(height: 16),
                      ],

                      // 테스트 모드 액션 카드 표시
                      if (testMode)
                        actionCardAsync.when(
                          data: (actionCard) {
                            if (actionCard != null) {
                              return Column(
                                children: [
                                  ActionCardWidget(actionCard: actionCard),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 8),
                                    Text('행동 카드 생성 중...'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          error: (e, st) => Card(
                            color: AppColors.critical.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('오류: $e'),
                            ),
                          ),
                        ),

                      // 활성 재난 경보 섹션 (테스트 모드가 아닐 때) - 위로 이동
                      if (!testMode) ...[
                        activeDisasterAsync.when(
                          data: (disaster) => disaster != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildActiveDisasterCard(context, disaster),
                                    const SizedBox(height: 24),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSafeCard(context),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                          loading: () => Column(
                            children: [
                              const LoadingSkeletonCard(height: 200),
                              const SizedBox(height: 24),
                            ],
                          ),
                          error: (e, st) => Column(
                            children: [
                              ErrorCard(
                                error: e.toString(),
                                onRetry: () => ref
                                    .invalidate(activeDisasterStreamProvider),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],

                      // 퀵 액션 그리드 (재난 카드 아래로 이동)
                      if (!testMode) ...[
                        Text(
                          '빠른 액션',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildQuickActions(context, ref, activeDisasterAsync),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 상단 상태 헤더 위젯
  Widget _buildStatusHeader(
    BuildContext context,
    AsyncValue activeDisasterAsync,
    AsyncValue locationAsync,
    AsyncValue<String?> addressAsync,
    bool testMode,
    dynamic testDisaster,
  ) {
    final bool hasDisaster = activeDisasterAsync.value != null || testDisaster != null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasDisaster
              ? [
                  AppColors.danger.withOpacity(0.9),
                  AppColors.dangerDark,
                ]
              : [
                  AppColors.safe,
                  AppColors.safe.withOpacity(0.8),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (hasDisaster ? AppColors.danger : AppColors.safe)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상태 아이콘
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                hasDisaster ? Icons.warning_rounded : Icons.shield_outlined,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // 상태 텍스트
            Text(
              hasDisaster ? '⚠️ 재난 경보 발생' : '✓ 안전 상태',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // 위치 정보
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: addressAsync.when(
                    data: (address) => Text(
                      address != null && address.isNotEmpty
                          ? '현재 위치: $address'
                          : '위치 정보 없음',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => Text(
                      '주소 확인 중...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    error: (_, __) => Text(
                      '위치 확인 실패',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 퀵 액션 그리드 위젯
  Widget _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    AsyncValue activeDisasterAsync,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        // 긴급전화
        _QuickActionCard(
          icon: Icons.phone,
          label: '긴급전화',
          color: AppColors.dangerDark,
          onTap: () => _showEmergencyContacts(context),
        ),
        // 대피소 찾기
        _QuickActionCard(
          icon: Icons.map_outlined,
          label: '대피소 찾기',
          color: AppColors.danger,
          onTap: () => _showShelterMapDialog(context),
        ),
        // 행동요령
        _QuickActionCard(
          icon: Icons.menu_book,
          label: '행동요령',
          color: const Color(0xFFFF6B7A),
          onTap: () => context.push('/training'),
        ),
        // 알림설정
        _QuickActionCard(
          icon: Icons.notifications_active_outlined,
          label: '알림설정',
          color: const Color(0xFFFF8A95),
          onTap: () => context.push('/settings'),
        ),
      ],
    );
  }

  /// 활성 재난 카드 위젯
  Widget _buildActiveDisasterCard(BuildContext context, dynamic disaster) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingExtraLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    DisasterTypeConfig.getConfig(disaster.type).icon,
                    color: Theme.of(context).colorScheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DisasterTypeConfig.getConfig(disaster.type).displayName}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '발생지: ${disaster.location}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // AI 행동 카드 미리보기
            _ActionCardPreview(disasterId: disaster.id),
          ],
        ),
      ),
    );
  }

  /// 안전 상태 카드 위젯
  Widget _buildSafeCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingExtraLarge),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.safe.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: AppColors.safe,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '현재 지역에 활성 경보 없음',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '위치 기반 알림이 활성화되어 있습니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// 테스트 모드 컨트롤 위젯
  Widget _buildTestModeControls(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.warning, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'TEST MODE',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TestScenarioButton(
                  label: '지진',
                  icon: Icons.landscape,
                  color: const Color(0xFF795548),
                  onPressed: () => _triggerTestScenario(context, ref, 'earthquake'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TestScenarioButton(
                  label: '해일',
                  icon: Icons.waves,
                  color: const Color(0xFF2196F3),
                  onPressed: () => _triggerTestScenario(context, ref, 'tsunami'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TestScenarioButton(
                  label: '화재',
                  icon: Icons.local_fire_department,
                  color: AppColors.critical,
                  onPressed: () => _triggerTestScenario(context, ref, 'fire'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TestScenarioButton(
                  label: '전쟁',
                  icon: Icons.shield,
                  color: const Color(0xFF9C27B0),
                  onPressed: () => _triggerTestScenario(context, ref, 'war'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 테스트 재난 카드 위젯
  Widget _buildTestDisasterCard(BuildContext context, dynamic testDisaster) {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  DisasterTypeConfig.getConfig(testDisaster.type).icon,
                  color: DisasterTypeConfig.getConfig(testDisaster.type).color,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${testDisaster.type} - ${testDisaster.severity}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '발생지: ${testDisaster.location}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.local_hospital, color: AppColors.critical),
                title: const Text('화재/응급'),
                trailing: const Text(
                  '119',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                onTap: () => _callNumber(context, '119'),
              ),
              ListTile(
                leading: const Icon(Icons.local_police, color: Colors.blue),
                title: const Text('범죄/재난'),
                trailing: const Text(
                  '112',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                onTap: () => _callNumber(context, '112'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.green),
                title: const Text('엄마'),
                trailing: const Text(
                  '010-1234-5678',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                onTap: () => _callNumber(context, '01012345678'),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text('아빠'),
                trailing: const Text(
                  '010-8765-4321',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                onTap: () => _callNumber(context, '01087654321'),
              ),
            ],
          ),
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

  /// 전화 걸기
  static Future<void> _callNumber(BuildContext context, String number) async {
    final url = Uri(scheme: 'tel', path: number);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('전화 걸기 실패: $e')),
        );
      }
    }
  }

  /// 대피소 지도 다이얼로그 표시
  static void _showShelterMapDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      '대피소 안내',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // 지도 위젯
              const Expanded(
                child: ShelterMapWidget(showAppBar: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 테스트 시나리오 트리거
  static Future<void> _triggerTestScenario(
    BuildContext context,
    WidgetRef ref,
    String disasterType,
  ) async {
    // 위치 정보 가져오기
    final location = await ref.read(currentLocationProvider.future);
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 정보를 가져올 수 없습니다')),
      );
      return;
    }

    // 사용자 프로필 가져오기
    final userProfile = await ref.read(userProfileProvider.future);

    // Mock 재난 데이터 생성
    ref.read(testDisasterProvider.notifier).createScenario(
          disasterType,
          location.latitude,
          location.longitude,
        );

    final disaster = ref.read(testDisasterProvider);
    if (disaster == null) return;

    final typeNames = {
      'earthquake': '지진',
      'tsunami': '해일',
      'fire': '화재',
      'war': '전쟁',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${typeNames[disasterType]} 시나리오 생성 중...'),
        duration: const Duration(seconds: 2),
      ),
    );

    // 테스트 액션 카드 생성
    await ref.read(testActionCardProvider.notifier).generateCard(
          ref.read(actionCardRepositoryProvider),
          disaster.id,
          location.latitude,
          location.longitude,
          userProfile?.ageGroup ?? '성인',
          userProfile?.mobility ?? '정상',
        );
  }
}

/// 퀵 액션 카드 위젯
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
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 테스트 시나리오 버튼 위젯
class _TestScenarioButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _TestScenarioButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 행동 카드 미리보기 위젯 (LLM 생성)
class _ActionCardPreview extends ConsumerWidget {
  final int disasterId;

  const _ActionCardPreview({required this.disasterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionCardAsync = ref.watch(currentActionCardProvider);

    return actionCardAsync.when(
      data: (actionCard) {
        if (actionCard == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            ),
            child: Text(
              '행동 카드를 생성할 수 없습니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey,
                  ),
            ),
          );
        }

        final actionItems = actionCard.actionItems.take(3).toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            border: Border.all(
              color: AppColors.danger.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI 추천 행동 요령',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...actionItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (actionCard.actionItems.length > 3) ...[
                const SizedBox(height: 4),
                Text(
                  '+ ${actionCard.actionItems.length - 3}개 더보기',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.danger),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AI가 행동 요령을 생성하는 중...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey,
                  ),
            ),
          ],
        ),
      ),
      error: (error, stack) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.critical, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '행동 카드 생성 실패: ${error.toString()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.critical,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
