import 'package:flutter/material.dart';
import '../../domain/entities/shelter.dart';
import '../../config/constants.dart';

/// 대피소 카드 위젯
class ShelterCardWidget extends StatelessWidget {
  final Shelter shelter;
  final int index;
  final VoidCallback onNavigate;

  const ShelterCardWidget({
    Key? key,
    required this.shelter,
    required this.index,
    required this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 번호 + 대피소명
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getRankColor(index),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shelter.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shelter.address,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 정보 바
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoChip(
                  icon: Icons.schedule,
                  label: '${shelter.walkingMinutes ?? 0}분',
                  sublabel: '도보',
                  color: Theme.of(context).colorScheme.primary,
                ),
                _InfoChip(
                  icon: Icons.people,
                  label: '${shelter.capacity}명',
                  sublabel: '수용',
                  color: Theme.of(context).colorScheme.secondary,
                ),
                _InfoChip(
                  icon: Icons.location_on,
                  label: shelter.type,
                  sublabel: '유형',
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 편의시설 (있는 경우)
            if (shelter.facilities.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shelter.facilities.take(3).map((facility) {
                  return Chip(
                    label: Text(
                      facility,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // 네비게이션 버튼
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onNavigate,
                icon: const Icon(Icons.navigation),
                label: const Text('📍 네비게이션 시작'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.grey;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          sublabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.grey,
              ),
        ),
      ],
    );
  }
}

