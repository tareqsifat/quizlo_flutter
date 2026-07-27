import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/storage/hive_storage.dart';

/// ─────────────────────────────────────────────
/// Leaderboard Repository — Weekly league ranking
/// Backed by the league/leaderboard endpoint, which
/// scopes ranking to the user's current league season
/// (weekly_xp resets every week — see League module).
/// ─────────────────────────────────────────────

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(DioClient());
});

/// Re-fetch by calling `ref.refresh(leaderboardProvider.future)`.
final leaderboardProvider = FutureProvider.autoDispose<LeaderboardData?>((ref) async {
  // Demo Mode has no real backend account behind it (see HiveStorage.isDemoMode
  // usage across the app — quiz answers, streaks, profile all short-circuit to
  // fixed local data). A brand-new demo account would otherwise always hit the
  // empty state here, so show a populated board instead.
  if (HiveStorage.isDemoMode()) {
    return LeaderboardData.demo();
  }

  final examTypeId = HiveStorage.getActiveExamTypeId() ?? 1;
  return ref.watch(leaderboardRepositoryProvider).getLeaderboard(examTypeId: examTypeId);
});

class RankEntry {
  final int rank;
  final int userId;
  final String name;
  final int xp;
  final bool isCurrentUser;

  const RankEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.xp,
    required this.isCurrentUser,
  });

  factory RankEntry.fromJson(Map<String, dynamic> json) => RankEntry(
        rank: json['rank'] as int,
        userId: json['user_id'] as int,
        name: json['name'] as String? ?? 'Learner',
        xp: json['xp'] as int,
        isCurrentUser: json['is_current_user'] as bool? ?? false,
      );
}

class LeaderboardData {
  final int weekNumber;
  final String tier;
  final List<RankEntry> entries;

  /// Non-null only when the current user falls outside [entries] —
  /// their live rank, appended so they're never left off the board.
  final RankEntry? currentUserOutsideTop;
  final int totalParticipants;

  const LeaderboardData({
    required this.weekNumber,
    required this.tier,
    required this.entries,
    required this.currentUserOutsideTop,
    required this.totalParticipants,
  });

  /// The current user's row, wherever it lives — inside [entries] or
  /// appended separately. Null only if the user has no entry at all.
  RankEntry? get myEntry {
    for (final entry in entries) {
      if (entry.isCurrentUser) return entry;
    }
    return currentUserOutsideTop;
  }

  /// Curated standings for Demo Mode (no live backend account behind it).
  /// "Demo User" is placed at a solid, encouraging rank rather than #1 —
  /// realistic, and it still shows off the top-3 treatment above them.
  factory LeaderboardData.demo() {
    return LeaderboardData(
      weekNumber: _currentWeekNumber(),
      tier: 'Bronze',
      entries: buildDemoStandings(demoUserRank: 6),
      currentUserOutsideTop: null,
      totalParticipants: 27,
    );
  }

  factory LeaderboardData.fromJson(Map<String, dynamic> json) => LeaderboardData(
        weekNumber: json['week_number'] as int,
        tier: json['tier'] as String? ?? 'Bronze',
        entries: (json['entries'] as List)
            .map((e) => RankEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentUserOutsideTop: json['current_user'] != null
            ? RankEntry.fromJson(json['current_user'] as Map<String, dynamic>)
            : null,
        totalParticipants: json['total_participants'] as int? ?? 0,
      );
}

/// Fixed demo-mode roster (everyone but "Demo User"), shared between the
/// static Rank tab and the post-quiz leaderboard reveal animation so both
/// show the same 11 people — only the current user's slot moves.
const List<String> demoOtherNames = [
  'Tanvir Ahmed',
  'Nusrat Jahan',
  'Rakibul Islam',
  'Sadia Afrin',
  'Mehedi Hasan',
  'Farzana Akter',
  'Shakib Al Rahman',
  'Jannatul Ferdous',
  'Imran Kabir',
  'Tasnim Rahman',
  'Arif Hossain',
];

/// One XP value per rank slot (1..12) — since XP is descending by rank,
/// whoever occupies a slot gets that slot's number.
const List<int> demoXpBySlot = [640, 590, 560, 520, 480, 450, 420, 390, 360, 330, 300, 270];

int get demoTotalSlots => demoOtherNames.length + 1;

/// Builds a demo standings list with "Demo User" inserted at [demoUserRank]
/// (1-indexed) and [otherNames] filling the rest in their fixed order.
/// Defaults to the full 12-person board; the leaderboard reveal animation
/// passes a smaller slice so the whole jump fits on screen at once.
List<RankEntry> buildDemoStandings({
  required int demoUserRank,
  List<String> otherNames = demoOtherNames,
  List<int> xpBySlot = demoXpBySlot,
}) {
  final totalSlots = otherNames.length + 1;
  var clampedRank = demoUserRank;
  if (clampedRank < 1) clampedRank = 1;
  if (clampedRank > totalSlots) clampedRank = totalSlots;
  final names = List<String>.from(otherNames)..insert(clampedRank - 1, 'Demo User');

  return List.generate(names.length, (i) {
    return RankEntry(
      rank: i + 1,
      userId: i + 1,
      name: names[i],
      xp: xpBySlot[i],
      isCurrentUser: names[i] == 'Demo User',
    );
  });
}

int _currentWeekNumber() {
  final now = DateTime.now();
  final startOfYear = DateTime(now.year, 1, 1);
  return (now.difference(startOfYear).inDays / 7).ceil() + 1;
}

class LeaderboardRepository {
  final DioClient _client;

  LeaderboardRepository(this._client);

  /// Returns null when the user hasn't joined this week's league yet
  /// (no questions answered) — the screen shows an encouraging empty
  /// state rather than treating this as an error.
  Future<LeaderboardData?> getLeaderboard({required int examTypeId}) async {
    try {
      final response = await _client.get(
        ApiEndpoints.leagueLeaderboard,
        queryParams: {'exam_type_id': examTypeId},
      );
      final data = response.data['data'];
      if (data == null) return null;
      return LeaderboardData.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data as Map<String, dynamic>? ?? {},
        e.response?.statusCode,
      );
    }
  }
}
