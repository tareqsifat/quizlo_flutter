import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/storage/hive_storage.dart';

/// ─────────────────────────────────────────────
/// Auth Landing Screen
/// "Unlock Your Learning Potential" + Sign In / Sign Up buttons
/// Includes DEV "Skip Auth" button (remove before prod release)
/// ─────────────────────────────────────────────
class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  Future<void> _skipAuth(BuildContext context) async {
    // DEV BYPASS — hardcoded auth true
    // To remove: delete this button and this function entirely
    // No other code needs changing (SecureStorage.isAuthenticated handles it)
    await SecureStorage.setSkipAuth(true);
    await HiveStorage.setOnboardingDone(true);
    await HiveStorage.setExamTypeSelected(true);
    if (context.mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
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

              const Spacer(),

              // ── Illustration ────────────────
              Center(
                child: Container(
                  width: 260,
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    size: 100,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

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
              const SizedBox(height: 12),
              Text(
                'Start your exam prep journey today. Learn smarter, score higher.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),

              const Spacer(),

              // ── Auth Buttons ────────────────
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Sign In',
                      onTap: () => context.go(AppRoutes.signIn),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton.outlined(
                      label: 'Sign Up',
                      onTap: () => context.go(AppRoutes.signIn,
                          extra: {'tab': 'signup'}),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── DEV ONLY: Skip Auth ─────────
              // TODO: Remove this button before production release
              // Hardcoded auth bypass for development/demo
              Center(
                child: TextButton(
                  onPressed: () => _skipAuth(context),
                  child: Text(
                    'Skip — View App (Dev Only)',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
