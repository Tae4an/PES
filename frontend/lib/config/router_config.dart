import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- Screens ---
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/action_card_screen.dart';
import '../presentation/screens/map_screen.dart';
import '../presentation/screens/training_screen.dart';
import '../presentation/screens/rewards_screen.dart';
import '../presentation/screens/notifications_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/register_screen.dart';

// --- Layout ---
import '../presentation/widgets/main_layout.dart';

/// 🌐 GoRouter 전역 라우터 설정
class AppRouter {
  /// 메뉴 인덱스 매핑 (MainLayout 전용)
  static const Map<String, int> _routeIndexMap = {
    '/home': 0,
    '/training': 1,
    '/rewards': 2,
    '/settings': 3,
  };

  /// 📱 슬라이드 전환 애니메이션 페이지 빌더
  static CustomTransitionPage _buildPageWithSlideTransition({
    required Widget child,
    required String path,
    required GoRouterState state,
  }) {
    final currentIndex = _routeIndexMap[path] ?? -1;
    final previousIndex = MainLayout.getPreviousIndex();

    // 인덱스가 증가하면 왼쪽에서 → 오른쪽, 감소하면 반대로
    final isForward = currentIndex > previousIndex;
    final slideOffset = isForward
        ? const Offset(1.0, 0.0)
        : const Offset(-1.0, 0.0);

    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
    );
  }

  /// 🚀 전역 라우터
  static final GoRouter router = GoRouter(
    initialLocation: '/login', // ✅ 앱 시작 시 로그인 화면부터 시작
    debugLogDiagnostics: true,
    routes: [
      // ✅ 로그인 화면
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ✅ 회원가입 화면 (페이드 인)
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 300),
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        ),
      ),

      // ✅ 홈 화면
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const HomeScreen(),
          path: '/home',
          state: state,
        ),
      ),

      // ✅ 행동 카드 화면 (페이드)
      GoRoute(
        path: '/action-card',
        name: 'action-card',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 300),
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
        ),
      ),

      // ✅ 훈련 화면
      GoRoute(
        path: '/training',
        name: 'training',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const TrainingScreen(),
          path: '/training',
          state: state,
        ),
      ),

      // ✅ 보상 화면
      GoRoute(
        path: '/rewards',
        name: 'rewards',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const RewardsScreen(),
          path: '/rewards',
          state: state,
        ),
      ),

      // ✅ 지도 화면 (기존, 유지)
      GoRoute(
        path: '/map',
        name: 'map',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          child: const MapScreen(),
          path: '/map',
          state: state,
        ),
      ),

      // ✅ 알림 화면 (페이드)
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 300),
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
        ),
      ),

      // ✅ 설정 화면
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

    // ⚠️ 에러 페이지
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
