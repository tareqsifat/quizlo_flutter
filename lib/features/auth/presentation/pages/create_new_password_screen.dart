import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/router/app_router.dart';

/// Create New Password Screen
class CreateNewPasswordScreen extends StatefulWidget {
  final String email;
  final String token;
  const CreateNewPasswordScreen({super.key, required this.email, required this.token});

  @override
  State<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _newVisible = false, _confirmVisible = false, _rememberMe = true, _loading = false;

  @override
  void dispose() { _newPassCtrl.dispose(); _confirmPassCtrl.dispose(); super.dispose(); }

  void _reset() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) { setState(() => _loading = false); context.push(AppRoutes.passwordChanged); }
    });
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
                IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
                const SizedBox(height: 32),
                Text('Create New Password', style: AppTextStyles.h1),
                const SizedBox(height: 8),
                Text('Your new password must be unique from those previously used.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.6)),
                const SizedBox(height: 32),
                Text('New Password', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                _PassField(controller: _newPassCtrl, visible: _newVisible, onToggle: () => setState(() => _newVisible = !_newVisible),
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null),
                const SizedBox(height: 20),
                Text('Confirm Password', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                _PassField(controller: _confirmPassCtrl, visible: _confirmVisible, onToggle: () => setState(() => _confirmVisible = !_confirmVisible),
                  validator: (v) => v != _newPassCtrl.text ? 'Passwords do not match' : null),
                const SizedBox(height: 12),
                Row(children: [
                  Checkbox(value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v ?? true)),
                  Text('Remember me', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
                ]),
                const SizedBox(height: 24),
                AppButton(label: 'Reset Password', isLoading: _loading, onTap: _reset),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PassField extends StatelessWidget {
  final TextEditingController controller;
  final bool visible;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PassField({required this.controller, required this.visible, required this.onToggle, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator: validator,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: '••••••••••••••••••',
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        suffixIcon: IconButton(icon: const Icon(Icons.visibility_off_outlined, size: 20, color: AppColors.textHint), onPressed: onToggle),
        filled: true, fillColor: AppColors.scaffoldBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.inputRadius), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.inputRadius), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.inputRadius), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.inputRadius), borderSide: const BorderSide(color: AppColors.error)),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// Password Changed Screen — success state
/// ─────────────────────────────────────────────
class PasswordChangedScreen extends StatelessWidget {
  const PasswordChangedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.go(AppRoutes.authLanding)),
              const Spacer(),
              Center(
                child: Container(
                  width: 100, height: 100,
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                ),
              ),
              const SizedBox(height: 32),
              Center(child: Text('Password Changed!', style: AppTextStyles.h1, textAlign: TextAlign.center)),
              const SizedBox(height: 12),
              Center(child: Text('Your password has been changed successfully.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center)),
              const Spacer(),
              AppButton(label: 'Back To Login', onTap: () => context.go(AppRoutes.signIn)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
