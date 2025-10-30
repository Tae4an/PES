import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/constants.dart';
import '../widgets/main_layout.dart';

/// 로그인 화면
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _login() async {
    final id = _idController.text.trim();
    final password = _passwordController.text;

    if (id.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2)); // 👈 실제 로그인 API 대체 (임시)
    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('로그인 성공!')),
    );

    // 로그인 성공 시 메인 페이지로 이동
    context.go('/home');
  }

  void _navigateToRegister() {
    context.push('/register'); // ✅ GoRouter로 회원가입 페이지 이동
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return MainLayout(
      currentIndex: 0,
      child: Scaffold(
        appBar: AppBar(title: const Text('로그인')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLarge * 1.2,
              vertical: AppConstants.paddingLarge,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔷 로고 및 제목
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: theme.colorScheme.primary.withOpacity(0.8),
                ),
                const SizedBox(height: 20),
                Text(
                  '로그인',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: (textTheme.headlineSmall?.fontSize ?? 20) + 2,
                  ),
                ),
                const SizedBox(height: 40),

                // 🧍 아이디 필드
                TextField(
                  controller: _idController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '아이디 (이메일)',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(
                      fontSize: (textTheme.bodyMedium?.fontSize ?? 14) + 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔒 비밀번호 필드
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    labelStyle: TextStyle(
                      fontSize: (textTheme.bodyMedium?.fontSize ?? 14) + 2,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 🟦 로그인 버튼
                FilledButton.icon(
                  onPressed: _isLoading ? null : _login,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(
                    _isLoading ? '로그인 중...' : '로그인',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // 🟧 회원가입 버튼
                TextButton(
                  onPressed: _navigateToRegister,
                  child: Text(
                    '회원가입하기',
                    style: TextStyle(
                      fontSize: (textTheme.bodyLarge?.fontSize ?? 16) + 2,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
