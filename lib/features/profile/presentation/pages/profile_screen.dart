import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/services/app_toast.dart';
import '../../auth/data/auth_repository.dart';

/// ─────────────────────────────────────────────
/// Profile Screen
/// ─────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = HiveStorage.getUserProfile();
    final streak = HiveStorage.getStreakCount();
    final xp = profile != null ? (profile['xp'] ?? 1250) : 1250;
    final hearts = profile != null ? (profile['hearts'] ?? 4) : 4;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.primary,
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: Center(
                          child: Text(
                            HiveStorage.isDemoMode() ? 'DU' : 'HA',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        HiveStorage.isDemoMode() ? 'Demo User' : 'Hero Alom',
                        style: AppTextStyles.h3.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        HiveStorage.isDemoMode()
                            ? 'BCS Candidate (Demo Mode)'
                            : 'BCS Candidate • Rank #1',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      // Gamification badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GamBadge(label: '🔥 $streak', sublabel: 'Streak'),
                          const SizedBox(width: 16),
                          _GamBadge(label: '❤️ $hearts', sublabel: 'Hearts'),
                          const SizedBox(width: 16),
                          _GamBadge(label: '⭐ $xp', sublabel: 'XP'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Stats ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Your Progress', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _StatCard2(label: 'Quizzes Done', value: '142')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard2(label: 'Accuracy', value: '78%')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard2(label: 'Total XP', value: '$xp')),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text('My Exam Types', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  _ExamTypePill(label: 'BCS', isPrimary: true),
                  const SizedBox(height: 8),
                  _ExamTypePill(label: 'Bank Jobs'),
                  const SizedBox(height: 24),

                  // Settings
                  Text('Settings', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profile',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Change Password',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const ChangePasswordDialog(),
                      );
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    isDestructive: true,
                    onTap: () async {
                      await SecureStorage.clearAll();
                      await HiveStorage.clearAll();
                      if (context.mounted) {
                        context.go(AppRoutes.authLanding);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GamBadge extends StatelessWidget {
  final String label;
  final String sublabel;
  const _GamBadge({required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        Text(sublabel, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.white70)),
      ],
    );
  }
}

class _StatCard2 extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard2({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ExamTypePill extends StatelessWidget {
  final String label;
  final bool isPrimary;
  const _ExamTypePill({required this.label, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: isPrimary ? AppColors.primary : AppColors.border, width: 1.5),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 3)],
      ),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.labelLarge.copyWith(color: isPrimary ? AppColors.primary : AppColors.textPrimary)),
          const Spacer(),
          if (isPrimary) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
            child: Text('Primary', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 3)],
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(label, style: AppTextStyles.labelMedium.copyWith(color: color)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }
}

/// ── Change Password Dialog ──────────────────────────────────────────────────

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final success = await ref.read(authStateProvider.notifier).changePassword(
          currentPassword: _currentPasswordCtrl.text,
          newPassword: _newPasswordCtrl.text,
        );

    if (mounted) {
      setState(() => _loading = false);
      if (success) {
        AppToast.showSuccess('Password changed successfully!');
        Navigator.pop(context);
      }
    }
  }

  InputDecoration _buildInputDecoration(String hint, bool obscure, VoidCallback toggleObscure) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.scaffoldBg,
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textHint,
          size: 20,
        ),
        onPressed: toggleObscure,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Change Password', style: AppTextStyles.h2),
              const SizedBox(height: 20),
              
              // Current Password
              Text('Current Password', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentPasswordCtrl,
                obscureText: _obscureCurrent,
                style: AppTextStyles.bodyMedium,
                validator: (v) => v == null || v.isEmpty ? 'Enter current password' : null,
                decoration: _buildInputDecoration('••••••••', _obscureCurrent, () {
                  setState(() => _obscureCurrent = !_obscureCurrent);
                }),
              ),
              const SizedBox(height: 16),

              // New Password
              Text('New Password', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newPasswordCtrl,
                obscureText: _obscureNew,
                style: AppTextStyles.bodyMedium,
                validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                decoration: _buildInputDecoration('••••••••', _obscureNew, () {
                  setState(() => _obscureNew = !_obscureNew);
                }),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              Text('Confirm New Password', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordCtrl,
                obscureText: _obscureConfirm,
                style: AppTextStyles.bodyMedium,
                validator: (v) => v != _newPasswordCtrl.text ? 'Passwords do not match' : null,
                decoration: _buildInputDecoration('••••••••', _obscureConfirm, () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                }),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 44,
                    width: 100,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
