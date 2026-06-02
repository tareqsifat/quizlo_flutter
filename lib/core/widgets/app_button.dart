import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_sizes.dart';

/// ─────────────────────────────────────────────
/// App Button — Quizlo Design System
/// Matches the large pill buttons from Figma
/// ─────────────────────────────────────────────

enum AppButtonVariant { primary, outlined, danger, ghost, disabled }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;
  final Widget? icon;
  final double fontSize;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = AppSizes.buttonHeightLg,
    this.icon,
    this.fontSize = 16,
  });

  const AppButton.outlined({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.width,
    this.height = AppSizes.buttonHeightLg,
    this.icon,
    this.fontSize = 16,
  }) : variant = AppButtonVariant.outlined;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.width,
    this.height = AppSizes.buttonHeightLg,
    this.icon,
    this.fontSize = 16,
  }) : variant = AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null || variant == AppButtonVariant.disabled;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled && !isLoading ? 0.55 : 1.0,
        child: _buildButton(isDisabled),
      ),
    );
  }

  Widget _buildButton(bool isDisabled) {
    switch (variant) {
      case AppButtonVariant.outlined:
        return _OutlinedBtn(
          label: label,
          onTap: isDisabled ? null : onTap,
          isLoading: isLoading,
          icon: icon,
          fontSize: fontSize,
        );
      case AppButtonVariant.danger:
        return _FilledBtn(
          label: label,
          onTap: isDisabled ? null : onTap,
          isLoading: isLoading,
          bgColor: AppColors.error,
          icon: icon,
          fontSize: fontSize,
        );
      case AppButtonVariant.ghost:
        return _GhostBtn(
          label: label,
          onTap: isDisabled ? null : onTap,
          isLoading: isLoading,
          fontSize: fontSize,
        );
      default:
        return _FilledBtn(
          label: label,
          onTap: isDisabled ? null : onTap,
          isLoading: isLoading,
          bgColor: isDisabled ? AppColors.primarySurface : AppColors.primary,
          icon: icon,
          fontSize: fontSize,
        );
    }
  }
}

class _FilledBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color bgColor;
  final Widget? icon;
  final double fontSize;

  const _FilledBtn({
    required this.label,
    this.onTap,
    this.isLoading = false,
    required this.bgColor,
    this.icon,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 8)],
                    Text(
                      label.toUpperCase(),
                      style: AppTextStyles.buttonLarge.copyWith(fontSize: fontSize),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _OutlinedBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Widget? icon;
  final double fontSize;

  const _OutlinedBtn({
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.icon,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(color: AppColors.border, width: 1.5),
        color: AppColors.cardBg,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[icon!, const SizedBox(width: 8)],
                      Text(
                        label,
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: fontSize,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double fontSize;

  const _GhostBtn({
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onTap,
      child: Text(
        label,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.primary,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// Social Auth Button (Facebook / Google)
/// ─────────────────────────────────────────────
class SocialAuthButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Widget icon;
  final VoidCallback? onTap;

  const SocialAuthButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeightLg,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTextStyles.buttonMedium.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
