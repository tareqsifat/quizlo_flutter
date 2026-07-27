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

class AnswerOptionTile extends StatefulWidget {
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
  State<AnswerOptionTile> createState() => _AnswerOptionTileState();
}

class _AnswerOptionTileState extends State<AnswerOptionTile>
    with TickerProviderStateMixin {
  late final AnimationController _feedbackController;
  // Own controller for the flash tint so slowing it down to stay visible
  // longer doesn't also slow the bounce/shake, which read better snappy.
  late final AnimationController _flashController;
  Animation<double> _scaleAnimation = const AlwaysStoppedAnimation(1.0);
  Animation<Offset> _shakeAnimation = const AlwaysStoppedAnimation(Offset.zero);
  Animation<double> _flashOpacity = const AlwaysStoppedAnimation(0.0);

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(vsync: this);
    _flashController = AnimationController(vsync: this);
    if (widget.state == AnswerState.correct || widget.state == AnswerState.wrong) {
      _startFeedback(widget.state);
    }
  }

  @override
  void didUpdateWidget(covariant AnswerOptionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final justRevealed = oldWidget.state != widget.state &&
        (widget.state == AnswerState.correct || widget.state == AnswerState.wrong);
    if (justRevealed) {
      _startFeedback(widget.state);
    }
  }

  // Kicks off the tap-feedback animation. Purely visual and self-contained —
  // it never awaits or blocks the caller, so the quiz flow (queueing the
  // next question, showing the celebration screen) proceeds independently.
  void _startFeedback(AnswerState state) {
    final isCorrect = state == AnswerState.correct;
    _feedbackController.duration = Duration(milliseconds: isCorrect ? 350 : 375);

    // ~700ms total: quick fade in, a solid hold at full opacity so the
    // green/red tint is clearly visible (not mid-transition), then fade out.
    const flashDuration = Duration(milliseconds: 700);
    _flashController.duration = flashDuration;
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 120), // ~120ms fade in
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 430), // ~430ms fully visible
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 150, // ~150ms fade out
      ),
    ]).animate(_flashController);

    if (isCorrect) {
      _scaleAnimation = TweenSequence<double>([
        TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.05), weight: 50),
        TweenSequenceItem(tween: Tween<double>(begin: 1.05, end: 1.0), weight: 50),
      ]).animate(CurvedAnimation(parent: _feedbackController, curve: Curves.easeOut));
      _shakeAnimation = const AlwaysStoppedAnimation(Offset.zero);
    } else {
      _scaleAnimation = const AlwaysStoppedAnimation(1.0);
      _shakeAnimation = TweenSequence<Offset>([
        TweenSequenceItem(tween: Tween<Offset>(begin: Offset.zero, end: const Offset(-8, 0)), weight: 20),
        TweenSequenceItem(tween: Tween<Offset>(begin: const Offset(-8, 0), end: const Offset(8, 0)), weight: 20),
        TweenSequenceItem(tween: Tween<Offset>(begin: const Offset(8, 0), end: const Offset(-4, 0)), weight: 20),
        TweenSequenceItem(tween: Tween<Offset>(begin: const Offset(-4, 0), end: const Offset(4, 0)), weight: 20),
        TweenSequenceItem(tween: Tween<Offset>(begin: const Offset(4, 0), end: Offset.zero), weight: 20),
      ]).animate(_feedbackController);
    }

    _feedbackController.forward(from: 0);
    _flashController.forward(from: 0);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(widget.state);
    final flashColor =
        widget.state == AnswerState.wrong ? AppColors.answerFlashWrong : AppColors.answerFlashCorrect;

    // The tap target (Material/InkWell/Text) is passed as `child` so it's
    // built once and reused across animation ticks; only the transform and
    // flash overlay — read fresh from their Animations — rebuild every frame.
    return AnimatedBuilder(
      animation: Listenable.merge([_feedbackController, _flashController]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (widget.state == AnswerState.idle || widget.state == AnswerState.selected)
              ? widget.onTap
              : null,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                widget.text,
                style: AppTextStyles.answerOption.copyWith(color: colors.text),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
      builder: (context, child) {
        return Transform.translate(
          offset: _shakeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: colors.border, width: 1.5),
                boxShadow: widget.state == AnswerState.idle
                    ? [
                        BoxShadow(
                          color: AppColors.shadowColor,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(
                    child: Opacity(
                      opacity: _flashOpacity.value,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: flashColor,
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                      ),
                    ),
                  ),
                  child!,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _AnswerColors _resolveColors(AnswerState state) {
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
