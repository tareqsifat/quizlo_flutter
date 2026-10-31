import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';

/// ─────────────────────────────────────────────
/// Quiz Loading Screen
/// Full primary background + logo + animated dots
/// Matches Figma "Loading...." screen
/// ─────────────────────────────────────────────
class QuizLoadingScreen extends StatefulWidget {
  final int lessonId;
  final String lessonTitle;
  final String? subject;

  /// When set, launches the Topic-journey quiz instead of a lesson quiz.
  final int? topicId;

  const QuizLoadingScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    this.subject,
    this.topicId,
  });

  @override
  State<QuizLoadingScreen> createState() => _QuizLoadingScreenState();
}

class _QuizLoadingScreenState extends State<QuizLoadingScreen>
    with TickerProviderStateMixin {
  // One slow, continuous loop drives both the logo's breathing and the dot
  // wave, so nothing snaps or bounces.
  static const _loopDuration = Duration(milliseconds: 1800);
  static const _screenDuration = Duration(milliseconds: 3200);

  late final AnimationController _introController;
  late final AnimationController _loopController;
  late final Animation<double> _introFade;
  late final Animation<double> _introScale;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _introFade = CurvedAnimation(parent: _introController, curve: Curves.easeOut);
    _introScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );
    _introController.forward();

    _loopController = AnimationController(vsync: this, duration: _loopDuration)
      ..repeat();

    // Navigate after loading
    Future.delayed(_screenDuration, () {
      if (mounted) {
        context.pushReplacement(
          AppRoutes.quizSession,
          extra: {
            'lesson_id': widget.lessonId,
            'subject': widget.subject,
            'topic_id': widget.topicId,
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _introFade,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo ──────────────────────
                ScaleTransition(
                  scale: _introScale,
                  child: AnimatedBuilder(
                    animation: _loopController,
                    builder: (context, child) {
                      // Gentle breathing: 1.0 → 1.04 → 1.0 once per loop.
                      final t = _loopController.value;
                      final scale = 1.0 + 0.04 * math.sin(t * 2 * math.pi).abs();
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: const _QuizloWhiteLogo(),
                  ),
                ),
                const SizedBox(height: 48),

                // ── Loading text ──────────────
                Text(
                  'Loading....',
                  style: AppTextStyles.h3.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 24),

                // ── 3 Dots Indicator ──────────
                _WaveDotLoader(animation: _loopController),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizloWhiteLogo extends StatelessWidget {
  const _QuizloWhiteLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.quiz_rounded, size: 52, color: Colors.white),
      ),
    );
  }
}

/// Three dots that swell and turn orange one after another in a smooth,
/// continuous wave (each dot is a third of a loop behind the previous one).
class _WaveDotLoader extends StatelessWidget {
  final Animation<double> animation;

  const _WaveDotLoader({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            // 0 → 1 → 0 bump per dot, phase-shifted by a third of the loop.
            final phase = (animation.value - i / 3) % 1.0;
            final bump = math.max(0.0, math.sin(phase * 2 * math.pi));
            final size = 10.0 + 4.0 * bump;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 14,
              height: 14,
              alignment: Alignment.center,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Color.lerp(Colors.white38, AppColors.accent, bump),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
