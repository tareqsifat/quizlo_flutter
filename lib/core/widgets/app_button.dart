import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_sizes.dart';

/// ─────────────────────────────────────────────
/// App Button — Quizlo Design System
/// Premium 3D pressable buttons (Duolingo style)
/// ─────────────────────────────────────────────

enum AppButtonVariant { primary, outlined, danger, ghost, disabled, cta, accent }

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

  const AppButton.cta({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.width,
    this.height = AppSizes.buttonHeightLg,
    this.icon,
    this.fontSize = 16,
  }) : variant = AppButtonVariant.cta;

  const AppButton.accent({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.width,
    this.height = AppSizes.buttonHeightLg,
    this.icon,
    this.fontSize = 16,
  }) : variant = AppButtonVariant.accent;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null || variant == AppButtonVariant.disabled;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: _buildButton(isDisabled),
    );
  }

  Widget _buildButton(bool isDisabled) {
    if (variant == AppButtonVariant.ghost) {
      return _GhostBtn(
        label: label,
        onTap: isDisabled ? null : onTap,
        isLoading: isLoading,
        fontSize: fontSize,
      );
    }

    // Resolve colors for 3D button
    Color topColor;
    Color shadowColor;
    Color textColor;
    BoxBorder? border;
    bool isUppercase = true;

    if (isDisabled) {
      topColor = const Color(0xFFE2E8F0);
      shadowColor = const Color(0xFFCBD5E1);
      textColor = const Color(0xFF94A3B8);
      isUppercase = false;
    } else {
      switch (variant) {
        case AppButtonVariant.outlined:
          topColor = Colors.white;
          shadowColor = AppColors.border;
          textColor = AppColors.textPrimary;
          border = Border.all(color: AppColors.border, width: 1.5);
          isUppercase = false;
          break;
        case AppButtonVariant.danger:
          topColor = AppColors.error;
          shadowColor = const Color(0xFFC0392B);
          textColor = Colors.white;
          break;
        case AppButtonVariant.cta:
          topColor = AppColors.cta;
          shadowColor = const Color(0xFF4538C4);
          textColor = Colors.white;
          break;
        case AppButtonVariant.accent:
          topColor = AppColors.accent;
          shadowColor = AppColors.accentDark;
          textColor = Colors.white;
          break;
        default: // primary
          topColor = AppColors.primary;
          shadowColor = AppColors.primaryDark;
          textColor = Colors.white;
          break;
      }
    }

    final String displayLabel = isUppercase ? label.toUpperCase() : label;

    return _Base3DButton(
      onTap: isDisabled ? null : onTap,
      topColor: topColor,
      shadowColor: shadowColor,
      border: border,
      height: height,
      isDisabled: isDisabled,
      isLoading: isLoading,
      textColor: textColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 8)],
          Text(
            displayLabel,
            style: AppTextStyles.buttonLarge.copyWith(
              color: textColor,
              fontSize: fontSize,
            ),
          ),
        ],
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
/// Also implements the pressable 3D shadow style
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
    final bool isGoogle = backgroundColor == Colors.white || backgroundColor == AppColors.googleWhite;
    final shadowColor = isGoogle ? const Color(0xFFDDDDDD) : const Color(0xFF0F5BBE);
    final border = isGoogle ? Border.all(color: AppColors.border, width: 1.5) : null;

    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeightLg,
      child: _Base3DButton(
        onTap: onTap,
        topColor: backgroundColor,
        shadowColor: shadowColor,
        border: border,
        height: AppSizes.buttonHeightLg,
        textColor: textColor,
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
    );
  }
}

/// ─────────────────────────────────────────────
/// Base 3D Pressable Button Wrapper
/// Handles snappy translation animation on tap
/// ─────────────────────────────────────────────
class _Base3DButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color topColor;
  final Color shadowColor;
  final BoxBorder? border;
  final double height;
  final bool isDisabled;
  final bool isLoading;
  final Color textColor;

  const _Base3DButton({
    required this.child,
    required this.onTap,
    required this.topColor,
    required this.shadowColor,
    this.border,
    required this.height,
    this.isDisabled = false,
    this.isLoading = false,
    required this.textColor,
  });

  @override
  State<_Base3DButton> createState() => _Base3DButtonState();
}

class _Base3DButtonState extends State<_Base3DButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double shadowHeight = 5.0;
    const double borderRadius = 16.0;

    final bool active = !widget.isDisabled && !widget.isLoading && widget.onTap != null;

    return GestureDetector(
      onTapDown: (_) {
        if (active) {
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        if (active) {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        }
      },
      onTapCancel: () {
        if (active) {
          setState(() => _isPressed = false);
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bottom Layer (Shadow)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: shadowHeight,
            child: Container(
              decoration: BoxDecoration(
                color: widget.shadowColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
          // Top Layer
          AnimatedPositioned(
            duration: const Duration(milliseconds: 60),
            curve: Curves.easeIn,
            left: 0,
            right: 0,
            top: _isPressed ? shadowHeight : 0,
            bottom: _isPressed ? 0 : shadowHeight,
            child: Container(
              decoration: BoxDecoration(
                color: widget.topColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: widget.border,
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: widget.textColor,
                          strokeWidth: 2.5,
                        ),
                      )
                    : widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
