import 'package:flutter/foundation.dart';
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
/// Sign In Screen — with SIGN IN / SIGN UP tabs
/// Matches Figma: tab underline, fields, social
/// ─────────────────────────────────────────────
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  // Sign In fields
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe = false;
  bool _signInPasswordVisible = false;
  bool _signInLoading = false;

  // Sign Up fields
  final _nameCtrl = TextEditingController();
  final _signUpEmailCtrl = TextEditingController();
  final _signUpPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _signUpPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _signUpLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _signUpEmailCtrl.dispose();
    _signUpPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => context.go(AppRoutes.authLanding),
                  ),
                ],
              ),
            ),

            // ── Tab Bar ─────────────────────
            TabBar(
              controller: _tabController,
              labelStyle: AppTextStyles.labelLarge,
              unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'SIGN IN'),
                Tab(text: 'SIGN UP'),
              ],
            ),

            // ── Tab content ─────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSignIn(),
                  _buildSignUp(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignIn() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Form(
        key: _signInFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Email
            Text('Email Here', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            _AppTextField(
              controller: _emailCtrl,
              hint: 'yourmail@gmail.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Email is required' : null,
            ),
            const SizedBox(height: 20),

            // Password
            Text('Password', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            _AppTextField(
              controller: _passwordCtrl,
              hint: '••••••••••••••••••',
              obscureText: !_signInPasswordVisible,
              suffix: IconButton(
                icon: Icon(
                  _signInPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textHint,
                ),
                onPressed: () => setState(
                    () => _signInPasswordVisible = !_signInPasswordVisible),
              ),
              validator: (v) =>
                  v == null || v.length < 6 ? 'Password too short' : null,
            ),
            const SizedBox(height: 12),

            // Remember me + Forgot
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                Text('Remember me', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  child: Text('Forget Password?',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sign In button
            AppButton(
              label: 'Sign In',
              isLoading: _signInLoading,
              onTap: _doSignIn,
            ),
            const SizedBox(height: 24),

            // Or divider
            _OrDivider(),
            const SizedBox(height: 20),

            // Social
            _FacebookButton(),
            const SizedBox(height: 12),
            _GoogleButton(),
            const SizedBox(height: 24),

            // Sign up link
            Center(
              child: RichText(
                text: TextSpan(
                  text: "Don't Have An Account? ",
                  style: AppTextStyles.bodySmall,
                  children: [
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => _tabController.animateTo(1),
                        child: Text(
                          'Sign Up Here',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUp() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Form(
        key: _signUpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Full Name
            Text('Full Name', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            _AppTextField(
              controller: _nameCtrl,
              hint: 'Enter Your Name Here',
              validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 20),

            // Email
            Text('Email Here', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            _AppTextField(
              controller: _signUpEmailCtrl,
              hint: 'yourmail@gmail.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Email is required' : null,
            ),
            const SizedBox(height: 20),

            // Password
            Text('Password', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            _AppTextField(
              controller: _signUpPasswordCtrl,
              hint: '••••••••••••••••••',
              obscureText: !_signUpPasswordVisible,
              suffix: IconButton(
                icon: const Icon(Icons.visibility_off_outlined,
                    size: 20, color: AppColors.textHint),
                onPressed: () => setState(
                    () => _signUpPasswordVisible = !_signUpPasswordVisible),
              ),
              validator: (v) =>
                  v == null || v.length < 6 ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 20),

            // Confirm Password
            Text('Confirm Password', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            _AppTextField(
              controller: _confirmPasswordCtrl,
              hint: '••••••••••••••••••',
              obscureText: !_confirmPasswordVisible,
              suffix: IconButton(
                icon: const Icon(Icons.visibility_off_outlined,
                    size: 20, color: AppColors.textHint),
                onPressed: () => setState(
                    () => _confirmPasswordVisible = !_confirmPasswordVisible),
              ),
              validator: (v) =>
                  v != _signUpPasswordCtrl.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 24),

            // Sign Up button
            AppButton(
              label: 'Sign Up',
              isLoading: _signUpLoading,
              onTap: _doSignUp,
            ),
            const SizedBox(height: 24),
            _OrDivider(),
            const SizedBox(height: 20),
            _FacebookButton(),
            const SizedBox(height: 12),
            _GoogleButton(),
            const SizedBox(height: 24),

            Center(
              child: RichText(
                text: TextSpan(
                  text: 'Already Have An Account? ',
                  style: AppTextStyles.bodySmall,
                  children: [
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => _tabController.animateTo(0),
                        child: Text(
                          'Sign In Here',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _doSignIn() async {
    if (!_signInFormKey.currentState!.validate()) return;
    setState(() => _signInLoading = true);
    debugPrint('[UI][SignIn] Submitting sign-in for ${_emailCtrl.text.trim()}');

    try {
      final success = await ref.read(authStateProvider.notifier).login(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
          );

      if (mounted) {
        setState(() => _signInLoading = false);
        if (success) {
          debugPrint('[UI][SignIn] ✅ Sign-in succeeded — navigating to examTypeSelection');
          _showDebugToast(context, '✅ Sign In successful!', isSuccess: true);
          context.go(AppRoutes.examTypeSelection);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _signInLoading = false);
        if (e is ApiException && e.needsVerification) {
          debugPrint('[UI][SignIn] ⚠️ Email not verified. Redirecting to OTP verification screen.');
          ref.read(authStateProvider.notifier).sendVerification(_emailCtrl.text.trim());
          context.push(
            AppRoutes.otpVerification,
            extra: {
              'email': _emailCtrl.text.trim(),
              'purpose': 'register',
            },
          );
        } else {
          final msg = e is ApiException ? e.message : e.toString();
          debugPrint('[UI][SignIn] ❌ Sign-in failed — $msg');
          _showDebugToast(context, '❌ Sign In failed: $msg', isSuccess: false);
        }
      }
    }
  }

  void _doSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;
    setState(() => _signUpLoading = true);
    debugPrint('[UI][SignUp] Submitting sign-up for ${_signUpEmailCtrl.text.trim()}');

    try {
      final success = await ref.read(authStateProvider.notifier).register(
            name: _nameCtrl.text.trim(),
            email: _signUpEmailCtrl.text.trim(),
            password: _signUpPasswordCtrl.text,
          );

      if (mounted) {
        setState(() => _signUpLoading = false);
        if (success) {
          debugPrint('[UI][SignUp] ✅ Sign-up succeeded — navigating to OTP verification');
          _showDebugToast(context, '✅ Registration successful! Verify your email.', isSuccess: true);
          context.push(
            AppRoutes.otpVerification,
            extra: {
              'email': _signUpEmailCtrl.text.trim(),
              'purpose': 'register',
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _signUpLoading = false);
        final msg = e is ApiException ? e.message : e.toString();
        debugPrint('[UI][SignUp] ❌ Sign-up failed — $msg');
        _showDebugToast(context, '❌ Sign Up failed: $msg', isSuccess: false);
      }
    }
  }

  /// Shows a debug SnackBar. Green = success, red = failure.
  /// Strip this helper before shipping to production.
  static void _showDebugToast(
    BuildContext context,
    String message, {
    required bool isSuccess,
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
          SnackBar(
            content: Text(
              '[DEBUG] $message',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            backgroundColor: isSuccess ? Colors.green.shade700 : AppColors.error,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
  }
}

// ── Shared local widgets ───────────────────────

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AppTextField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('Or Sign In With',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
        ),
        const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
      ],
    );
  }
}

class _FacebookButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SocialAuthButton(
      label: 'Sign In with Facebook',
      backgroundColor: AppColors.facebookBlue,
      textColor: Colors.white,
      icon: const Icon(Icons.facebook_rounded, color: Colors.white, size: 22),
      onTap: () {}, // TODO: Facebook auth
    );
  }
}

class _GoogleButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends ConsumerState<_GoogleButton> {
  bool _loading = false;

  void _handleGoogleSignIn() async {
    setState(() => _loading = true);
    debugPrint('[UI][Google] Tapped Google Sign-In button');
    _showStepToast('🔄 Step 1: Opening Google account picker…');

    final success =
        await ref.read(authStateProvider.notifier).loginWithGoogle();

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      debugPrint('[UI][Google] ✅ Flow complete — navigating to examTypeSelection');
      _showStepToast('✅ Google Sign-In successful!', isSuccess: true);
      // Small delay so the user can read the success toast
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) context.go(AppRoutes.examTypeSelection);
    } else {
      final error = ref.read(authStateProvider);
      final message = error.maybeWhen(
        error: (e, _) => e.toString(),
        orElse: () => 'Google Sign-In failed. Please try again.',
      );
      debugPrint('[UI][Google] ❌ Flow failed — $message');
      _showStepToast('❌ Google Sign-In failed:\n$message', isSuccess: false);
    }
  }

  void _showStepToast(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
          SnackBar(
            content: Text(
              '[DEBUG] $message',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            backgroundColor: isSuccess
                ? Colors.green.shade700
                : (message.startsWith('🔄') ? Colors.blueGrey.shade700 : AppColors.error),
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return SocialAuthButton(
      label: _loading ? 'Signing in...' : 'Sign In with Google',
      backgroundColor: Colors.white,
      textColor: AppColors.textPrimary,
      icon: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.g_mobiledata_rounded, color: Colors.red, size: 26),
      onTap: _loading ? () {} : _handleGoogleSignIn,
    );
  }
}
