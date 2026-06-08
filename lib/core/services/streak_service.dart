import 'package:intl/intl.dart';
import '../../features/quiz_engine/data/quiz_repository.dart';
import '../storage/hive_storage.dart';
import '../network/dio_client.dart';

class StreakService {
  /// Update the user streak count based on lesson completion.
  /// Handles both Demo Mode (fully local memory) and Normal Mode (API + local sync).
  static Future<int> updateStreak({required int lessonId, required int score}) async {
    // 1. Calculate and update local memory streak (for both demo and normal)
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    final lastPractice = HiveStorage.getLastPracticeDate();
    int currentStreak = HiveStorage.getStreakCount();
    final practicedDates = HiveStorage.getPracticedDates();

    if (lastPractice.isEmpty) {
      // First time practicing
      currentStreak = 1;
    } else if (lastPractice == todayStr) {
      // Already practiced today, streak doesn't change
    } else if (lastPractice == yesterdayStr) {
      // Continued streak!
      currentStreak += 1;
    } else {
      // Streak broken, reset to 1
      currentStreak = 1;
    }

    // Update last practice date
    await HiveStorage.setLastPracticeDate(todayStr);
    await HiveStorage.setStreakCount(currentStreak);

    // Add to practiced dates list if not already present
    if (!practicedDates.contains(todayStr)) {
      practicedDates.add(todayStr);
      await HiveStorage.setPracticedDates(practicedDates);
    }

    // 2. For Normal Mode (non-demo), call API to register completion on backend
    if (!HiveStorage.isDemoMode()) {
      try {
        final examTypeId = HiveStorage.getActiveExamTypeId() ?? 1;
        final repository = QuizRepository(DioClient());
        final data = await repository.completeLesson(
          lessonId: lessonId,
          examTypeId: examTypeId,
          score: score,
        );

        // If backend returns updated streak/coins/xp, sync it to user profile cache
        final userProfile = HiveStorage.getUserProfile();
        if (userProfile != null) {
          if (data.containsKey('total_xp')) {
            userProfile['xp'] = data['total_xp'];
          }
          if (data.containsKey('coin_balance')) {
            userProfile['coins'] = data['coin_balance'];
          }
          // The backend might track streak too, but if it doesn't return it here,
          // we make sure user profile's streakDays matches our calculated local streak
          userProfile['streakDays'] = currentStreak;
          await HiveStorage.saveUserProfile(userProfile);
        }
      } catch (e) {
        // Silently catch network issues to ensure offline resilience
      }
    } else {
      // Demo mode: sync profile streak too
      final userProfile = HiveStorage.getUserProfile();
      if (userProfile != null) {
        userProfile['streakDays'] = currentStreak;
        await HiveStorage.saveUserProfile(userProfile);
      }
    }

    return currentStreak;
  }

  /// Get the practiced state of the current week (Saturday to Friday)
  /// Returns a list of 7 booleans indicating whether the user practiced on that day.
  static List<bool> getPracticedDaysOfWeek() {
    final now = DateTime.now();
    // Saturday to Friday logic:
    // Determine number of days to subtract to get to the most recent Saturday
    int daysSinceSaturday = now.weekday == DateTime.saturday
        ? 0
        : now.weekday == DateTime.sunday
            ? 1
            : now.weekday + 1;

    final saturday = now.subtract(Duration(days: daysSinceSaturday));
    final practicedDates = HiveStorage.getPracticedDates();

    return List.generate(7, (index) {
      final date = saturday.add(Duration(days: index));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      return practicedDates.contains(dateStr);
    });
  }
}
