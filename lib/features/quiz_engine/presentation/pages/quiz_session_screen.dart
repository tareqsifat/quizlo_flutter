import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/answer_option_tile.dart';
import '../../../../core/widgets/quiz_progress_bar.dart';
import '../../../../core/router/app_router.dart';

/// ─────────────────────────────────────────────
/// Quiz Session Screen — Master quiz controller
/// Renders the correct question type based on
/// the question's type field.
///
/// Question types:
///   - mcq          → McqQuestion
///   - match        → MatchQuestion
///   - fill_blank   → FillBlankQuestion
///   - hear_touch   → HearTouchQuestion
/// ─────────────────────────────────────────────
class QuizSessionScreen extends StatefulWidget {
  final int lessonId;

  const QuizSessionScreen({super.key, required this.lessonId});

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  int _currentIndex = 0;
  int _score = 0;
  final _stopwatch = Stopwatch();

  // Mock questions — in production, from GET /lessons/{id}/questions
  static final _questions = [
    _Question(id: 1, type: 'match', text: 'Touch to match', options: ['English', 'English', 'English', 'English', 'English', 'English', 'English', 'English', 'English', 'English', 'English', 'English'], correctOptionId: 0),
    _Question(id: 2, type: 'hear_touch', text: 'Touch what you hear.', options: ['Nice', 'are', 'is', 'English', 'speak', 'excellent', 'is', 'you'], correctOptionId: 0),
    _Question(id: 3, type: 'mcq', text: 'Lorem Ipsum is simply dummy text of the printing and typesetting industry?', options: ['English', 'English', 'English', 'English'], correctOptionId: 1),
    _Question(id: 4, type: 'mcq', text: 'Give the correct answer. What is the capital of Bangladesh?', options: ['Khulna', 'Chittagong', 'Dhaka', 'Rajshahi'], correctOptionId: 2),
    _Question(id: 5, type: 'fill_blank', text: 'Lorem Ipsum is _____ text of the printing', options: ['Nice', 'are', 'is', 'English', 'speak', 'excellent', 'is', 'you'], correctOptionId: 2),
    _Question(id: 6, type: 'mcq', text: 'Bangladesh gained independence in which year?', options: ['1952', '1971', '1947', '1965'], correctOptionId: 1),
    _Question(id: 7, type: 'match', text: 'Touch to match', options: ['English', 'English', 'English', 'English', 'English', 'English', 'English', 'English'], correctOptionId: 0),
    _Question(id: 8, type: 'mcq', text: 'Who is the father of the nation of Bangladesh?', options: ['Ziaur Rahman', 'Sheikh Hasina', 'Sheikh Mujibur Rahman', 'H.M. Ershad'], correctOptionId: 2),
    _Question(id: 9, type: 'hear_touch', text: 'Touch what you hear.', options: ['you', 'speak', 'excellent', 'English', 'Nice', 'are', 'is', 'you'], correctOptionId: 0),
    _Question(id: 10, type: 'fill_blank', text: 'Lorem Ipsum is _____ dummy text', options: ['Nice', 'are', 'simply', 'English', 'speak', 'excellent', 'is', 'you'], correctOptionId: 2),
  ];

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
  }

  void _onAnswer(bool isCorrect) {
    if (isCorrect) setState(() => _score++);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      // Quiz complete
      _stopwatch.stop();
      final elapsed = _stopwatch.elapsed;
      final timeStr = '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
      final accuracy = ((_score / _questions.length) * 100).round();
      final points = _score * 2;

      context.pushReplacement(
        AppRoutes.quizCompleted,
        extra: {
          'time_taken': timeStr,
          'accuracy': accuracy,
          'points': points,
        },
      );
    }
  }

  void _showLeaveDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LeaveLessonDialog(
        onKeepLearning: () => Navigator.pop(context),
        onLeave: () {
          Navigator.pop(context);
          context.go(AppRoutes.home);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: QuizAppBar(
        current: _currentIndex + 1,
        total: _questions.length,
        onBack: () => context.go(AppRoutes.home),
        onMenu: _showLeaveDialog,
      ),
      body: _buildQuestionType(q),
    );
  }

  Widget _buildQuestionType(_Question q) {
    switch (q.type) {
      case 'match':
        return MatchQuestionWidget(
          question: q,
          onNext: _nextQuestion,
          onAnswer: _onAnswer,
        );
      case 'hear_touch':
        return HearTouchQuestionWidget(
          question: q,
          onNext: _nextQuestion,
          onAnswer: _onAnswer,
        );
      case 'fill_blank':
        return FillBlankQuestionWidget(
          question: q,
          onNext: _nextQuestion,
          onAnswer: _onAnswer,
        );
      default: // mcq
        return McqQuestionWidget(
          question: q,
          onNext: _nextQuestion,
          onAnswer: _onAnswer,
        );
    }
  }
}

