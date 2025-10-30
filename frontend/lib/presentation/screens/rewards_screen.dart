import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/rewards_provider.dart';
import '../providers/training_user_provider.dart';
import '../widgets/main_layout.dart';
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
    // initState에서는 context.read를 사용할 수 없으므로 postFrameCallback 사용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    AppLogger.i('보상 화면 데이터 로딩 시작');
    final trainingUserProvider = context.read<TrainingUserProvider>();
    final rewardsProvider = context.read<RewardsProvider>();

    // 보상 목록은 device_id 없이도 로드 가능
    await rewardsProvider.loadRewards();
    AppLogger.i('보상 목록 로드 완료: ${rewardsProvider.state.rewards.length}개');

    // device_id가 있으면 포인트와 쿠폰 로드
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
        appBar: AppBar(
          title: const Text('보상'),
          automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '교환 가능한 보상'),
              Tab(text: '내 쿠폰함'),
            ],
          ),
        ),
        body: Column(
        children: [
          // 포인트 헤더
          Consumer2<TrainingUserProvider, RewardsProvider>(
            builder: (context, trainingUserProvider, rewardsProvider, _) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.blue.shade50,
                child: Column(
                  children: [
                    const Text(
                      '💎 내 포인트',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${trainingUserProvider.state.totalPoints} P',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🏃 완료한 훈련: ${rewardsProvider.state.completedTrainings}회',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
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

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7, // 0.75 -> 0.7로 변경 (카드 높이 증가)
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: canAfford ? () => _showRedeemDialog(reward) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘 영역
            Container(
              height: 110, // 120 -> 110으로 줄임
              width: double.infinity,
              color: Colors.grey.shade100,
              child: Center(
                child: Text(
                  _getPartnerEmoji(reward.partner),
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0), // 12 -> 10으로 줄임
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.partner,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reward.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: canAfford ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${reward.points} P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPartnerEmoji(String partner) {
    final emojiMap = {
      '올리브영': '🛍️',
      '스타벅스': '☕',
      'GS25': '🏪',
      'CU': '🏪',
      '배달의민족': '🍔',
    };
    return emojiMap[partner] ?? '🎁';
  }

  void _showRedeemDialog(Reward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('보상 교환'),
        content: Text(
          '${reward.name}을(를) ${reward.points} 포인트로 교환하시겠습니까?',
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
            child: const Text('교환'),
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

      // 사용자 포인트도 업데이트
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
        title: const Text('🎉 교환 완료!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rewardName),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                _showMessage('코드가 복사되었습니다');
              },
              icon: const Icon(Icons.copy),
              label: const Text('코드 복사'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _tabController.animateTo(1); // 내 쿠폰함으로 이동
            },
            child: const Text('확인'),
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
          return const Center(
            child: Text('교환한 쿠폰이 없습니다'),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.blue),
                const SizedBox(width: 8),
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
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
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
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code.code));
                      _showMessage('코드가 복사되었습니다');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '교환일: ${dateFormat.format(code.redeemedAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              '사용 포인트: ${code.pointsSpent} P',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

