import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/global_top_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/leaderboard_repository.dart';
import '../widgets/rank_row.dart';

/// ─────────────────────────────────────────────
/// Rank Screen — This week's leaderboard
/// Ranking is scoped to the user's current league
/// season/group (weekly_xp, resets every week).
/// The current user is always represented, even
/// when they fall outside the visible top range.
/// ─────────────────────────────────────────────
class RankScreen extends ConsumerStatefulWidget {
  const RankScreen({super.key});

  @override
  ConsumerState<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends ConsumerState<RankScreen> {
  final GlobalKey _myRowKey = GlobalKey();

  void _scrollToMyRow() {
    final ctx = _myRowKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            const GlobalTopBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding, 0, AppSizes.screenPadding, 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('This Week\'s Ranking', style: AppTextStyles.h3),
                        const SizedBox(height: 2),
                        Text(
                          'Keep answering questions to climb up!',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: leaderboardAsync.when(
                loading: () => const _LoadingState(),
                error: (error, stack) => _ErrorState(
                  onRetry: () => ref.invalidate(leaderboardProvider),
                ),
                data: (data) {
                  if (data == null || data.myEntry == null) {
                    return _EmptyState(
                      onRefresh: () => ref.refresh(leaderboardProvider.future),
                    );
                  }
                  return _LeaderboardList(
                    data: data,
                    myRowKey: _myRowKey,
                    onScrollToMe: _scrollToMyRow,
                    onRefresh: () => ref.refresh(leaderboardProvider.future),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final LeaderboardData data;
  final GlobalKey myRowKey;
  final VoidCallback onScrollToMe;
  final Future<void> Function() onRefresh;

  const _LeaderboardList({
    required this.data,
    required this.myRowKey,
    required this.onScrollToMe,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final showJumpToMe = data.currentUserOutsideTop != null;
    final itemCount = data.entries.length + (showJumpToMe ? 2 : 0);

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primary,
          onRefresh: onRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSizes.screenPadding, 0, AppSizes.screenPadding,
              showJumpToMe ? 90 : AppSizes.bottomNavHeight + 20,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index < data.entries.length) {
                final entry = data.entries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RankRow(
                    key: entry.isCurrentUser ? myRowKey : null,
                    entry: entry,
                  ),
                );
              }
              if (index == data.entries.length) {
                return const _GapDivider();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RankRow(
                  key: myRowKey,
                  entry: data.currentUserOutsideTop!,
                ),
              );
            },
          ),
        ),
        if (showJumpToMe)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: _JumpToMeButton(
                rank: data.currentUserOutsideTop!.rank,
                onTap: onScrollToMe,
              ),
            ),
          ),
      ],
    );
  }
}

class _GapDivider extends StatelessWidget {
  const _GapDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(
          '· · ·',
          style: AppTextStyles.h4.copyWith(color: AppColors.textHint, letterSpacing: 4),
        ),
      ),
    );
  }
}

class _JumpToMeButton extends StatelessWidget {
  final int rank;
  final VoidCallback onTap;

  const _JumpToMeButton({required this.rank, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Your rank: #$rank',
                style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Loading this week\'s ranking…', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              'Couldn\'t load the leaderboard',
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Check your connection and try again.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              label: const Text('Try again', style: TextStyle(fontFamily: 'Poppins', color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.emoji_events_outlined, size: 56, color: AppColors.accent),
          const SizedBox(height: 16),
          Text(
            'Your spot on the leaderboard\nis waiting for you',
            textAlign: TextAlign.center,
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: 8),
          Text(
            'Answer a few questions this week and\nyou\'ll show up here — every point counts.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 200,
              child: AppButton(
                label: 'Start a Quiz',
                onTap: () => context.go(AppRoutes.home),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
