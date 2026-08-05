import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../data/leaderboard_repository.dart';
import '../widgets/rank_row.dart';

/// ─────────────────────────────────────────────
/// Leaderboard Reveal — post-quiz "before -> after" rank jump.
///
/// A page in the post-quiz journey (Lesson Complete -> Streak -> this),
/// showing the user climbing the weekly leaderboard.
///
/// - Demo Mode ([beforeLeaderboard] null): a fresh "before" and "after"
///   rank is picked at random every time it's shown, animating a fixed
///   simulated roster.
/// - Live Mode ([beforeLeaderboard] non-null, captured by
///   [QuizSessionScreen] right before this session's answers changed the
///   user's XP): fetches the real current standing and animates from the
///   real "before" rank to the real "after" rank.
/// ─────────────────────────────────────────────
class LeaderboardRevealPage extends StatefulWidget {
  final VoidCallback onContinue;
  final LeaderboardData? beforeLeaderboard;

  const LeaderboardRevealPage({
    super.key,
    required this.onContinue,
    this.beforeLeaderboard,
  });

  @override
  State<LeaderboardRevealPage> createState() => _LeaderboardRevealPageState();
}

class _LeaderboardRevealPageState extends State<LeaderboardRevealPage> {
  static const _rowHeight = 68.0;

  // A smaller slice of the roster so the full before/after jump always
  // fits on screen without needing to scroll mid-animation.
  static final List<String> _otherNames = demoOtherNames.sublist(0, 7);
  static final List<int> _xpBySlot = demoXpBySlot.sublist(0, 8);

  bool get _isLive => widget.beforeLeaderboard != null;

  int _totalSlots = _otherNames.length + 1;
  int _initialRank = 1;
  int _afterRank = 1;
  List<RankEntry> _standings = [];
  bool _hasJumped = false;
  bool _improved = false;
  bool _showContinue = false;

  @override
  void initState() {
    super.initState();
    if (_isLive) {
      _initLive();
    } else {
      _initDemo();
    }
  }

  void _initDemo() {
    final random = Random();
    _totalSlots = _otherNames.length + 1;
    // "Before": somewhere in the lower half of this small board.
    final beforeSpan = _totalSlots - 3; // leaves room for at least a 2-spot jump
    _initialRank = 4 + random.nextInt(beforeSpan > 0 ? beforeSpan : 1);
    // "After": a real improvement — at least 2 spots up, sometimes top 3.
    final maxAfter = _initialRank - 2 < 1 ? 1 : _initialRank - 2;
    _afterRank = 1 + random.nextInt(maxAfter);

    _standings = buildDemoStandings(
      demoUserRank: _initialRank,
      otherNames: _otherNames,
      xpBySlot: _xpBySlot,
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _standings = buildDemoStandings(
          demoUserRank: _afterRank,
          otherNames: _otherNames,
          xpBySlot: _xpBySlot,
        );
        _hasJumped = true;
        _improved = true;
      });
    });

    Future.delayed(const Duration(milliseconds: 1200 + 900), () {
      if (!mounted) return;
      setState(() => _showContinue = true);
    });
  }

  Future<void> _initLive() async {
    final before = widget.beforeLeaderboard!;
    final beforeStandings = _clampedRealStandings(before);
    setState(() {
      _standings = beforeStandings;
      _totalSlots = beforeStandings.length;
      _initialRank = before.myEntry?.rank ?? beforeStandings.length;
      _afterRank = _initialRank;
    });

    final examTypeId = HiveStorage.getActiveExamTypeId() ?? 1;
    LeaderboardData? after;
    try {
      after = await LeaderboardRepository(DioClient()).getLeaderboard(examTypeId: examTypeId);
    } catch (_) {
      after = null;
    }

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (after != null) {
      final afterStandings = _clampedRealStandings(after);
      final afterRank = after.myEntry?.rank ?? _initialRank;
      setState(() {
        _standings = afterStandings;
        _totalSlots = max(_totalSlots, afterStandings.length);
        _afterRank = afterRank;
        _hasJumped = afterRank != _initialRank;
        _improved = afterRank < _initialRank;
      });
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _showContinue = true);
  }

  /// Top 7 real entries plus the current user's row appended if they fall
  /// outside that slice — mirrors Demo Mode's fixed 8-row board so the
  /// animation always fits on screen.
  List<RankEntry> _clampedRealStandings(LeaderboardData data) {
    final top = data.entries.take(7).toList();
    final userInTop = top.any((e) => e.isCurrentUser);
    if (!userInTop && data.currentUserOutsideTop != null) {
      top.add(data.currentUserOutsideTop!);
    }
    return top;
  }

  @override
  Widget build(BuildContext context) {
    // Position rows by their index within the current standings (sorted by
    // rank) rather than the raw rank number, so a real "outside top 7" row
    // (e.g. rank 42) still lands on the next slot instead of far off-screen.
    final sorted = List<RankEntry>.from(_standings)
      ..sort((a, b) => a.rank.compareTo(b.rank));
    final slotOf = <int, int>{
      for (var i = 0; i < sorted.length; i++) sorted[i].userId: i,
    };

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text('🚀', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              _titleText,
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _subtitleText,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: _rowHeight * _totalSlots,
              child: Stack(
                // Current user's row must stay painted on top of the others
                // while they reflow past each other mid-animation, so it's
                // ordered last in the Stack regardless of current rank.
                children: [
                  ..._standings.where((entry) => !entry.isCurrentUser),
                  ..._standings.where((entry) => entry.isCurrentUser),
                ].map((entry) {
                  final slot = slotOf[entry.userId] ?? (entry.rank - 1);
                  return AnimatedPositioned(
                    key: ValueKey(entry.userId),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInOut,
                    top: slot * _rowHeight,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RankRow(entry: entry),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
            AnimatedOpacity(
              opacity: _showContinue ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: IgnorePointer(
                ignoring: !_showContinue,
                child: AppButton(
                  label: 'CONTINUE',
                  onTap: widget.onContinue,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String get _titleText {
    if (!_hasJumped) return "This week's ranking";
    return _improved ? 'You moved up!' : 'Your rank updated';
  }

  String get _subtitleText {
    if (!_hasJumped) return "Let's see where you stand…";
    return _improved
        ? 'Great job — keep answering questions to climb even higher.'
        : 'Keep practicing to climb the ranks.';
  }
}
