import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/rewards_provider.dart';
import '../providers/training_user_provider.dart';
import '../widgets/main_layout.dart';
import '../../config/constants.dart';
import '../../core/utils/logger.dart';
import 'package:intl/intl.dart';

/// 보상 화면
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({Key? key}) : super(key: key);

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    AppLogger.i('보상 화면 데이터 로딩 시작');
    final trainingUserProvider = context.read<TrainingUserProvider>();
    final rewardsProvider = context.read<RewardsProvider>();

    await rewardsProvider.loadRewards();
    AppLogger.i('보상 목록 로드 완료: ${rewardsProvider.state.rewards.length}개');

    if (trainingUserProvider.state.deviceId != null) {
      await rewardsProvider.loadPointsBalance(trainingUserProvider.state.deviceId!);
      await rewardsProvider.loadMyCodes(trainingUserProvider.state.deviceId!);
      AppLogger.i('포인트 및 쿠폰 로드 완료');
    } else {
      AppLogger.w('deviceId가 없어서 포인트/쿠폰을 로드할 수 없습니다');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 2, // 보상 탭
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('보상'),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.danger,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.danger,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: '교환 가능한 보상'),
              Tab(text: '내 쿠폰함'),
            ],
          ),
        ),
        body: Column(
          children: [
            // 포인트 헤더 (작고 가로로 긴)
            Consumer2<TrainingUserProvider, RewardsProvider>(
              builder: (context, trainingUserProvider, rewardsProvider, _) {
                return Container(
                  margin: const EdgeInsets.all(16),
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
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.diamond,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '내 포인트',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${trainingUserProvider.state.totalPoints} P',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '🏃 ${rewardsProvider.state.completedTrainings}회 완료',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 탭 뷰
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRewardsTab(),
                  _buildMyCodesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsTab() {
    return Consumer<RewardsProvider>(
      builder: (context, rewardsProvider, _) {
        final rewards = rewardsProvider.state.rewards;

        if (rewardsProvider.state.isLoading && rewards.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (rewards.isEmpty) {
          return const Center(child: Text('보상이 없습니다'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            final reward = rewards[index];
            return _buildRewardCard(reward);
          },
        );
      },
    );
  }

  Widget _buildRewardCard(Reward reward) {
    final trainingUserProvider = context.read<TrainingUserProvider>();
    final canAfford = trainingUserProvider.state.totalPoints >= reward.points;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: canAfford ? () => _showRedeemDialog(reward) : null,
        child: SizedBox(
          height: 100, // 가로로 긴 직사각형
          child: Row(
            children: [
              // 이미지 영역 (왼쪽)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getPartnerColor(reward.partner).withOpacity(0.8),
                      _getPartnerColor(reward.partner),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getPartnerIcon(reward.partner),
                        size: 40,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reward.partner,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 정보 영역 (오른쪽)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        reward.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: canAfford ? AppColors.danger : AppColors.grey,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.diamond,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${reward.points} P',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right,
                            color: canAfford ? AppColors.danger : Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPartnerColor(String partner) {
    final colorMap = {
      '올리브영': const Color(0xFF00A862),
      '스타벅스': const Color(0xFF00704A),
      'GS25': const Color(0xFF0066B3),
      'CU': const Color(0xFF652D8E),
      '배달의민족': const Color(0xFF2AC1BC),
    };
    return colorMap[partner] ?? AppColors.danger;
  }

  IconData _getPartnerIcon(String partner) {
    final iconMap = {
      '올리브영': Icons.shopping_bag,
      '스타벅스': Icons.coffee,
      'GS25': Icons.store,
      'CU': Icons.local_convenience_store,
      '배달의민족': Icons.delivery_dining,
    };
    return iconMap[partner] ?? Icons.card_giftcard;
  }

  void _showRedeemDialog(Reward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.card_giftcard, color: AppColors.danger),
            const SizedBox(width: 8),
            const Text('보상 교환'),
          ],
        ),
        content: Text(
          '${reward.name}을(를) ${reward.points} 포인트로 교환하시겠습니까?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _redeemReward(reward);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('교환', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _redeemReward(Reward reward) async {
    final trainingUserProvider = context.read<TrainingUserProvider>();
    final rewardsProvider = context.read<RewardsProvider>();

    if (trainingUserProvider.state.deviceId == null) {
      _showMessage('로그인이 필요합니다');
      return;
    }

    try {
      final code = await rewardsProvider.redeemReward(
        deviceId: trainingUserProvider.state.deviceId!,
        rewardId: reward.id,
      );

      trainingUserProvider.subtractPoints(reward.points);
      _showCodeDialog(reward.name, code);
    } catch (e) {
      _showMessage('교환 실패: $e');
    }
  }

  void _showCodeDialog(String rewardName, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration,
                size: 60,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 16),
            const Text('🎉 교환 완료!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rewardName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.danger.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                _showMessage('코드가 복사되었습니다');
              },
              icon: Icon(Icons.copy, color: AppColors.danger),
              label: Text('코드 복사', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _tabController.animateTo(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                '내 쿠폰함으로 이동',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCodesTab() {
    return Consumer<RewardsProvider>(
      builder: (context, rewardsProvider, _) {
        final codes = rewardsProvider.state.myCodes;

        if (codes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '교환한 쿠폰이 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: codes.length,
          itemBuilder: (context, index) {
            final code = codes[index];
            return _buildCodeCard(code);
          },
        );
      },
    );
  }

  Widget _buildCodeCard(RedemptionCode code) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.card_giftcard, color: AppColors.danger),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    code.rewardName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.danger.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      code.code,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: AppColors.danger),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code.code));
                      _showMessage('코드가 복사되었습니다');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '교환일: ${dateFormat.format(code.redeemedAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '${code.pointsSpent} P',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
