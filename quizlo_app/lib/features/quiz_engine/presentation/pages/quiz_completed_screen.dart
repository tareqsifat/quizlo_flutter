import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_router.dart';

/// ─────────────────────────────────────────────
/// Quiz Completed Screen
/// Confetti + 3 stat cards + action buttons
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

class _QuizCompletedScreenState extends State<QuizCompletedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Confetti effect ───────────────
          ..._buildConfettiPieces(),

          // ── Main content ──────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // ── Trophy icon ───────
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('🏆', style: TextStyle(fontSize: 52)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Title ─────────────
                      Text(
                        'Quiz Completed!',
                        style: AppTextStyles.display1.copyWith(color: AppColors.primary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Excellent performance! Keep it up!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // ── Stats row ─────────
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.timer_rounded,
                              label: 'Time',
                              value: widget.timeTaken,
                              bgColor: AppColors.statGreenBg,
                              iconColor: AppColors.statGreen,
                              valueColor: AppColors.statGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.auto_graph_rounded,
                              label: 'Accuracy',
                              value: '${widget.accuracy}%',
                              bgColor: AppColors.statOrangeBg,
                              iconColor: AppColors.statOrange,
                              valueColor: AppColors.statOrange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.star_rounded,
                              label: 'Points',
                              value: '+${widget.points}',
                              bgColor: AppColors.statPurpleBg,
                              iconColor: AppColors.statPurple,
                              valueColor: AppColors.statPurple,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // ── Actions ───────────
                      SizedBox(
                        width: double.infinity,
                        height: AppSizes.buttonHeightLg,
                        child: ElevatedButton(
                          onPressed: () => context.go(AppRoutes.discover),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                            ),
                            elevation: 0,
                          ),
                          child: Text('Explore More Quizzes', style: AppTextStyles.buttonLarge),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: AppSizes.buttonHeightLg,
                        child: OutlinedButton(
                          onPressed: () => context.go(AppRoutes.rank),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                            ),
                          ),
                          child: Text(
                            'Check Leaderboard',
                            style: AppTextStyles.buttonLarge.copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildConfettiPieces() {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      AppColors.error,
      AppColors.info,
    ];
    return List.generate(30, (i) {
      final size = Size(
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height,
      );
      return Positioned(
        top: (i * 29.7) % size.height,
        left: (i * 43.1) % size.width,
        child: _ConfettiPiece(
          color: colors[i % colors.length],
          size: 6 + (i % 4) * 2.0,
          isCircle: i % 3 == 0,
        ),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color bgColor;
  final Color iconColor;
  final Color valueColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.bgColor,
    required this.iconColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(color: valueColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: iconColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ConfettiPiece extends StatelessWidget {
  final Color color;
  final double size;
  final bool isCircle;

  const _ConfettiPiece({required this.color, required this.size, required this.isCircle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(2),
      ),
    );
  }
}
