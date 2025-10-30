import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/user_provider.dart';
import '../widgets/main_layout.dart';

/// 설정 화면
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedGender = 'male';
  String _selectedAgeGroup = '성인';
  bool _notificationsEnabled = true;
  bool _highPriorityNotifications = true;
  bool _soundEnabled = true;

  // 🩺 질환 목록 동적 추가용 리스트
  final List<TextEditingController> _diseaseControllers = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _addDiseaseField(); // 기본 1개 필드 생성
  }

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

  void _loadUserProfile() {
    final userProfileAsync = ref.read(userProfileProvider);
    userProfileAsync.whenData((profile) {
      if (profile != null) {
        setState(() {
          _selectedAgeGroup = profile.ageGroup;
          _notificationsEnabled = profile.notificationsEnabled;
          _highPriorityNotifications = profile.highPriorityNotifications;
          _soundEnabled = profile.soundEnabled;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MainLayout(
      currentIndex: 3, // 훈련 시스템 추가로 인덱스 변경 (홈/훈련/보상/설정)
      child: Scaffold(
        appBar: AppBar(
          title: const Text('설정'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🧍‍♂️ 개인 정보 섹션
              Text(
                '개인 정보',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: (textTheme.headlineSmall?.fontSize ?? 20) + 2,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGenderSection(context),
                      const Divider(height: 24),
                      _buildAgeSection(context),
                      const Divider(height: 24),

                      // 🩺 “앓고 있는 질환이 있나요?” 섹션
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '앓고 있는 질환이 있나요?',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize:
                                  (textTheme.titleMedium?.fontSize ?? 16) + 2,
                            ),
                          )
                        ],
                      ),
                      Column(
                        children: List.generate(_diseaseControllers.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _diseaseControllers[index],
                                    style: const TextStyle(fontSize: 16),
                                    decoration: InputDecoration(
                                      labelText: '질환 ${index + 1}',
                                      labelStyle: TextStyle(
                                          fontSize: (textTheme.bodyMedium?.fontSize ?? 14) + 2),
                                      hintText: '예: 고혈압, 천식 등',
                                      hintStyle: TextStyle(
                                          fontSize: (textTheme.bodySmall?.fontSize ?? 12) + 2),
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
                      Center(
                      child: IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: Theme.of(context).colorScheme.primary,
                        iconSize: 28,
                        tooltip: "질환 항목 추가",
                        onPressed: _addDiseaseField,
                      ),
                    ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// 🔔 알림 설정
              Text(
                '알림 설정',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: (textTheme.headlineSmall?.fontSize ?? 20) + 2,
                ),
              ),
              const SizedBox(height: 16),
              _buildNotificationSettings(context),

              const SizedBox(height: 24),

              /// 📱 앱 정보
              _buildAppInfoSection(context),

              const SizedBox(height: 24),

              /// 💾 저장 버튼
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('설정 저장', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 👩 성별
  Widget _buildGenderSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wc, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '성별',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: (textTheme.titleMedium?.fontSize ?? 16) + 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _genderButton(context, 'male', '남성', Icons.male),
            _genderButton(context, 'female', '여성', Icons.female),
          ],
        ),
      ],
    );
  }

  Widget _genderButton(BuildContext context, String value, String label, IconData icon) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () => setState(() => _selectedGender = value),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[100],
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: isSelected ? Colors.white : Colors.grey[700]),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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

  /// 👶 연령대
  Widget _buildAgeSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '연령대',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: (textTheme.titleMedium?.fontSize ?? 16) + 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['어린이', '청소년', '성인', '노인']
              .map((age) => ChoiceChip(
                    label: Text(
                      age,
                      style: TextStyle(fontSize: 16),
                    ),
                    selected: _selectedAgeGroup == age,
                    onSelected: (_) => setState(() => _selectedAgeGroup = age),
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: _selectedAgeGroup == age ? Colors.white : Colors.grey[800],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  /// 🔔 알림 설정
  Widget _buildNotificationSettings(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('위치 기반 알림', style: TextStyle(fontSize: (textTheme.bodyLarge?.fontSize ?? 16) + 2)),
              subtitle: Text('현재 위치 기반 재난 알림 수신', style: TextStyle(fontSize: (textTheme.bodySmall?.fontSize ?? 12) + 2)),
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
            ),
            const Divider(),
            SwitchListTile(
              title: Text('높은 우선순위', style: TextStyle(fontSize: (textTheme.bodyLarge?.fontSize ?? 16) + 2)),
              subtitle: Text('중요한 알림을 우선적으로 표시', style: TextStyle(fontSize: (textTheme.bodySmall?.fontSize ?? 12) + 2)),
              value: _highPriorityNotifications,
              onChanged: (value) => setState(() => _highPriorityNotifications = value),
            ),
            const Divider(),
            SwitchListTile(
              title: Text('소리 알림', style: TextStyle(fontSize: (textTheme.bodyLarge?.fontSize ?? 16) + 2)),
              subtitle: Text('알림 수신 시 소리 재생', style: TextStyle(fontSize: (textTheme.bodySmall?.fontSize ?? 12) + 2)),
              value: _soundEnabled,
              onChanged: (value) => setState(() => _soundEnabled = value),
            ),
          ],
        ),
      ),
    );
  }

  /// 📱 앱 정보
  Widget _buildAppInfoSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('앱 버전',
                style: TextStyle(fontSize: (textTheme.bodyLarge?.fontSize ?? 14) + 2)),
            trailing: Text(AppConstants.appVersion,
                style: TextStyle(fontSize: (textTheme.bodySmall?.fontSize ?? 12) + 2)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text('개인정보 처리방침',
                style: TextStyle(fontSize: (textTheme.bodyLarge?.fontSize ?? 14) + 2)),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text('서비스 약관',
                style: TextStyle(fontSize: (textTheme.bodyLarge?.fontSize ?? 14) + 2)),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text('도움말',
                style: TextStyle(fontSize: (textTheme.bodyLarge?.fontSize ?? 14) + 2)),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  /// 저장
  Future<void> _saveSettings() async {
    final diseases = _diseaseControllers.map((c) => c.text).where((t) => t.isNotEmpty).join(', ');
    final profile = UserProfile(
      ageGroup: _selectedAgeGroup,
      notificationsEnabled: _notificationsEnabled,
      highPriorityNotifications: _highPriorityNotifications,
      soundEnabled: _soundEnabled,
      disease: diseases,
      lastUpdated: DateTime.now(),
    );

    await ref.read(userProfileNotifierProvider.notifier).updateProfile(profile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('설정이 저장되었습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
