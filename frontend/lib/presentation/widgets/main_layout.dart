import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/constants.dart';

/// 하단 네비게이션 바가 포함된 메인 레이아웃
class MainLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  // 이전 인덱스를 저장하는 정적 변수
  static int _previousIndex = 0;

  const MainLayout({
    Key? key,
    required this.child,
    required this.currentIndex,
  }) : super(key: key);

  bool _shouldShowBottomNav(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    // 로그인, 회원가입, 온보딩, 스플래시에서는 네비게이션 바 숨김
    return !(location.startsWith('/login') ||
        location.startsWith('/register') ||
        location == '/' ||
        location.startsWith('/onboarding'));
  }

  @override
  Widget build(BuildContext context) {
    final showNav = _shouldShowBottomNav(context);
    return Scaffold(
      body: child,
      bottomNavigationBar:
          showNav ? _buildBottomNavigationBar(context) : null, // ✅ 조건부 렌더링
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onItemTapped(context, index),
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.danger.withOpacity(0.1),
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: '훈련',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: '보상',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    _previousIndex = currentIndex;

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/training');
        break;
      case 2:
        context.go('/rewards');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  static int getPreviousIndex() => _previousIndex;
  static void setPreviousIndex(int index) => _previousIndex = index;
}
