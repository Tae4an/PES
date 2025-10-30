import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/onboarding_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/action_card_screen.dart';
import '../presentation/screens/map_screen.dart';
import '../presentation/screens/notifications_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/widgets/main_layout.dart';

/// GoRouter 설정
class AppRouter {
  /// 메뉴 인덱스 매핑
  static const Map<String, int> _routeIndexMap = {
    '/home': 0,
    '/map': 1,
    '/settings': 2,
  };

  /// 슬라이드 애니메이션을 가진 페이지 빌더
  static CustomTransitionPage _buildPageWithSlideTransition({
    required Widget child,
    required String path,
    required GoRouterState state,
  }) {
    final currentIndex = _routeIndexMap[path] ?? -1;
    final previousIndex = MainLayout.getPreviousIndex();
    
    // 슬라이드 방향 결정: 인덱스가 증가하면 왼쪽에서, 감소하면 오른쪽에서
    final isForward = currentIndex > previousIndex;
    final slideOffset = isForward 
        ? const Offset(1.0, 0.0)  // 왼쪽에서 오른쪽으로
        : const Offset(-1.0, 0.0); // 오른쪽에서 왼쪽으로

    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // 부드러운 곡선 적용
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: slideOffset,
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // 스플래시 화면 (애니메이션 없음)
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // 온보딩 화면 (애니메이션 없음)
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // 홈 화면 (슬라이드 애니메이션)
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const HomeScreen(),
          path: '/home',
          state: state,
        ),
      ),

      // 행동 카드 화면 (페이드 애니메이션)
      GoRoute(
        path: '/action-card',
        name: 'action-card',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ActionCardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),

      // 지도 화면 (슬라이드 애니메이션)
      GoRoute(
        path: '/map',
        name: 'map',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const MapScreen(),
          path: '/map',
          state: state,
        ),
      ),

      // 알림 화면 (페이드 애니메이션)
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),

      // 설정 화면 (슬라이드 애니메이션)
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const SettingsScreen(),
          path: '/settings',
          state: state,
        ),
      ),
    ],

    // 에러 화면
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '페이지를 찾을 수 없습니다',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}