// ─────────────────────────────────────────────
// MCQ Question Widget
// ─────────────────────────────────────────────
class McqQuestionWidget extends StatefulWidget {
  final _Question question;
  final VoidCallback onNext;
  final ValueChanged<bool> onAnswer;

  const McqQuestionWidget({
    super.key,
    required this.question,
    required this.onNext,
    required this.onAnswer,
  });

  @override
  State<McqQuestionWidget> createState() => _McqQuestionWidgetState();
}

class _McqQuestionWidgetState extends State<McqQuestionWidget> {
  int? _selectedIndex;
  bool _answered = false;
  bool? _isCorrect;

  void _select(int index) {
    if (_answered) return;
    final isCorrect = index == widget.question.correctOptionId;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      _isCorrect = isCorrect;
    });
    widget.onAnswer(isCorrect);
  }

  AnswerState _stateFor(int index) {
    if (!_answered) return AnswerState.idle;
    if (index == widget.question.correctOptionId) return AnswerState.correct;
    if (index == _selectedIndex) return AnswerState.wrong;
    return AnswerState.idle;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Give the correct answer.', style: AppTextStyles.questionLabel),
                const SizedBox(height: 32),

                // Question text
                Center(
                  child: Text(
                    widget.question.text,
                    style: AppTextStyles.questionText,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),

                // Options
                ...List.generate(widget.question.options.length, (i) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AnswerOptionTile(
                      text: widget.question.options[i],
                      state: _stateFor(i),
                      onTap: () => _select(i),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Bottom feedback + Continue ─────────
        if (_answered)
          _FeedbackBar(
            isCorrect: _isCorrect!,
            onContinue: () {
              setState(() { _selectedIndex = null; _answered = false; _isCorrect = null; });
              widget.onNext();
            },
          )
        else
          _DisabledContinueBar(),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Match Question Widget (Touch to Match)
// ─────────────────────────────────────────────
class MatchQuestionWidget extends StatefulWidget {
  final _Question question;
  final VoidCallback onNext;
  final ValueChanged<bool> onAnswer;

  const MatchQuestionWidget({super.key, required this.question, required this.onNext, required this.onAnswer});

  @override
  State<MatchQuestionWidget> createState() => _MatchQuestionWidgetState();
}

class _MatchQuestionWidgetState extends State<MatchQuestionWidget> {
  int? _firstSelected;
  final Set<int> _matched = {};
  final Set<int> _wrong = {};
  bool _hasError = false;
  bool _allMatched = false;

  void _select(int index) {
    if (_matched.contains(index) || _wrong.contains(index)) return;

    if (_firstSelected == null) {
      setState(() => _firstSelected = index);
    } else {
      final first = _firstSelected!;
      // Simple match: pair left col with right col (even=left, odd=right)
      final isMatch = (first % 2 == 0 && index == first + 1) ||
                      (first % 2 == 1 && index == first - 1);
      if (isMatch) {
        setState(() {
          _matched.addAll([first, index]);
          _firstSelected = null;
          _hasError = false;
          _allMatched = _matched.length == widget.question.options.length;
        });
        widget.onAnswer(true);
      } else {
        setState(() {
          _wrong.addAll([first, index]);
          _firstSelected = null;
          _hasError = true;
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() { _wrong.clear(); _hasError = false; });
        });
      }
    }
  }

  AnswerState _stateFor(int i) {
    if (_matched.contains(i)) return AnswerState.correct;
    if (_wrong.contains(i)) return AnswerState.wrong;
    if (_firstSelected == i) return AnswerState.selected;
    return AnswerState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final cols = widget.question.options;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Touch to match', style: AppTextStyles.questionLabel),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 3.2,
                  ),
                  itemCount: cols.length,
                  itemBuilder: (context, i) => AnswerOptionTile(
                    text: cols[i],
                    state: _stateFor(i),
                    onTap: () => _select(i),
                    height: 44,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_hasError)
          _ErrorBar(onGotIt: () => setState(() => _hasError = false)),
        if (_allMatched)
          _FeedbackBar(
            isCorrect: true,
            onContinue: () {
              setState(() { _matched.clear(); _allMatched = false; });
              widget.onNext();
            },
          )
        else if (!_hasError)
          _DisabledContinueBar(),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Fill in the Blank Question Widget
// ─────────────────────────────────────────────
class FillBlankQuestionWidget extends StatefulWidget {
  final _Question question;
  final VoidCallback onNext;
  final ValueChanged<bool> onAnswer;

  const FillBlankQuestionWidget({super.key, required this.question, required this.onNext, required this.onAnswer});

  @override
  State<FillBlankQuestionWidget> createState() => _FillBlankQuestionWidgetState();
}

class _FillBlankQuestionWidgetState extends State<FillBlankQuestionWidget> {
  String? _selectedWord;
  int? _selectedIndex;
  bool _answered = false;

  void _selectWord(int index, String word) {
    if (_selectedIndex != null) return;
    setState(() { _selectedWord = word; _selectedIndex = index; });
  }

  void _submit() {
    if (_selectedIndex == null) return;
    final isCorrect = _selectedIndex == widget.question.correctOptionId;
    setState(() => _answered = true);
    widget.onAnswer(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final parts = widget.question.text.split('_____');
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fill in the blank!', style: AppTextStyles.questionLabel),
                const SizedBox(height: 32),

                // Sentence with blank
                Wrap(
                  children: [
                    Text(parts[0], style: AppTextStyles.questionText),
                    Container(
                      width: 100,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: _selectedWord != null ? AppColors.primary : AppColors.textHint, width: 2)),
                      ),
                      child: Text(
                        _selectedWord ?? '',
                        style: AppTextStyles.questionText.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (parts.length > 1) Text(parts[1], style: AppTextStyles.questionText),
                  ],
                ),
                const SizedBox(height: 48),

                // Word chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(widget.question.options.length, (i) {
                    final word = widget.question.options[i];
                    final isPlaced = i == _selectedIndex;
                    return WordChip(
                      word: word,
                      isPlaced: isPlaced,
                      isSelected: false,
                      onTap: () => _selectWord(i, word),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        if (_answered)
          _FeedbackBar(
            isCorrect: _selectedIndex == widget.question.correctOptionId,
            onContinue: () {
              setState(() { _selectedWord = null; _selectedIndex = null; _answered = false; });
              widget.onNext();
            },
          )
        else
          _ActiveContinueBar(
            enabled: _selectedWord != null,
            onContinue: _submit,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Hear & Touch Question Widget
// ─────────────────────────────────────────────
class HearTouchQuestionWidget extends StatefulWidget {
  final _Question question;
  final VoidCallback onNext;
  final ValueChanged<bool> onAnswer;

  const HearTouchQuestionWidget({super.key, required this.question, required this.onNext, required this.onAnswer});

  @override
  State<HearTouchQuestionWidget> createState() => _HearTouchQuestionWidgetState();
}

class _HearTouchQuestionWidgetState extends State<HearTouchQuestionWidget> {
  final List<int> _selectedIndices = [];
  bool _answered = false;
  bool _isPlaying = false;

  void _toggleWord(int index) {
    if (_answered) return;
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _submit() {
    setState(() => _answered = true);
    widget.onAnswer(_selectedIndices.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Touch what you hear.', style: AppTextStyles.questionLabel),
                const SizedBox(height: 32),

                // Audio player
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isPlaying = !_isPlaying),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _isPlaying ? AppColors.primaryDark : AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 4)],
                      ),
                      child: Text('Listen carefully!', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Answer area
                Container(
                  width: double.infinity,
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    children: _selectedIndices.map((i) {
                      return WordChip(
                        word: widget.question.options[i],
                        isSelected: true,
                        onTap: () => _toggleWord(i),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 24),

                // Word bank
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(widget.question.options.length, (i) {
                    final isSelected = _selectedIndices.contains(i);
                    return WordChip(
                      word: widget.question.options[i],
                      isSelected: isSelected,
                      isPlaced: false,
                      onTap: () => _toggleWord(i),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        if (_answered)
          _FeedbackBar(
            isCorrect: _selectedIndices.isNotEmpty,
            onContinue: () {
              setState(() { _selectedIndices.clear(); _answered = false; _isPlaying = false; });
              widget.onNext();
            },
          )
        else
          _ActiveContinueBar(
            enabled: _selectedIndices.isNotEmpty,
            onContinue: _submit,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Shared bottom bar widgets
// ─────────────────────────────────────────────

class _FeedbackBar extends StatelessWidget {
  final bool isCorrect;
  final VoidCallback onContinue;

  const _FeedbackBar({required this.isCorrect, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, 16, AppSizes.screenPadding, 0),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.feedbackCorrectBg : AppColors.feedbackWrongBg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Exceptional' : 'Incorrect',
                style: AppTextStyles.h4.copyWith(
                  color: isCorrect ? AppColors.success : AppColors.error,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeightLg,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCorrect ? AppColors.primary : AppColors.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
                  elevation: 0,
                ),
                child: Text('Continue', style: AppTextStyles.buttonLarge),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  final VoidCallback onGotIt;
  const _ErrorBar({required this.onGotIt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, 16, AppSizes.screenPadding, 0),
      decoration: const BoxDecoration(color: AppColors.feedbackWrongBg),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error occurred', style: AppTextStyles.h4.copyWith(color: AppColors.error)),
            Text('Try again', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeightMd,
              child: ElevatedButton(
                onPressed: onGotIt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
                  elevation: 0,
                ),
                child: Text('Got it', style: AppTextStyles.buttonLarge),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DisabledContinueBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, 12, AppSizes.screenPadding, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeightLg,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarySurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
                  elevation: 0,
                  disabledBackgroundColor: AppColors.primarySurface,
                ),
                child: Text('Continue', style: AppTextStyles.buttonLarge.copyWith(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ActiveContinueBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onContinue;

  const _ActiveContinueBar({required this.enabled, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, 12, AppSizes.screenPadding, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeightLg,
              child: ElevatedButton(
                onPressed: enabled ? onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: enabled ? AppColors.primary : AppColors.primarySurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
                  elevation: 0,
                  disabledBackgroundColor: AppColors.primarySurface,
                ),
                child: Text(
                  'Continue',
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: enabled ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Leave Lesson Dialog ────────────────────────
class _LeaveLessonDialog extends StatelessWidget {
  final VoidCallback onKeepLearning;
  final VoidCallback onLeave;

  const _LeaveLessonDialog({required this.onKeepLearning, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXxl)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, 24, AppSizes.screenPadding, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 20),
            Text('Leaving Already?', style: AppTextStyles.h1),
            const SizedBox(height: 12),
            Text(
              "Wait, there's only 1 minute left\nin this lesson!",
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: AppSizes.buttonHeightLg,
              child: ElevatedButton(
                onPressed: onKeepLearning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
                  elevation: 0,
                ),
                child: Text('Keep Learning', style: AppTextStyles.buttonLarge),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: AppSizes.buttonHeightLg,
              child: OutlinedButton(
                onPressed: onLeave,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
                ),
                child: Text('Yes, Leave Now', style: AppTextStyles.buttonLarge.copyWith(color: AppColors.textPrimary)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Data Model ────────────────────────────────
class _Question {
  final int id;
  final String type;
  final String text;
  final List<String> options;
  final int correctOptionId;

  const _Question({
    required this.id,
    required this.type,
    required this.text,
    required this.options,
    required this.correctOptionId,
  });
}
