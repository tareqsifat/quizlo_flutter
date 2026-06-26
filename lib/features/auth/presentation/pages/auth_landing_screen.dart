import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../data/auth_repository.dart';

/// ─────────────────────────────────────────────
/// Auth Landing Screen
/// "Unlock Your Learning Potential"
/// Redesigned with premium "Login User" and "Demo User" modes.
/// ─────────────────────────────────────────────
class AuthLandingScreen extends ConsumerStatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  ConsumerState<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends ConsumerState<AuthLandingScreen> {
  bool _googleLoading = false;

  Future<void> _enterDemoMode(BuildContext context) async {
    await SecureStorage.setSkipAuth(false);
    await HiveStorage.setDemoMode(true);
    await HiveStorage.setOnboardingDone(true);
    await HiveStorage.setExamTypeSelected(false);
    if (context.mounted) context.go(AppRoutes.examTypeSelection);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    final success = await ref.read(authStateProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);

    if (success) {
      context.go(AppRoutes.examTypeSelection);
    } else {
      final error = ref.read(authStateProvider);
      final message = error.maybeWhen(
        error: (e, _) => e.toString(),
        orElse: () => 'Google Sign-In failed. Please try again.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Back ────────────────────────
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  onPressed: () => context.go(AppRoutes.onboarding),
                ),

                const SizedBox(height: 16),

                // ── Illustration ────────────────
                Center(
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                    ),
                    child: const Icon(
                      Icons.lock_person_rounded,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Headline ───────────────────
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Unlock Your Learning\n',
                        style: AppTextStyles.h1,
                      ),
                      TextSpan(
                        text: 'Potential',
                        style: AppTextStyles.h1.copyWith(color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start your exam prep journey today. Learn smarter, score higher.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Mode Switcher / Info ──
                Text(
                  'Choose Your Pathway',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Login User Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.15),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Login User', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Access live tracking, synced profile statistics, and global leaderboard rankings.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Sign In',
                              onTap: () async {
                                await HiveStorage.setDemoMode(false);
                                if (context.mounted) {
                                  context.go(AppRoutes.signIn);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton.outlined(
                              label: 'Sign Up',
                              onTap: () async {
                                await HiveStorage.setDemoMode(false);
                                if (context.mounted) {
                                  context.go(AppRoutes.signIn, extra: {'tab': 'signup'});
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Google Sign-In shortcut from landing screen
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _googleLoading ? null : _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                            ),
                          ),
                          icon: _googleLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.g_mobiledata_rounded,
                                  color: Colors.red, size: 24),
                          label: Text(
                            _googleLoading ? 'Signing in...' : 'Continue with Google',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Demo User Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.rocket_launch_rounded, color: AppColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Text('Demo User', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Instantly test all features offline with a curated dataset of 200 premium BCS exam questions.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: 'Enter Demo Mode',
                          onTap: () => _enterDemoMode(context),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
