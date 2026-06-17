import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/services/streak_service.dart';
import '../../../../core/services/feedback_service.dart';

/// ─────────────────────────────────────────────
/// Quiz Completed Screen
/// Multi-step flow: Page 1 (Lesson Complete) -> Page 2 (Streak Screen)
/// ─────────────────────────────────────────────
class QuizCompletedScreen extends StatefulWidget {
  final String timeTaken;
  final int accuracy;
  final int points;

  const QuizCompletedScreen({
    super.key,
    required this.timeTaken,
    required this.accuracy,
    required this.points,
  });

  @override
  State<QuizCompletedScreen> createState() => _QuizCompletedScreenState();
}

class _QuizCompletedScreenState extends State<QuizCompletedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    FeedbackService.playLessonComplete();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Force navigation via CONTINUE button
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: [
          _buildLessonCompletePage(),
          _buildStreakPage(),
        ],
      ),
    );
  }

  Widget _buildLessonCompletePage() {
    final dailyGoal = HiveStorage.getDailyGoal();
    final pointsEarned = widget.points;
    final remainingXp = (dailyGoal - pointsEarned).clamp(0, dailyGoal);
    final progressFraction = (pointsEarned / dailyGoal).clamp(0.0, 1.0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Celebratory Emoji Badge
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🎉', style: TextStyle(fontSize: 72)),
              ),
            ),
            const SizedBox(height: 32),

            // Header Text
            Text(
              'Lesson Complete!',
              style: AppTextStyles.display1.copyWith(
                color: AppColors.primary,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '+$pointsEarned XP',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.accent,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Progress bar to daily goal
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(50),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressFraction,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentLight],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              remainingXp > 0
                  ? 'Earn another $remainingXp XP today to reach your daily goal'
                  : 'Daily goal achieved! Excellent work!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(flex: 3),

            // Continue Button (routes to next slide)
            AppButton(
              label: 'CONTINUE',
              onTap: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakPage() {
    final streakCount = HiveStorage.getStreakCount();
    final practicedDays = StreakService.getPracticedDaysOfWeek(); // List of 7 booleans
    final dayLetters = ['S', 'S', 'M', 'T', 'W', 'T', 'F'];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Large Flame Badge with Streak Number
            Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 160,
                  color: AppColors.streakOrange,
                ),
                Positioned(
                  bottom: 30,
                  child: Text(
                    '$streakCount',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Streak Title
            Text(
              '$streakCount Day Streak!',
              style: AppTextStyles.display1.copyWith(
                color: AppColors.streakOrange,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Complete a lesson every day to build your streak',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Weekly day indicators (Saturday to Friday)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final isPracticed = practicedDays[index];
                return Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 38,
                          color: isPracticed ? AppColors.streakOrange : AppColors.divider,
                        ),
                        Positioned(
                          bottom: 7,
                          child: Text(
                            dayLetters[index],
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isPracticed ? Colors.white : AppColors.textHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),

            const Spacer(flex: 3),

            // Continue Button (routes to Home / Discover)
            AppButton(
              label: 'CONTINUE',
              onTap: () {
                context.go(AppRoutes.home);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
