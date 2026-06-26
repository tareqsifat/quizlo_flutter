import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/onboarding_screen.dart';
import '../../features/auth/presentation/pages/auth_landing_screen.dart';
import '../../features/auth/presentation/pages/sign_in_screen.dart';
import '../../features/auth/presentation/pages/forgot_password_screen.dart';
import '../../features/auth/presentation/pages/otp_verification_screen.dart';
import '../../features/auth/presentation/pages/create_new_password_screen.dart';

import '../../features/exam_type/presentation/pages/stack_selection_screen.dart';
import '../../features/dashboard/presentation/pages/coming_soon_screen.dart';
import '../../features/dashboard/presentation/pages/subject_selection_screen.dart';
import '../../features/dashboard/presentation/pages/main_shell.dart';
import '../../features/dashboard/presentation/pages/home_screen.dart';
import '../../features/dashboard/presentation/pages/discover_screen.dart';
import '../../features/quiz_engine/presentation/pages/quiz_loading_screen.dart';
import '../../features/quiz_engine/presentation/pages/quiz_session_screen.dart';
import '../../features/quiz_engine/presentation/pages/quiz_completed_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../storage/secure_storage.dart';
import '../storage/hive_storage.dart';

/// ─────────────────────────────────────────────
/// Route Names — type-safe navigation
/// ─────────────────────────────────────────────
abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String authLanding = '/auth';
  static const String signIn = '/auth/sign-in';
  static const String forgotPassword = '/auth/forgot-password';
  static const String otpVerification = '/auth/otp';
  static const String createNewPassword = '/auth/create-password';
  static const String passwordChanged = '/auth/password-changed';
  static const String examTypeSelection = '/exam-type-selection';
  static const String comingSoon = '/coming-soon';
  static const String home = '/home';
  static const String discover = '/discover';
  static const String quizLoading = '/quiz/loading';
  static const String quizSession = '/quiz/session';
  static const String quizCompleted = '/quiz/completed';
  static const String profile = '/profile';
  static const String library = '/library';
  static const String rank = '/rank';
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// ─────────────────────────────────────────────
/// App Router Provider
/// ─────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,

    // Route guard — redirect unauthenticated users
    redirect: (context, state) async {
      final isAuth = await SecureStorage.isAuthenticated();
      final isOnboarded = await _isOnboardingDone();
      final hasExamType = await _hasExamTypeSelected();

      final currentPath = state.matchedLocation;
      final publicPaths = [
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.authLanding,
        AppRoutes.signIn,
        AppRoutes.forgotPassword,
        AppRoutes.otpVerification,
        AppRoutes.createNewPassword,
        AppRoutes.passwordChanged,
      ];

      if (!isAuth && !publicPaths.contains(currentPath)) {
        return AppRoutes.authLanding;
      }
      if (isAuth && !hasExamType && currentPath != AppRoutes.examTypeSelection) {
        return AppRoutes.examTypeSelection;
      }
      return null;
    },

    routes: [
      // ── Splash ───────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Onboarding ───────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Auth ─────────────────────────────────
      GoRoute(
        path: AppRoutes.authLanding,
        builder: (context, state) => const AuthLandingScreen(),
        routes: [
          GoRoute(
            path: 'sign-in',
            builder: (context, state) => const SignInScreen(),
          ),
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: 'otp',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return OtpVerificationScreen(
                email: extra?['email'] as String? ?? '',
                purpose: extra?['purpose'] as String? ?? 'forgot_password',
              );
            },
          ),
          GoRoute(
            path: 'create-password',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return CreateNewPasswordScreen(
                email: extra?['email'] as String? ?? '',
                token: extra?['token'] as String? ?? '',
              );
            },
          ),
          GoRoute(
            path: 'password-changed',
            builder: (context, state) => const PasswordChangedScreen(),
          ),
        ],
      ),

      // ── Exam Type Selection (new users) ──────
      GoRoute(
        path: AppRoutes.examTypeSelection,
        builder: (context, state) => const StackSelectionScreen(),
      ),

      // ── Coming Soon ──────────────────────────
      GoRoute(
        path: AppRoutes.comingSoon,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ComingSoonScreen(title: extra?['title'] as String? ?? 'Quiz');
        },
      ),

      // ── Main Shell (Bottom Nav) ───────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const SubjectSelectionScreen(),
          ),
          GoRoute(
            path: AppRoutes.discover,
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: AppRoutes.library,
            builder: (context, state) => const LibraryScreen(),
          ),
          GoRoute(
            path: AppRoutes.rank,
            builder: (context, state) => const RankScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Quiz Engine ──────────────────────────
      GoRoute(
        path: AppRoutes.quizLoading,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return QuizLoadingScreen(
            lessonId: extra?['lesson_id'] as int? ?? 0,
            lessonTitle: extra?['title'] as String? ?? '',
            subject: extra?['subject'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quizSession,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return QuizSessionScreen(
            lessonId: extra?['lesson_id'] as int? ?? 0,
            subject: extra?['subject'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quizCompleted,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return QuizCompletedScreen(
            timeTaken: extra?['time_taken'] as String? ?? '0:00',
            accuracy: extra?['accuracy'] as int? ?? 0,
            points: extra?['points'] as int? ?? 0,
          );
        },
      ),
    ],
  );
});

Future<bool> _isOnboardingDone() async {
  return HiveStorage.isOnboardingDone();
}

Future<bool> _hasExamTypeSelected() async {
  return HiveStorage.isExamTypeSelected();
}

// Placeholder screens for tab items not yet implemented
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Library — Coming Soon')),
  );
}

class RankScreen extends StatelessWidget {
  const RankScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Rankings — Coming Soon')),
  );
}
