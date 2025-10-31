import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:go_router/go_router.dart';
import '../../config/constants.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/user_provider.dart';
import '../providers/training_user_provider.dart';
import '../widgets/main_layout.dart';
import '../../core/utils/logger.dart';

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

  final List<TextEditingController> _diseaseControllers = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _addDiseaseField();
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
    return MainLayout(
      currentIndex: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('설정'),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // 프로필 카드
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.danger.withOpacity(0.85),
                      AppColors.dangerDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '개인 정보',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '프로필 및 안전 설정',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 개인 정보 섹션
              _buildSection(
                context,
                title: '기본 정보',
                children: [
                  _buildGenderSelector(),
                  const Divider(height: 1),
                  _buildAgeSelector(),
                  const Divider(height: 1),
                  _buildDiseaseSection(),
                ],
              ),

              // 알림 설정 섹션
              _buildSection(
                context,
                title: '알림 설정',
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications_active,
                    iconColor: AppColors.danger,
                    title: '위치 기반 알림',
                    subtitle: '현재 위치 기반 재난 알림 수신',
                    value: _notificationsEnabled,
                    onChanged: (value) => setState(() => _notificationsEnabled = value),
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    icon: Icons.priority_high,
                    iconColor: Colors.orange,
                    title: '높은 우선순위',
                    subtitle: '중요한 알림을 우선적으로 표시',
                    value: _highPriorityNotifications,
                    onChanged: (value) => setState(() => _highPriorityNotifications = value),
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    icon: Icons.volume_up,
                    iconColor: Colors.blue,
                    title: '소리 알림',
                    subtitle: '알림 수신 시 소리 재생',
                    value: _soundEnabled,
                    onChanged: (value) => setState(() => _soundEnabled = value),
                  ),
                ],
              ),

              // 앱 정보 섹션
              _buildSection(
                context,
                title: '앱 정보',
                children: [
                  _buildInfoTile(
                    icon: Icons.info_outline,
                    iconColor: Colors.grey,
                    title: '앱 버전',
                    trailing: Text(
                      AppConstants.appVersion,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: Colors.grey,
                    title: '개인정보 처리방침',
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    icon: Icons.description_outlined,
                    iconColor: Colors.grey,
                    title: '서비스 약관',
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    icon: Icons.help_outline,
                    iconColor: Colors.grey,
                    title: '도움말',
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                ],
              ),

              // 저장 및 로그아웃 버튼
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          '설정 저장',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                        child: const Text(
                          '로그아웃',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wc, size: 20, color: AppColors.danger),
              const SizedBox(width: 8),
              const Text(
                '성별',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption('male', '남성', Icons.male),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderOption('female', '여성', Icons.female),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final isSelected = _selectedGender == value;
    return InkWell(
      onTap: () => setState(() => _selectedGender = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.danger.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.danger : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.danger : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.danger : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 20, color: AppColors.danger),
              const SizedBox(width: 8),
              const Text(
                '연령대',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['어린이', '청소년', '성인', '노인'].map((age) {
              final isSelected = _selectedAgeGroup == age;
              return InkWell(
                onTap: () => setState(() => _selectedAgeGroup = age),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.danger : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    age,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.medical_services_outlined, size: 20, color: AppColors.danger),
                  const SizedBox(width: 8),
                  const Text(
                    '기저 질환',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _addDiseaseField,
                icon: Icon(Icons.add_circle_outline, size: 18, color: AppColors.danger),
                label: Text(
                  '추가',
                  style: TextStyle(color: AppColors.danger, fontSize: 14),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._diseaseControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: '예: 고혈압, 천식 등',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  if (_diseaseControllers.length > 1) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      color: Colors.red,
                      onPressed: () => _removeDiseaseField(index),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.danger,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
    );
  }

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
        SnackBar(
          content: const Text('설정이 저장되었습니다'),
          backgroundColor: AppColors.safe,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final trainingUserProvider = provider.Provider.of<TrainingUserProvider>(context, listen: false);
      await trainingUserProvider.logout();
      AppLogger.i('로그아웃 완료');
      if (mounted) {
        context.go('/login');
      }
    }
  }
}
