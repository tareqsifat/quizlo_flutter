import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../storage/hive_storage.dart';
import '../router/app_router.dart';

class GlobalTopBar extends StatelessWidget {
  const GlobalTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = HiveStorage.getUserProfile();
    final avatar = profile?['avatar'] as String?;
    final hasAvatar = avatar != null && avatar.isNotEmpty;
    final streakCount = HiveStorage.getStreakCount();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
        vertical: 12,
      ),
      child: Row(
        children: [
          // ── Stack Icon Button (left) ────────────────────────
          GestureDetector(
            onTap: () => context.push(AppRoutes.examTypeSelection),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFE1F5FE), // light blue
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.layers_rounded,
                color: Color(0xFF0288D1), // blue stack icon
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Streak indicator ─────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 4),
              Text(
                '$streakCount',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.streakOrange,
                ),
              ),
            ],
          ),

          const Spacer(),

          // ── User Avatar (right) ──────────────────────────────
          GestureDetector(
            onTap: () => context.go(AppRoutes.profile),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0288D1), width: 1.5),
                color: const Color(0xFFE1F5FE), // fallback light blue background
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: hasAvatar
                    ? Image.network(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                      )
                    : _buildPlaceholderIcon(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Icon(
      Icons.person_rounded,
      color: Color(0xFF0288D1),
      size: 24,
    );
  }
}
