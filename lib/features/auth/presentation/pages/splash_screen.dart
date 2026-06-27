import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/services/app_toast.dart';

/// ─────────────────────────────────────────────
/// Splash Screen
/// Shows logo + auto-navigates based on state
/// ─────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    // ── CRITICAL: wrap auth check with a timeout ───────────────
    // On Android, flutter_secure_storage with encryptedSharedPreferences
    // can hang when the Keystore is locked (fresh boot / encrypted device).
    // Without a timeout the splash screen freezes forever — black screen.
    bool isAuth = false;
    try {
      isAuth = await SecureStorage.isAuthenticated()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('[SPLASH] ⚠️ Auth check timed out — falling back to unauthenticated');
        AppToast.show(
          '⚠️ Auth check timed out. Please try again.',
          isError: true,
          duration: const Duration(seconds: 7),
        );
        return false;
      });
    } catch (e) {
      debugPrint('[SPLASH] ❌ Auth check error: $e');
      AppToast.showError('Startup error: $e');
      isAuth = false;
    }

    if (!mounted) return;
    final isOnboarded = HiveStorage.isOnboardingDone();
    final hasExamType = HiveStorage.isExamTypeSelected();

    debugPrint('[SPLASH] → isAuth=$isAuth isOnboarded=$isOnboarded hasExamType=$hasExamType');

    if (!isOnboarded) {
      context.go(AppRoutes.onboarding);
    } else if (!isAuth) {
      context.go(AppRoutes.authLanding);
    } else if (!hasExamType) {
      context.go(AppRoutes.examTypeSelection);
    } else {
      context.go(AppRoutes.home);
    }
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
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: _QuizloLogo(),
          ),
        ),
      ),
    );
  }
}

class _QuizloLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Icon Mark ─────────────────────────
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primarySurface,
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(60, 60),
              painter: _QuizloIconPainter(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // ── Wordmark ──────────────────────────
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Quiz',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const TextSpan(
                text: 'Lo',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the Q checkmark icon
class _QuizloIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Draw a Q-like shape
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    canvas.drawCircle(center, radius, paint);

    // Checkmark inside
    final checkPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.50)
      ..lineTo(size.width * 0.43, size.height * 0.65)
      ..lineTo(size.width * 0.68, size.height * 0.38);
    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
