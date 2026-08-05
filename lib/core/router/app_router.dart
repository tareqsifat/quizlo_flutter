import 'package:flutter/foundation.dart';
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
import '../../features/leaderboard/data/leaderboard_repository.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/leaderboard/presentation/pages/rank_screen.dart';
import '../storage/secure_storage.dart';
import '../storage/hive_storage.dart';
import '../widgets/global_top_bar.dart';
import '../services/app_toast.dart';

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

/// Lets screens (e.g. [SubjectSelectionScreen]) subscribe via [RouteAware]
/// to find out when they've become visible again after a pushed route
/// (like the quiz flow) is popped/replaced back to them, so they can
/// refresh state that was updated while they were hidden.
final RouteObserver<PageRoute<dynamic>> routeObserver = RouteObserver<PageRoute<dynamic>>();

/// ─────────────────────────────────────────────
/// App Router Provider
/// ─────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    observers: [routeObserver],

    // Route guard — redirect unauthenticated users
    redirect: (context, state) async {
      // ── CRITICAL: wrap auth check with timeout ──────────────────
      // flutter_secure_storage on Android (encryptedSharedPreferences)
      // can hang indefinitely if the Keystore is initializing or locked.
      // A 5-second timeout prevents a permanent black screen.
      bool isAuth = false;
      try {
        isAuth = await SecureStorage.isAuthenticated()
            .timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint('[ROUTER] ⚠️ SecureStorage timed out — defaulting to unauthenticated');
          AppToast.show(
            '⚠️ Storage check timed out. Try restarting the app.',
            isError: true,
            duration: const Duration(seconds: 8),
          );
          return false;
        });
      } catch (e) {
        debugPrint('[ROUTER] ❌ SecureStorage error: $e — defaulting to unauthenticated');
        AppToast.showError('Auth check failed: $e');
        isAuth = false;
      }

      final isOnboarded = await _isOnboardingDone();
      final hasExamType = await _hasExamTypeSelected();

      final currentPath = state.matchedLocation;
      debugPrint('[ROUTER] redirect — path=$currentPath isAuth=$isAuth onboarded=$isOnboarded hasExamType=$hasExamType');

      final publicPaths = [
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.authLanding,
        AppRoutes.signIn,
        AppRoutes.forgotPassword,
        AppRoutes.otpVerification,
        AppRoutes.createNewPassword,
      ];

      if (!isAuth && !publicPaths.contains(currentPath)) {
        debugPrint('[ROUTER] → redirecting to authLanding (not authenticated)');
        return AppRoutes.authLanding;
      }
      if (isAuth && !hasExamType && currentPath != AppRoutes.examTypeSelection) {
        debugPrint('[ROUTER] → redirecting to examTypeSelection (no exam type set)');
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
            beforeLeaderboard: extra?['before_leaderboard'] as LeaderboardData?,
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
    body: SafeArea(
      child: Column(
        children: [
          GlobalTopBar(),
          Expanded(
            child: Center(child: Text('Library — Coming Soon')),
          ),
        ],
      ),
    ),
  );
}

