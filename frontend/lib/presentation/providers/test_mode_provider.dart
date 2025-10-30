import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 테스트 모드 Provider
final testModeProvider = StateNotifierProvider<TestModeNotifier, bool>((ref) {
  return TestModeNotifier();
});

class TestModeNotifier extends StateNotifier<bool> {
  TestModeNotifier() : super(false); // 기본값은 false (테스트 모드 비활성화)

  void toggle() {
    state = !state;
  }
}

