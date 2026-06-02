import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_router.dart';

/// ─────────────────────────────────────────────
/// Home Screen
/// Welcome · Search · Categories · Discover
/// Top 3 Rankings · Popular Quiz
/// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'BCS';

  // Mock categories from enrolled exam types
  static const _categories = ['BCS', 'SSC', 'HSC', 'Bank', 'Job'];

  // Mock data — replace with API response
  static const _discoverItems = [
    _QuizItem(id: 1, title: 'Objective Question with Answer for Math MCQ', imageColor: Color(0xFFFF6B9D), questionCount: 20, timeAgo: '2 Month ago', plays: '5.2k'),
    _QuizItem(id: 2, title: 'Bangladesh Affairs Complete Guide', imageColor: Color(0xFF6BCB77), questionCount: 15, timeAgo: '1 Month ago', plays: '3.8k'),
    _QuizItem(id: 3, title: 'English Grammar Mastery', imageColor: Color(0xFF4D96FF), questionCount: 25, timeAgo: '3 Weeks ago', plays: '7.1k'),
    _QuizItem(id: 4, title: 'General Science for BCS', imageColor: Color(0xFFFFD93D), questionCount: 30, timeAgo: '5 Days ago', plays: '2.4k'),
  ];

  static const _rankings = [
    _RankItem(rank: 1, name: 'Ashraful Alom (Hero Alom)', points: 150, avatarColor: Color(0xFF5B4FDC)),
    _RankItem(rank: 2, name: 'Sefat Ullah SefuDa', points: 143, avatarColor: Color(0xFF27AE60)),
    _RankItem(rank: 3, name: 'Zayed Khan', points: 138, avatarColor: Color(0xFFE67E22)),
  ];

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.scaffoldBg,
            elevation: 0,
            toolbarHeight: 70,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome Hero Alom !', style: AppTextStyles.h3),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _HeartBadge(hearts: 4, maxHearts: 5),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Search ──────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
                  child: _SearchBar(controller: _searchCtrl),
                ),
                const SizedBox(height: 20),

                // ── Categories ──────────────
                Padding(
                  padding: const EdgeInsets.only(left: AppSizes.screenPadding),
                  child: Text('Categories', style: AppTextStyles.h4),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      final isSelected = cat == _selectedCategory;
                      return _CategoryChip(
                        label: cat,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedCategory = cat),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── Discover ────────────────
                _SectionHeader(
                  title: 'Discover',
                  onSeeAll: () => context.go(AppRoutes.discover),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: AppSizes.quizCardHeight + 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
                    itemCount: _discoverItems.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) =>
                        _QuizCard(item: _discoverItems[i]),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Top 3 Rankings ──────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
                  child: Text('Top 3 Rankings', style: AppTextStyles.h4),
                ),
                const SizedBox(height: 12),
                ...List.generate(_rankings.length, (i) =>
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, 0, AppSizes.screenPadding, 8),
                    child: _RankCard(item: _rankings[i]),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Popular Quiz ────────────
                _SectionHeader(
                  title: 'Popular Quiz',
                  onSeeAll: () => context.go(AppRoutes.discover),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: AppSizes.quizCardHeight + 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
                    itemCount: _discoverItems.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) =>
                        _QuizCard(item: _discoverItems[(i + 2) % _discoverItems.length]),
                  ),
                ),
                const SizedBox(height: 100), // bottom nav space
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting Widgets ────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search....',
          hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.chipBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.h4),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(children: [
                Text('See All', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
              ]),
            ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final _QuizItem item;
  const _QuizCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showQuizStartSheet(context, item),
      child: Container(
        width: AppSizes.quizCardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                Container(
                  height: AppSizes.quizCardHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: item.imageColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.cardRadius)),
                  ),
                  child: const Center(child: Icon(Icons.menu_book_rounded, size: 40, color: Colors.white60)),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_border_rounded, size: 16, color: AppColors.error),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${item.questionCount} Question', style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final _RankItem item;
  const _RankCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: item.avatarColor.withOpacity(0.2), shape: BoxShape.circle),
            child: Center(child: Text(item.name[0], style: AppTextStyles.h4.copyWith(color: item.avatarColor))),
          ),
          const SizedBox(width: 12),
          // Name + Points
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.star_rounded, size: 14, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text('${item.points} Point', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ]),
              ],
            ),
          ),
          // Rank badge
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: item.rank == 1 ? AppColors.rankGold : item.rank == 2 ? AppColors.rankSilver : AppColors.rankBronze,
              shape: BoxShape.circle,
            ),
            child: Center(child: Text('${item.rank}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
        ],
      ),
    );
  }
}

class _HeartBadge extends StatelessWidget {
  final int hearts;
  final int maxHearts;
  const _HeartBadge({required this.hearts, required this.maxHearts});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(maxHearts, (i) => Icon(
        i < hearts ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 18,
        color: i < hearts ? AppColors.heartRed : AppColors.textHint,
      )),
    );
  }
}

void _showQuizStartSheet(BuildContext context, _QuizItem item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuizStartSheet(item: item),
  );
}

class _QuizStartSheet extends StatelessWidget {
  final _QuizItem item;
  const _QuizStartSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXxl)),
      ),
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: AppColors.scaffoldBg, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Container(
              width: double.infinity,
              height: 140,
              color: item.imageColor,
              child: const Center(child: Icon(Icons.menu_book_rounded, size: 60, color: Colors.white60)),
            ),
          ),
          const SizedBox(height: 16),

          Text(item.title, style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text('${item.questionCount} Question', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.star_rounded, size: 18, color: AppColors.accent),
            const SizedBox(width: 6),
            Text('Total Score: ', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            Text('${item.questionCount * 2} Points', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),

          Text('Instructions:', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          const _Instruction(number: '1', text: 'Read each question carefully.'),
          const _Instruction(number: '2', text: 'Choose the correct answer from the options provided.'),
          const _Instruction(number: '3', text: 'Try to get the highest score and beat the leader board!'),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRoutes.quizLoading, extra: {'lesson_id': item.id, 'title': item.title});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
                elevation: 0,
              ),
              child: Text('Start Play Quiz', style: AppTextStyles.buttonLarge),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Instruction extends StatelessWidget {
  final String number;
  final String text;
  const _Instruction({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. ', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

// ── Data Models (local) ───────────────────────
class _QuizItem {
  final int id;
  final String title;
  final Color imageColor;
  final int questionCount;
  final String timeAgo;
  final String plays;

  const _QuizItem({
    required this.id,
    required this.title,
    required this.imageColor,
    required this.questionCount,
    required this.timeAgo,
    required this.plays,
  });
}

class _RankItem {
  final int rank;
  final String name;
  final int points;
  final Color avatarColor;

  const _RankItem({required this.rank, required this.name, required this.points, required this.avatarColor});
}
