import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';

/// ─────────────────────────────────────────────
/// Discover Screen — Search + Vertical Quiz List
/// ─────────────────────────────────────────────
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const _allItems = [
    _ListQuizItem(id: 1, title: 'Objective Question with Answer for Math MCQ', imageColor: Color(0xFFFF6B9D), questionCount: 20, timeAgo: '2 Month ago', plays: '5.2 plays'),
    _ListQuizItem(id: 2, title: 'Objective Question with Answer for Math MCQ', imageColor: Color(0xFF6BCB77), questionCount: 20, timeAgo: '2 Month ago', plays: '5.2 plays'),
    _ListQuizItem(id: 3, title: 'Objective Question with Answer for Math MCQ', imageColor: Color(0xFF4D96FF), questionCount: 20, timeAgo: '2 Month ago', plays: '5.2 plays'),
    _ListQuizItem(id: 4, title: 'Objective Question with Answer for Math MCQ', imageColor: Color(0xFFFFD93D), questionCount: 20, timeAgo: '2 Month ago', plays: '5.2 plays'),
    _ListQuizItem(id: 5, title: 'Objective Question with Answer for Math MCQ', imageColor: Color(0xFFFF9A3C), questionCount: 20, timeAgo: '2 Month ago', plays: '5.2 plays'),
    _ListQuizItem(id: 6, title: 'Objective Question with Answer for Math MCQ', imageColor: Color(0xFF9B59B6), questionCount: 20, timeAgo: '2 Month ago', plays: '5.2 plays'),
  ];

  List<_ListQuizItem> get _filtered => _query.isEmpty
      ? _allItems
      : _allItems.where((i) => i.title.toLowerCase().contains(_query.toLowerCase())).toList();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Text('Discover', style: AppTextStyles.h3),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search....',
                  hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: true,
                  fillColor: AppColors.scaffoldBg,
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _DiscoverListCard(
          item: _filtered[i],
          onTap: () => _showQuizSheet(context, _filtered[i]),
        ),
      ),
    );
  }

  void _showQuizSheet(BuildContext context, _ListQuizItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuizStartBottomSheet(item: item),
    );
  }
}

class _DiscoverListCard extends StatelessWidget {
  final _ListQuizItem item;
  final VoidCallback onTap;

  const _DiscoverListCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppSizes.quizListCardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppSizes.cardRadius)),
              child: Container(
                width: 80,
                color: item.imageColor,
                child: const Center(child: Icon(Icons.menu_book_rounded, size: 32, color: Colors.white60)),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.title, style: AppTextStyles.labelLarge.copyWith(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text(item.timeAgo, style: AppTextStyles.caption),
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(item.plays, style: AppTextStyles.caption),
                    ]),
                    const SizedBox(height: 2),
                    Text('${item.questionCount} Question', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizStartBottomSheet extends StatelessWidget {
  final _ListQuizItem item;
  const _QuizStartBottomSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXxl)),
      ),
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(item.title, style: AppTextStyles.h4, maxLines: 2, overflow: TextOverflow.ellipsis)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(color: AppColors.scaffoldBg, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              HiveStorage.isDemoMode()
                  ? '10 Question • ${item.timeAgo}'
                  : '${item.questionCount} Question • ${item.timeAgo}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              RichText(text: TextSpan(children: [
                TextSpan(text: 'Total Score: ', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
                TextSpan(
                  text: HiveStorage.isDemoMode() ? '20 Points' : '${item.questionCount * 2} Points',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ])),
            ]),
            const SizedBox(height: 16),
            Text('Instructions:', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            _buildInstruction('1', 'Read each question carefully.'),
            _buildInstruction('2', 'Choose the correct answer from the options provided.'),
            _buildInstruction('3', 'Try to get the highest score and beat the leader board!'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$n. ', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

class _ListQuizItem {
  final int id;
  final String title;
  final Color imageColor;
  final int questionCount;
  final String timeAgo;
  final String plays;

  const _ListQuizItem({required this.id, required this.title, required this.imageColor, required this.questionCount, required this.timeAgo, required this.plays});
}
