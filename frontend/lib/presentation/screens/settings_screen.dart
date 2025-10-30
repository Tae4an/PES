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
  String _selectedMobility = 'normal';
  bool _notificationsEnabled = true;
  bool _highPriorityNotifications = true;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    final userProfileAsync = ref.read(userProfileNotifierProvider);
    userProfileAsync.whenData((profile) {
      if (profile != null) {
        setState(() {
          // _selectedGender는 UserProfile에 없으므로 기본값 유지
          _selectedAgeGroup = profile.ageGroup;
          _selectedMobility = profile.mobility;
          _notificationsEnabled = profile.notificationsEnabled;
          _highPriorityNotifications = profile.highPriorityNotifications;
          _soundEnabled = profile.soundEnabled;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('설정'),
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 개인 정보 섹션
            Text(
              '개인 정보',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.wc,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '성별',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '성별에 맞는 안내를 제공합니다',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedGender = 'male'),
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _selectedGender == 'male'
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                      border: Border.all(
                                        color: _selectedGender == 'male'
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey[300]!,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.male,
                                          size: 20,
                                          color: _selectedGender == 'male'
                                              ? Colors.white
                                              : Colors.grey[700],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '남성',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: _selectedGender == 'male' ? FontWeight.w600 : FontWeight.w500,
                                            color: _selectedGender == 'male'
                                                ? Colors.white
                                                : Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedGender = 'female'),
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _selectedGender == 'female'
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                      border: Border.all(
                                        color: _selectedGender == 'female'
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey[300]!,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.female,
                                          size: 20,
                                          color: _selectedGender == 'female'
                                              ? Colors.white
                                              : Colors.grey[700],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '여성',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: _selectedGender == 'female' ? FontWeight.w600 : FontWeight.w500,
                                            color: _selectedGender == 'female'
                                                ? Colors.white
                                                : Colors.grey[800],
                                          ),
                                        ),
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
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '연령대',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '맞춤형 대피 안내를 위해 필요합니다',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            Row(
                              children: ['어린이', '청소년'].map((age) {
                                final isSelected = _selectedAgeGroup == age;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: InkWell(
                                      onTap: () => setState(() => _selectedAgeGroup = age),
                                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                          border: Border.all(
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.primary
                                                : Colors.grey[300]!,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            age,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: ['성인', '노인'].map((age) {
                                final isSelected = _selectedAgeGroup == age;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: InkWell(
                                      onTap: () => setState(() => _selectedAgeGroup = age),
                                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                          border: Border.all(
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.primary
                                                : Colors.grey[300]!,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            age,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.accessibility_new,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '이동성',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '대피소 및 경로 추천에 활용됩니다',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        _MobilityOption(
                          icon: Icons.directions_walk,
                          title: '정상',
                          subtitle: '빠른 이동 가능',
                          value: 'normal',
                          groupValue: _selectedMobility,
                          onChanged: (value) {
                            setState(() => _selectedMobility = value!);
                          },
                        ),
                        _MobilityOption(
                          icon: Icons.accessible,
                          title: '제한적',
                          subtitle: '천천히 이동 가능',
                          value: 'limited',
                          groupValue: _selectedMobility,
                          onChanged: (value) {
                            setState(() => _selectedMobility = value!);
                          },
                        ),
                        _MobilityOption(
                          icon: Icons.wheelchair_pickup,
                          title: '휠체어 사용',
                          subtitle: '휠체어 접근 가능 시설 필요',
                          value: 'wheelchair',
                          groupValue: _selectedMobility,
                          onChanged: (value) {
                            setState(() => _selectedMobility = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 알림 설정 섹션
            Text(
              '알림 설정',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('위치 기반 알림'),
                      subtitle: const Text('현재 위치 기반 재난 알림 수신'),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('높은 우선순위'),
                      subtitle: const Text('중요한 알림을 우선적으로 표시'),
                      value: _highPriorityNotifications,
                      onChanged: (value) {
                        setState(() => _highPriorityNotifications = value);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('소리 알림'),
                      subtitle: const Text('알림 수신 시 소리 재생'),
                      value: _soundEnabled,
                      onChanged: (value) {
                        setState(() => _soundEnabled = value);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 정보 섹션
            Text(
              '정보',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('앱 버전'),
                    trailing: Text(
                      AppConstants.appVersion,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('개인정보 처리방침'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: 개인정보 처리방침 화면
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('서비스 약관'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: 서비스 약관 화면
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('도움말'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: 도움말 화면
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('설정 저장'),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
    );
  }

  Future<void> _saveSettings() async {
    final profile = UserProfile(
      ageGroup: _selectedAgeGroup,
      mobility: _selectedMobility,
      notificationsEnabled: _notificationsEnabled,
      highPriorityNotifications: _highPriorityNotifications,
      soundEnabled: _soundEnabled,
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

/// 이동성 옵션 위젯
class _MobilityOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _MobilityOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

