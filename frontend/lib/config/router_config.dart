import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/onboarding_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/action_card_screen.dart';
import '../presentation/screens/map_screen.dart';
import '../presentation/screens/notifications_screen.dart';
import '../presentation/screens/settings_screen.dart';

/// GoRouter 설정
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // 스플래시 화면
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // 온보딩 화면
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // 홈 화면
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // 행동 카드 화면
      GoRoute(
        path: '/action-card',
        name: 'action-card',
        builder: (context, state) => const ActionCardScreen(),
      ),

      // 지도 화면
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) => const MapScreen(),
      ),

      // 알림 화면
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // 설정 화면
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
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

