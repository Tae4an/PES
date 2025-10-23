import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/constants.dart';
import '../providers/location_provider.dart';
import '../providers/disaster_provider.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/error_card.dart';

/// 홈 화면
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(currentLocationProvider);
    final activeDisasterAsync = ref.watch(activeDisasterStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // 알림 목록 화면으로 이동 (TODO)
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
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
                '🚨 활성 재난 경보',
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

              // 빠른 액션 버튼
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: () => context.push('/map'),
                        borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium),
                        child: Padding(
                          padding: const EdgeInsets.all(AppConstants.paddingLarge),
                          child: Column(
                            children: [
                              Icon(
                                Icons.map,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              const Text('지도'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: () => context.push('/settings'),
                        borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium),
                        child: Padding(
                          padding: const EdgeInsets.all(AppConstants.paddingLarge),
                          child: Column(
                            children: [
                              Icon(
                                Icons.settings,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              const Text('설정'),
                            ],
                          ),
                        ),
                      ),
                    ),
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

