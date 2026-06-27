import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/services/app_toast.dart';

/// ─────────────────────────────────────────────
/// Splash Screen
/// Shows logo + auto-navigates based on state.
/// Displays a live status text so any freeze is visible on screen.
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

  // Live status text shown at bottom of splash — tracks each step
  String _statusText = 'Starting…';

  void _setStatus(String text) {
    debugPrint('[SPLASH_STATUS] $text');
    // Native toast (works even if UI is partially frozen)
    Fluttertoast.showToast(
      msg: text,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: const Color(0xFF1A1A2E),
      textColor: Colors.white,
      fontSize: 13.0,
    );
    // On-screen status text (visible even without ScaffoldMessenger)
    if (mounted) {
      setState(() => _statusText = text);
    }
  }

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

    // ── Check auth with 5s timeout ─────────────────────────────────
    // flutter_secure_storage on Android can hang if the Keystore is
    // locked/initializing → timeout prevents permanent black/frozen screen.
    _setStatus('🔐 Checking auth…');
    bool isAuth = false;
    try {
      isAuth = await SecureStorage.isAuthenticated().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _setStatus('⚠️ Auth check timed out — going to login');
          AppToast.showError('Auth timed out. Please sign in again.');
          return false;
        },
      );
      _setStatus(isAuth ? '✅ Auth OK' : '🔓 Not signed in');
    } catch (e) {
      _setStatus('❌ Auth error: $e');
      AppToast.showError('Auth check failed: $e');
      isAuth = false;
    }

    if (!mounted) return;

    _setStatus('📦 Reading local prefs…');
    final isOnboarded = HiveStorage.isOnboardingDone();
    final hasExamType = HiveStorage.isExamTypeSelected();

    debugPrint('[SPLASH] isAuth=$isAuth isOnboarded=$isOnboarded hasExamType=$hasExamType');

    if (!isOnboarded) {
      _setStatus('➡️ Opening onboarding…');
      if (mounted) context.go(AppRoutes.onboarding);
    } else if (!isAuth) {
      _setStatus('➡️ Opening login…');
      if (mounted) context.go(AppRoutes.authLanding);
    } else if (!hasExamType) {
      _setStatus('➡️ Opening exam setup…');
      if (mounted) context.go(AppRoutes.examTypeSelection);
    } else {
      _setStatus('➡️ Opening home…');
      if (mounted) context.go(AppRoutes.home);
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
      body: Stack(
        children: [
          // ── Logo (centre) ───────────────────────
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: _QuizloLogo(),
              ),
            ),
          ),

          // ── Live status text (bottom) ────────────
          // Always visible; shows exactly which step is running.
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _statusText,
                key: ValueKey<String>(_statusText),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
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
