import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../data/leaderboard_repository.dart';

/// ─────────────────────────────────────────────
/// Rank Row — a single leaderboard entry
/// Shared between the Rank tab and the post-quiz
/// leaderboard reveal animation, so both look the same.
/// ─────────────────────────────────────────────
class RankRow extends StatelessWidget {
  final RankEntry entry;

  const RankRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isTopThree = entry.rank <= 3;
    final badgeColor = switch (entry.rank) {
      1 => AppColors.rankGold,
      2 => AppColors.rankSilver,
      3 => AppColors.rankBronze,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser ? AppColors.primarySurface : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: entry.isCurrentUser
            ? Border.all(color: AppColors.primary, width: 1.5)
            : (isTopThree ? Border.all(color: badgeColor.withOpacity(0.35), width: 1) : null),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          // ── Rank badge ──────────────────────
          SizedBox(
            width: 32,
            child: isTopThree
                ? Icon(Icons.emoji_events_rounded, color: badgeColor, size: 26)
                : Text(
                    '${entry.rank}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                  ),
          ),
          const SizedBox(width: 10),
          // ── Avatar ──────────────────────────
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isTopThree ? badgeColor : AppColors.primary).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isTopThree ? badgeColor : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ── Name ────────────────────────────
          Expanded(
            child: Text(
              entry.isCurrentUser ? '${entry.name} (You)' : entry.name,
              style: AppTextStyles.labelLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // ── XP ──────────────────────────────
          Text(
            '${entry.xp} XP',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
