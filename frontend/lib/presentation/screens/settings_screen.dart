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
  String _selectedAgeGroup = '20~40대';
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
      currentIndex: 3,
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
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '연령대',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: ['10대', '20~40대', '50~60대', '70대+'].map((age) {
                        return ChoiceChip(
                          label: Text(age),
                          selected: _selectedAgeGroup == age,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedAgeGroup = age);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '이동성',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('정상'),
                          value: 'normal',
                          groupValue: _selectedMobility,
                          onChanged: (value) {
                            setState(() => _selectedMobility = value!);
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('제한적'),
                          value: 'limited',
                          groupValue: _selectedMobility,
                          onChanged: (value) {
                            setState(() => _selectedMobility = value!);
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('휠체어 사용'),
                          value: 'wheelchair',
                          groupValue: _selectedMobility,
                          onChanged: (value) {
                            setState(() => _selectedMobility = value!);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
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

