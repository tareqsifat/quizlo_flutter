import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/domain/entities.dart';

/// ─────────────────────────────────────────────
/// Topic Node — one checkpoint bubble in the journey path.
///
/// Kept deliberately isolated from the screen's layout/scroll logic so the
/// exact visual (size, decoration, icon) can be swapped once the reference
/// screenshot arrives, without touching data loading or navigation.
/// ─────────────────────────────────────────────
class TopicNode extends StatelessWidget {
  final Topic topic;
  final VoidCallback? onTap;

  /// Label under the bubble (the Bangla name for Bangla subjects).
  final String title;

  static const double diameter = 76.0;

  // Progress ring drawn around the bubble, with a small gap between them.
  static const double _ringStroke = 6.0;
  static const double _ringGap = 4.0;
  static const double _ringDiameter = diameter + 2 * (_ringGap + _ringStroke);

  const TopicNode({
    super.key,
    required this.topic,
    required this.title,
    this.onTap,
  });

  bool get _isLocked => topic.status == TopicStatus.locked;
  bool get _isCompleted => topic.status == TopicStatus.completed;
  bool get _isCurrent => topic.status == TopicStatus.current;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _isLocked ? null : onTap,
          child: SizedBox(
            width: _ringDiameter,
            height: _ringDiameter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Right answers / total questions; fills in when the list loads
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: topic.progress),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: _ringStroke,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(AppColors.success),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: diameter,
                  height: diameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _fillColor,
                    border: Border.all(color: _borderColor, width: 3),
                    boxShadow: _isLocked
                        ? null
                        : [
                            BoxShadow(
                              color: _borderColor.withOpacity(0.35),
                              blurRadius: AppSizes.shadowBlurMd,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Icon(_icon, color: _iconColor, size: AppSizes.iconXl),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        SizedBox(
          width: _ringDiameter + 24,
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: _isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: _isLocked ? AppColors.textHint : AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          '${topic.correctCount}/${topic.questionCount}',
          style: AppTextStyles.bodySmall.copyWith(
            color: _isLocked ? AppColors.textHint : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color get _fillColor {
    if (_isCompleted) return AppColors.success;
    if (_isCurrent) return AppColors.primary;
    return AppColors.scaffoldBg;
  }

  Color get _borderColor {
    if (_isCompleted) return AppColors.success;
    if (_isCurrent) return AppColors.primaryDark;
    return AppColors.border;
  }

  Color get _iconColor {
    if (_isLocked) return AppColors.textHint;
    return AppColors.textWhite;
  }

  IconData get _icon {
    if (_isCompleted) return Icons.check_rounded;
    if (_isLocked) return Icons.lock_rounded;
    return Icons.star_rounded;
  }
}
