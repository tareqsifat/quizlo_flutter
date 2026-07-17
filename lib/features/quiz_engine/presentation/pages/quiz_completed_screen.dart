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
    final pointsEarned = widget.points;

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
              decoration: const BoxDecoration(
                color: Color(0xFFE1F5FE), // light blue
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
            const SizedBox(height: 48),

            // 3 Info Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.flash_on_rounded,
                    iconColor: const Color(0xFFFFB300),
                    value: '$pointsEarned',
                    label: 'TOTAL XP',
                    bgColor: const Color(0xFFFFF8E1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.adjust_rounded,
                    iconColor: const Color(0xFFE53935),
                    value: '${widget.accuracy}%',
                    label: 'ACCURACY',
                    bgColor: const Color(0xFFE1F5FE),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.timer_outlined,
                    iconColor: const Color(0xFF5C6BC0),
                    value: widget.timeTaken,
                    label: 'TIME',
                    bgColor: const Color(0xFFEDE7F6),
                  ),
                ),
              ],
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

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

            // Redesigned Blue Flame Badge
            Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: Color(0xFFE1F5FE), // light blue background
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Flame (darker blue)
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 96,
                    color: Color(0xFF0288D1),
                  ),
                  // Inner Flame (cyan)
                  const Positioned(
                    top: 42,
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      size: 60,
                      color: Color(0xFF29B6F6),
                    ),
                  ),
                  // White Circle with Streak Number Overlay
                  Positioned(
                    bottom: 24,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$streakCount',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0288D1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Redesigned Streak Titles
            Text(
              '$streakCount',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A2E),
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              'DAY STREAK',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0288D1),
                letterSpacing: 1.2,
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
            const SizedBox(height: 48),

            // Weekly day indicators (Saturday to Friday)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final isPracticed = practicedDays[index];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayLetters[index],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPracticed ? const Color(0xFF0288D1) : AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPracticed ? const Color(0xFF0288D1) : const Color(0xFFECEFF1),
                      ),
                      alignment: Alignment.center,
                      child: isPracticed
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
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
