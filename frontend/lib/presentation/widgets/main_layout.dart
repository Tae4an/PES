import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNavigationBar(context),
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: '지도',
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
    // 이전 인덱스 업데이트
    _previousIndex = currentIndex;
    
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/map');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }

  /// 현재와 이전 인덱스를 비교하여 슬라이드 방향 결정
  static int getPreviousIndex() => _previousIndex;
  static void setPreviousIndex(int index) => _previousIndex = index;
}

