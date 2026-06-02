import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';

/// ─────────────────────────────────────────────
/// Quiz Loading Screen
/// Full purple background + logo + animated dots
/// Matches Figma "Loading...." screen exactly
/// ─────────────────────────────────────────────
class QuizLoadingScreen extends StatefulWidget {
  final int lessonId;
  final String lessonTitle;

  const QuizLoadingScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<QuizLoadingScreen> createState() => _QuizLoadingScreenState();
}

class _QuizLoadingScreenState extends State<QuizLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _dotsController;
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  int _activeDot = 0;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoController.forward();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _activeDot = (_activeDot + 1) % 3);
          _dotsController.reset();
          _dotsController.forward();
        }
      });
    _dotsController.forward();

    // Navigate after loading
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.pushReplacement(
          AppRoutes.quizSession,
          extra: {'lesson_id': widget.lessonId},
        );
      }
    });
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo ──────────────────────
              ScaleTransition(
                scale: _logoScale,
                child: _QuizloWhiteLogo(),
              ),
              const SizedBox(height: 48),

              // ── Loading text ──────────────
              Text(
                'Loading....',
                style: AppTextStyles.h3.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 24),

              // ── 3 Dots Indicator ──────────
              _ThreeDotLoader(activeDot: _activeDot),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizloWhiteLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.quiz_rounded, size: 52, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _ThreeDotLoader extends StatelessWidget {
  final int activeDot;

  const _ThreeDotLoader({required this.activeDot});

  static const _dotColors = [
    Colors.white54,
    AppColors.accent,
    AppColors.accent,
  ];

  @override
  Widget build(BuildContext context) {
    // Pattern from Figma: white · orange · orange (cycling)
    final dots = [
      Colors.white54,
      AppColors.accent,
      AppColors.accent,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == activeDot;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 14 : 10,
          height: isActive ? 14 : 10,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : Colors.white38,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
