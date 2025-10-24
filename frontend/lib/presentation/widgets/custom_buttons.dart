import 'package:flutter/material.dart';
import '../../config/constants.dart';

/// 긴급 신고 버튼 (CTA)
class EmergencyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const EmergencyButton({
    Key? key,
    required this.onPressed,
    this.label = '🚨 긴급 신고 (112)',
    this.icon = Icons.phone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
          elevation: AppConstants.elevationMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
        ),
      ),
    );
  }
}

/// 네비게이션 버튼
class NavigationButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const NavigationButton({
    Key? key,
    required this.onPressed,
    this.label = '📍 네비게이션 시작',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.navigation),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// 뒤로가기 버튼
class BackButtonCustom extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const BackButtonCustom({
    Key? key,
    this.onPressed,
    this.label = '← 돌아가기',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
        child: Text(label),
      ),
    );
  }
}

/// 일반 주요 액션 버튼
class PrimaryActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;

  const PrimaryActionButton({
    Key? key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon),
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  )
                : Text(label),
      ),
    );
  }
}

/// 보조 액션 버튼
class SecondaryActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;

  const SecondaryActionButton({
    Key? key,
    required this.onPressed,
    required this.label,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label),
      ),
    );
  }
}

