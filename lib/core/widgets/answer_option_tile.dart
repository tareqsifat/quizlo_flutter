import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_sizes.dart';

/// ─────────────────────────────────────────────
/// Answer Option Tile — Quiz Engine
/// States: default / selected / correct / wrong
/// Sizes: large (MCQ), medium (match col), small
/// ─────────────────────────────────────────────
enum AnswerState { idle, selected, correct, wrong }

class AnswerOptionTile extends StatelessWidget {
  final String text;
  final AnswerState state;
  final VoidCallback? onTap;
  final double? width;
  final double height;

  const AnswerOptionTile({
    super.key,
    required this.text,
    this.state = AnswerState.idle,
    this.onTap,
    this.width,
    this.height = AppSizes.answerOptionHeight,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: colors.border, width: 1.5),
        boxShadow: state == AnswerState.idle
            ? [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: state == AnswerState.idle ? onTap : null,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                text,
                style: AppTextStyles.answerOption.copyWith(color: colors.text),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  _AnswerColors _resolveColors() {
    switch (state) {
      case AnswerState.selected:
        return _AnswerColors(
          bg: AppColors.answerSelected,
          border: AppColors.answerSelectedBorder,
          text: AppColors.answerCorrectText,
        );
      case AnswerState.correct:
        return _AnswerColors(
          bg: AppColors.answerCorrect,
          border: AppColors.answerCorrectBorder,
          text: AppColors.answerCorrectText,
        );
      case AnswerState.wrong:
        return _AnswerColors(
          bg: AppColors.answerWrong,
          border: AppColors.answerWrongBorder,
          text: AppColors.answerWrongText,
        );
      case AnswerState.idle:
        return _AnswerColors(
          bg: AppColors.answerDefault,
          border: AppColors.border,
          text: AppColors.textPrimary,
        );
    }
  }
}

class _AnswerColors {
  final Color bg;
  final Color border;
  final Color text;
  const _AnswerColors({required this.bg, required this.border, required this.text});
}

/// ─────────────────────────────────────────────
/// Word Chip — for Fill-in-Blank & HearTouch
/// ─────────────────────────────────────────────
class WordChip extends StatelessWidget {
  final String word;
  final bool isSelected;
  final bool isPlaced;
  final VoidCallback? onTap;

  const WordChip({
    super.key,
    required this.word,
    this.isSelected = false,
    this.isPlaced = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    if (isSelected) {
      bg = AppColors.answerSelected;
      border = AppColors.primary;
      text = AppColors.primary;
    } else if (isPlaced) {
      bg = AppColors.scaffoldBg;
      border = AppColors.border;
      text = AppColors.textHint;
    } else {
      bg = AppColors.cardBg;
      border = AppColors.border;
      text = AppColors.textPrimary;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: InkWell(
          onTap: isPlaced ? null : onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: border, width: 1.5),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Text(
              word,
              style: AppTextStyles.labelMedium.copyWith(color: text),
            ),
          ),
        ),
      ),
    );
  }
}
