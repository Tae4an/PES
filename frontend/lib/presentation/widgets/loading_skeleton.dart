import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/constants.dart';

/// 스켈레톤 로딩 위젯
class LoadingSkeletonCard extends StatelessWidget {
  final double height;

  const LoadingSkeletonCard({
    Key? key,
    this.height = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        child: Container(
          height: height,
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 리스트 스켈레톤 로딩
class LoadingSkeletonList extends StatelessWidget {
  final int itemCount;

  const LoadingSkeletonList({
    Key? key,
    this.itemCount = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => const LoadingSkeletonCard(height: 120),
      ),
    );
  }
}

