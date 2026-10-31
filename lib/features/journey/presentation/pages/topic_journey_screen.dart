import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/domain/entities.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../data/journey_repository.dart';
import '../widgets/topic_node.dart';

/// ─────────────────────────────────────────────
/// Topic Journey Screen — Duolingo-style winding
/// checkpoint chain, one node per Topic under a
/// subject. Tapping the current/completed node
/// launches that Topic's quiz; locked nodes are
/// inert until earlier checkpoints are cleared.
/// ─────────────────────────────────────────────
class TopicJourneyScreen extends ConsumerWidget {
  final int subjectId;
  final String subjectTitle;

  /// Show topic names in Bangla (name_bn) — set for the Bangla subject.
  final bool banglaNames;

  const TopicJourneyScreen({
    super.key,
    required this.subjectId,
    required this.subjectTitle,
    this.banglaNames = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsProvider(subjectId));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(subjectTitle, style: AppTextStyles.h4),
      ),
      body: SafeArea(
        child: topicsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            onRetry: () => ref.invalidate(topicsProvider(subjectId)),
          ),
          data: (topics) {
            if (topics.isEmpty) {
              return const _EmptyState();
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(topicsProvider(subjectId)),
              child: _JourneyPath(
                topics: topics,
                banglaNames: banglaNames,
                onTapTopic: (topic) => _openTopicQuiz(context, ref, topic),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openTopicQuiz(
    BuildContext context,
    WidgetRef ref,
    Topic topic,
  ) async {
    if (HiveStorage.isDemoMode()) {
      // No live backend to serve topic-scoped questions in demo mode.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Topic quizzes need a live connection — exit Demo Mode to try this.')),
      );
      return;
    }

    await context.push(AppRoutes.quizLoading, extra: {
      'lesson_id': 0,
      'title': topic.displayName(bangla: banglaNames),
      'subject': null,
      'topic_id': topic.id,
    });
    // Refresh so a just-completed checkpoint flips to completed/unlocks the next.
    if (context.mounted) ref.invalidate(topicsProvider(subjectId));
  }
}

/// Lays the topic nodes out in a winding vertical path — alternating
/// left/right offsets, connected by a simple vertical guide line.
class _JourneyPath extends StatelessWidget {
  final List<Topic> topics;
  final bool banglaNames;
  final ValueChanged<Topic> onTapTopic;

  const _JourneyPath({
    required this.topics,
    required this.banglaNames,
    required this.onTapTopic,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.xxl,
        horizontal: AppSizes.screenPadding,
      ),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        // Zigzag: center → right → center → left → …
        final offsets = [0.0, 0.32, 0.0, -0.32];
        final alignX = offsets[index % offsets.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.xxl),
          child: Align(
            alignment: Alignment(alignX, 0),
            child: TopicNode(
              topic: topic,
              title: topic.displayName(bangla: banglaNames),
              onTap: () => onTapTopic(topic),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Text(
          'No topics yet for this subject — check back soon.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load this journey.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
