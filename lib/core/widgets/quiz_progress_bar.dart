import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_sizes.dart';

/// ─────────────────────────────────────────────
/// Quiz Progress Bar
/// Shows linear progress + X/10 counter
/// Matches the thin purple bar in Figma screens
/// ─────────────────────────────────────────────
class QuizProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final bool showCounter;

  const QuizProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.showCounter = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Bar ───────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: AppSizes.progressBarHeight,
              backgroundColor: AppColors.progressTrack,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.progressFill),
            ),
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────
/// Quiz App Bar — shows X/10 + menu icon
/// ─────────────────────────────────────────────
class QuizAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int current;
  final int total;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;

  const QuizAppBar({
    super.key,
    required this.current,
    required this.total,
    this.onBack,
    this.onMenu,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            '$current/$total',
            style: AppTextStyles.h4,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, size: 22),
              onPressed: onMenu,
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
          child: QuizProgressBar(current: current, total: total),
        ),
      ],
    );
  }
}
