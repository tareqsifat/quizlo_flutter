import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/app_toast.dart';
import '../../data/auth_repository.dart';

/// ─────────────────────────────────────────────
/// Create New Password Screen
/// ─────────────────────────────────────────────
class CreateNewPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String token;

  const CreateNewPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  ConsumerState<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends ConsumerState<CreateNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final success = await ref.read(authStateProvider.notifier).updatePassword(
          email: widget.email,
          otp: widget.token,
          newPassword: _passwordCtrl.text,
        );

    if (mounted) {
      setState(() => _loading = false);
      if (success) {
        AppToast.showSuccess('Password reset successfully! Please sign in with your new password.');
        context.go(AppRoutes.signIn);
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

                Text('Create New Password', style: AppTextStyles.h1),
                const SizedBox(height: 8),
                Text(
                  'Your new password must be unique from those previously used.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),

                // Password
                Text('New Password', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  style: AppTextStyles.bodyMedium,
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Min 6 characters' : null,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.scaffoldBg,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
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
                const SizedBox(height: 24),

                // Confirm Password
                Text('Confirm Password', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  style: AppTextStyles.bodyMedium,
                  validator: (v) =>
                      v != _passwordCtrl.text ? 'Passwords do not match' : null,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.scaffoldBg,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
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
                  label: 'Reset Password',
                  isLoading: _loading,
                  onTap: _resetPassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
