import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/router/app_router.dart';

/// ─────────────────────────────────────────────
/// OTP Verification Screen
/// 4-box OTP input + 60s countdown + resend
/// ─────────────────────────────────────────────
class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String purpose; // 'forgot_password' or 'register'

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.purpose,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(AppSizes.otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(AppSizes.otpLength, (_) => FocusNode());

  int _secondsRemaining = 60;
  Timer? _timer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining == 0) {
        t.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _verify() {
    if (_otp.length < AppSizes.otpLength) return;
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _loading = false);
        context.push(
          AppRoutes.createNewPassword,
          extra: {'email': widget.email, 'token': _otp},
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

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
              IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: 32),

              Text('OTP Verification', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(
                'Enter the verification code we just sent on your email address or phone number.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),

              // ── OTP Boxes ─────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  AppSizes.otpLength,
                  (i) => _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    onChanged: (val) {
                      if (val.isNotEmpty && i < AppSizes.otpLength - 1) {
                        _focusNodes[i + 1].requestFocus();
                      }
                      if (val.isEmpty && i > 0) {
                        _focusNodes[i - 1].requestFocus();
                      }
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Verify button ─────────────
              AppButton(
                label: 'Verify',
                isLoading: _loading,
                onTap: _otp.length == AppSizes.otpLength ? _verify : null,
              ),
              const SizedBox(height: 20),

              // ── Countdown ─────────────────
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'You can resend the code in ',
                    style: AppTextStyles.bodySmall,
                    children: [
                      TextSpan(
                        text: '$_secondsRemaining seconds',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // ── Resend link ───────────────
              Center(
                child: GestureDetector(
                  onTap: _secondsRemaining == 0 ? _startTimer : null,
                  child: RichText(
                    text: TextSpan(
                      text: "Didn't Received Code? ",
                      style: AppTextStyles.bodySmall,
                      children: [
                        TextSpan(
                          text: 'Resend',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _secondsRemaining == 0
                                ? AppColors.primary
                                : AppColors.textHint,
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
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.otpBoxSize,
      height: AppSizes.otpBoxSize,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: focusNode.hasFocus ? AppColors.primary : AppColors.border,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTextStyles.h2.copyWith(color: AppColors.primary),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

