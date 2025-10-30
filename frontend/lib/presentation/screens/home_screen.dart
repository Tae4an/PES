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
import '../widgets/notification_overlay.dart';
import '../widgets/main_layout.dart';
import '../widgets/action_card_widget.dart';
import '../widgets/shelter_map_widget.dart';
import '../../core/services/fcm_service.dart';
import '../../core/network/dio_client.dart';

/// 홈 화면
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDisasterAsync = ref.watch(activeDisasterStreamProvider);
    final testMode = ref.watch(testModeProvider);
    final testDisaster = ref.watch(testDisasterProvider);

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
                // 테스트 모드 시나리오 버튼
                if (testMode) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadiusSmall),
                      border: Border.all(color: AppColors.warning, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bug_report,
                            color: AppColors.warning, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'TEST',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _TestScenarioButton(
                                  label: '지진',
                                  icon: Icons.landscape,
                                  color: const Color(0xFF795548),
                                  onPressed: () => _triggerTestScenario(
                                      context, ref, 'earthquake'),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _TestScenarioButton(
                                  label: '해일',
                                  icon: Icons.waves,
                                  color: const Color(0xFF2196F3),
                                  onPressed: () => _triggerTestScenario(
                                      context, ref, 'tsunami'),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _TestScenarioButton(
                                  label: '화재',
                                  icon: Icons.local_fire_department,
                                  color: AppColors.critical,
                                  onPressed: () => _triggerTestScenario(
                                      context, ref, 'fire'),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _TestScenarioButton(
                                  label: '전쟁',
                                  icon: Icons.shield,
                                  color: const Color(0xFF9C27B0),
                                  onPressed: () =>
                                      _triggerTestScenario(context, ref, 'war'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 테스트 모드 재난 정보 표시
                  if (testDisaster != null) ...[
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingLarge),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  DisasterTypeConfig.getConfig(
                                          testDisaster.type)
                                      .icon,
                                  color: DisasterTypeConfig.getConfig(
                                          testDisaster.type)
                                      .color,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${testDisaster.type} - ${testDisaster.severity}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '발생지: ${testDisaster.location}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadiusSmall),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '나중에 llm연결',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize: (Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.fontSize ??
                                                  14) *
                                              1.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '나중에 llm연결',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize: (Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.fontSize ??
                                                  14) *
                                              1.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '나중에 llm연결',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize: (Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.fontSize ??
                                                  14) *
                                              1.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 테스트 모드 액션 카드 표시
                  actionCardAsync.when(
                    data: (actionCard) {
                      if (actionCard != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                ],

                // 활성 재난 경보 섹션 (테스트 모드가 아닐 때만 표시)
                if (!testMode) ...[
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
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingLarge),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        DisasterTypeConfig.getConfig(
                                                disaster.type)
                                            .icon,
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${DisasterTypeConfig.getConfig(disaster.type).displayName} - ${disaster.type}',
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
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // AI 행동 카드 미리보기
                                  _ActionCardPreview(disasterId: disaster.id),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: () =>
                                          _showShelterMapDialog(context),
                                      icon: const Icon(Icons.map),
                                      label: const Text('대피소 안내'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.safe,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Card(
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingLarge),
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
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '위치 기반 알림이 활성화되어 있습니다',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                    loading: () => const LoadingSkeletonCard(height: 200),
                    error: (e, st) => ErrorCard(
                      error: e.toString(),
                      onRetry: () =>
                          ref.invalidate(activeDisasterStreamProvider),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 빠른 액션 섹션 제거, 원형 긴급전화 버튼만 표시
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(44),
                        onTap: () => _showEmergencyContacts(context),
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.phone,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '긴급전화',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
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
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.local_hospital, color: AppColors.critical),
                title: const Text('화재/응급'),
                trailing: const Text('119',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                onTap: () => _callNumber(context, '119'),
              ),
              ListTile(
                leading: const Icon(Icons.local_police, color: Colors.blue),
                title: const Text('범죄/재난'),
                trailing: const Text('112',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                onTap: () => _callNumber(context, '112'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.green),
                title: const Text('엄마'),
                trailing: const Text('010-1234-5678',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                onTap: () => _callNumber(context, '01012345678'),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text('아빠'),
                trailing: const Text('010-8765-4321',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
        Navigator.pop(context); // 다이얼로그 닫기
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.safe,
                  borderRadius: const BorderRadius.only(
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
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        minimumSize: const Size(0, 36),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// (삭제됨) 빠른 액션 카드 위젯은 더 이상 사용하지 않습니다.

/// 행동 카드 미리보기 위젯 (LLM 생성)
class _ActionCardPreview extends ConsumerWidget {
  final int disasterId;

  const _ActionCardPreview({required this.disasterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 현재 활성 재난 기반 행동 카드 가져오기
    final actionCardAsync = ref.watch(currentActionCardProvider);

    return actionCardAsync.when(
      data: (actionCard) {
        if (actionCard == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusSmall),
            ),
            child: Text(
              '행동 카드를 생성할 수 없습니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey,
                  ),
            ),
          );
        }

        // 액션 카드 내용 표시 (상위 3개만)
        final actionItems = actionCard.actionItems.take(3).toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            border: Border.all(
              color: AppColors.safe.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.safe,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI 추천 행동 요령',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.safe,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 행동 요령 목록
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
                          color: AppColors.safe.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.safe,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.safe),
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
