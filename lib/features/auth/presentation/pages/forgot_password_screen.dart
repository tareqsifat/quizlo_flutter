import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/router/app_router.dart';
import '../../data/auth_repository.dart';

/// ─────────────────────────────────────────────
/// Forgot Password Screen
/// ─────────────────────────────────────────────
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final success = await ref.read(authStateProvider.notifier).sendForgetPasswordOtp(
          _emailCtrl.text.trim(),
        );

    if (mounted) {
      setState(() => _loading = false);
      if (success) {
        context.push(
          AppRoutes.otpVerification,
          extra: {
            'email': _emailCtrl.text.trim(),
            'purpose': 'forgot_password',
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: 32),

                Text('Forgot Password?', style: AppTextStyles.h1),
                const SizedBox(height: 8),
                Text(
                  "Don't worry! It occurs. Please enter the email address linked with your account.",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),

                Text('Email Here', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.bodyMedium,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your email' : null,
                  decoration: InputDecoration(
                    hintText: 'yourmail@gmail.com',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.scaffoldBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                AppButton(
                  label: 'Send Code',
                  isLoading: _loading,
                  onTap: _sendCode,
                ),

                const Spacer(),

                Center(
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.signIn),
                    child: RichText(
                      text: TextSpan(
                        text: 'Remember Password? ',
                        style: AppTextStyles.bodySmall,
                        children: [
                          TextSpan(
                            text: 'Sign In Now',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
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
