import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/constants.dart';
import '../widgets/main_layout.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // 로그인 관련 필드
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  // 선택 값
  String? _selectedGender; // ✅ 기본 null
  String? _selectedAgeGroup; // ✅ 기본 null

  // 질환 목록
  final List<TextEditingController> _diseaseControllers = [];

  bool _isLoading = false;

  void _addDiseaseField() {
    setState(() {
      _diseaseControllers.add(TextEditingController());
    });
  }

  void _removeDiseaseField(int index) {
    setState(() {
      _diseaseControllers.removeAt(index);
    });
  }

  bool get _isFormValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final gender = _selectedGender;
    final age = _selectedAgeGroup;

    final fieldsValid = email.isNotEmpty &&
        password.isNotEmpty &&
        confirm.isNotEmpty &&
        password == confirm;

    final selectionValid = gender != null && age != null;
    return fieldsValid && selectionValid;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isFormValid) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2)); // 실제 API 대체용
    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('회원가입이 완료되었습니다!')),
    );

    context.go('/login');
  }

  void _goToLogin() => context.go('/login');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return MainLayout(
      currentIndex: 0,
      child: Scaffold(
        appBar: AppBar(title: const Text('회원가입')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge * 1.2),
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(
                    Icons.person_add_alt_1_outlined,
                    size: 70,
                    color: theme.colorScheme.primary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    '회원가입',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: (textTheme.headlineSmall?.fontSize ?? 20) + 2,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // 이메일
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? '이메일을 입력해주세요.' : null,
                ),
                const SizedBox(height: 16),

                // 비밀번호
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.length < 6 ? '비밀번호는 6자 이상이어야 합니다.' : null,
                ),
                const SizedBox(height: 16),

                // 비밀번호 확인
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 확인',
                    prefixIcon: Icon(Icons.check_circle_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v != _passwordController.text
                      ? '비밀번호가 일치하지 않습니다.'
                      : null,
                ),
                const SizedBox(height: 32),

                // 개인 정보
                Text(
                  '개인 정보',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildGenderSection(context),
                const SizedBox(height: 16),
                _buildAgeSection(context),
                const Divider(height: 32),

                // 질환 추가 섹션
                Text(
                  '앓고 있는 질환이 있나요? (선택)',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // 동적으로 생성되는 질환 입력 필드
                Column(
                  children: List.generate(_diseaseControllers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _diseaseControllers[index],
                              decoration: InputDecoration(
                                labelText: '질환 ${index + 1}',
                                hintText: '예: 천식, 고혈압 등',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.redAccent,
                            onPressed: () => _removeDiseaseField(index),
                          ),
                        ],
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 8),

                // 중앙 플러스 버튼
                Center(
                  child: IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 32),
                    color: theme.colorScheme.primary,
                    onPressed: _addDiseaseField,
                  ),
                ),
                const SizedBox(height: 16),
                // 회원가입 버튼
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isFormValid && !_isLoading ? _register : null,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add),
                    label: Text(
                      _isLoading ? '가입 중...' : '회원가입',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 로그인으로 이동
                Center(
                  child: TextButton(
                    onPressed: _goToLogin,
                    child: Text(
                      '이미 계정이 있으신가요? 로그인하기',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: (textTheme.bodyLarge?.fontSize ?? 16) + 2,
                      ),
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

  /// 👩 성별 섹션
  Widget _buildGenderSection(BuildContext context) {
    return Row(
      children: [
        _genderButton(context, 'male', '남성', Icons.male),
        _genderButton(context, 'female', '여성', Icons.female),
      ],
    );
  }

  Widget _genderButton(
      BuildContext context, String value, String label, IconData icon) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () => setState(() => _selectedGender = value),
          borderRadius:
              BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[100],
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusMedium),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 22,
                    color: isSelected ? Colors.white : Colors.grey[700]),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  /// 👶 연령대 섹션
Widget _buildAgeSection(BuildContext context) {
  final ages = ['어린이', '청소년', '성인', '노인'];

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: ages.map((age) {
      final isSelected = _selectedAgeGroup == age;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(age, style: const TextStyle(fontSize: 16)),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedAgeGroup = age),
            selectedColor: Theme.of(context).colorScheme.primary,
            backgroundColor: Colors.grey[100],
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[800],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusMedium),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300]!,
                width: 1.3,
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}


}
