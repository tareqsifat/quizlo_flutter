import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/storage/secure_storage.dart';

/// ─────────────────────────────────────────────
/// Profile Screen (stub — to be completed)
/// ─────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                          _GamBadge(label: '🔥 12', sublabel: 'Streak'),
                          const SizedBox(width: 16),
                          _GamBadge(label: '❤️ 4', sublabel: 'Hearts'),
                          const SizedBox(width: 16),
                          _GamBadge(label: '⭐ 1250', sublabel: 'XP'),
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
                      Expanded(child: _StatCard2(label: 'Total XP', value: '1250')),
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
                  ...const [
                    _SettingsItem(icon: Icons.person_outline_rounded, label: 'Edit Profile'),
                    _SettingsItem(icon: Icons.notifications_outlined, label: 'Notifications'),
                    _SettingsItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy'),
                    _SettingsItem(icon: Icons.help_outline_rounded, label: 'Help & Support'),
                    _SettingsItem(icon: Icons.logout_rounded, label: 'Logout', isDestructive: true),
                  ],
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
  const _SettingsItem({required this.icon, required this.label, this.isDestructive = false});

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
        onTap: () async {
          if (label == 'Logout') {
            await SecureStorage.clearAll();
            await HiveStorage.clearAll();
            if (context.mounted) {
              context.go(AppRoutes.authLanding);
            }
          }
        },
      ),
    );
  }
}
