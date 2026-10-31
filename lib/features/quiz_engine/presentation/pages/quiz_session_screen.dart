import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/answer_option_tile.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/quiz_progress_bar.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/constants/demo_questions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/widgets/floating_xp_text.dart';
import '../../../../core/services/streak_service.dart';
import '../../../../core/services/progress_sync.dart';
import '../../../../core/services/hearts_service.dart';
import '../../../../core/widgets/out_of_hearts_toast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/utils/bangla_text.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../leaderboard/data/leaderboard_repository.dart';
import '../widgets/exam_tag_chip.dart';
import 'package:dio/dio.dart';

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
///
/// `xpEarned` is a local estimate (`_xpPerCorrectAnswer` per correct answer)
/// shown immediately, since grading itself never waits on the network — the
/// correct option is already embedded in the loaded question. `totalXp` is
/// always null here; the backend's authoritative running total is recorded
/// in the background by [_QuizSessionScreenState._recordAnswer] and synced
/// into the cached profile XP without blocking the UI.
typedef AnswerCallback = void Function(bool isCorrect, [int? xpEarned, int? totalXp]);

class QuizSessionScreen extends StatefulWidget {
  final int lessonId;
  final String? subject;

  /// When set, this session runs in Topic-journey mode: questions come from
  /// `/topics/{topicId}/questions` instead of the lesson/practice paths, and
  /// finishing the quiz posts to `/topics/{topicId}/complete` to advance the
  /// checkpoint chain. Takes precedence over [lessonId] when both are set.
  final int? topicId;

  const QuizSessionScreen({super.key, required this.lessonId, this.subject, this.topicId});

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  int _currentIndex = 0;
  int _score = 0;
  int _totalXpEarned = 0;
  final _stopwatch = Stopwatch();

  List<_Question> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;

  /// The user's real leaderboard standing captured right before this
  /// session's answers start changing their XP — the "before" half of the
  /// post-quiz leaderboard reveal. Null in Demo Mode or if the fetch fails.
  Future<LeaderboardData?>? _beforeLeaderboardFuture;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    HeartsService.refresh();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final examTypeId = HiveStorage.getActiveExamTypeId() ?? 1;

      if (HiveStorage.isDemoMode()) {
        _loadDemoQuestions();
        return;
      }

      _beforeLeaderboardFuture = LeaderboardRepository(DioClient())
          .getLeaderboard(examTypeId: examTypeId)
          .catchError((_) => null);

      if (widget.topicId != null) {
        final response = await DioClient().get(
          ApiEndpoints.topicQuestions(widget.topicId!),
          queryParams: {'exam_type_id': examTypeId},
        );
        final list = response.data['data'] as List;
        setState(() {
          _questions = list.map((item) => _parseApiQuestion(item)).toList();
          _isLoading = false;
        });
      } else if (widget.lessonId != 0) {
        // Fetch lesson questions
        final response = await DioClient().get(
          ApiEndpoints.lessonQuestions(widget.lessonId),
          queryParams: {'exam_type_id': examTypeId},
        );
        final list = response.data['data'] as List;
        setState(() {
          _questions = list.map((item) => _parseApiQuestion(item)).toList();
          _isLoading = false;
        });
      } else {
        // Practice session for a subject
        final subjectsResponse = await DioClient().get(
          ApiEndpoints.subjects,
          queryParams: {'exam_type_id': examTypeId},
        );
        final subjectsList = subjectsResponse.data['data'] as List;
        final matchingSubject = subjectsList.firstWhere(
          (s) => s['slug'].toString().toLowerCase() == widget.subject?.toLowerCase(),
          orElse: () => null,
        );

        if (matchingSubject != null) {
          final subjectId = matchingSubject['id'] as int;
          final lessonsResponse = await DioClient().get(
            ApiEndpoints.subjectLessons(subjectId),
            queryParams: {'exam_type_id': examTypeId},
          );
          final lessonsList = lessonsResponse.data['data'] as List;

          final List<_Question> fetchedQuestions = [];
          for (final lesson in lessonsList) {
            final lessonId = lesson['id'] as int;
            try {
              final questionsResponse = await DioClient().get(
                ApiEndpoints.lessonQuestions(lessonId),
                queryParams: {'exam_type_id': examTypeId},
              );
              final qList = questionsResponse.data['data'] as List;
              for (final q in qList) {
                fetchedQuestions.add(_parseApiQuestion(q));
              }
            } catch (e) {
              debugPrint('Error fetching questions for lesson $lessonId: $e');
            }
          }

          if (fetchedQuestions.isNotEmpty) {
            fetchedQuestions.shuffle();
            setState(() {
              _questions = fetchedQuestions.take(10).toList();
              _isLoading = false;
            });
            return;
          }
        }

        // Fallback to local demo questions if no API questions found for this subject
        _loadDemoQuestions();
      }
    } on DioException catch (e) {
      debugPrint('[QUIZ] Dio error loading questions: ${e.message}');
      setState(() {
        _errorMessage = 'Failed to load questions: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[QUIZ] Unexpected error loading questions: $e');
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  void _loadDemoQuestions() {
    var demoList = List<Map<String, dynamic>>.from(DemoQuestions.list);
    if (widget.subject != null && widget.subject!.isNotEmpty) {
      demoList = demoList.where((q) => q['subject'] == widget.subject).toList();
    }
    demoList.shuffle();
    setState(() {
      _questions = demoList.take(10).map((m) {
        final originalText = m['text'] as String;
        final cleanedText = originalText.replaceFirst(RegExp(r'^[০-৯\d]+\.\s*'), '');
        return _Question(
          id: m['id'] as int,
          type: m['type'] as String? ?? 'mcq',
          text: BanglaText.forDisplay(cleanedText),
          options: (m['options'] as List).asMap().entries.map((entry) {
            return _Option(id: entry.key, text: BanglaText.forDisplay(entry.value as String));
          }).toList(),
          correctOptionId: m['correctOptionId'] as int,
          subject: m['subject'] as String? ?? '',
          explanation: _displayOrNull(m['explanation'] as String?),
        );
      }).toList();
      _isLoading = false;
    });
  }

  static String? _displayOrNull(String? text) =>
      text == null ? null : BanglaText.forDisplay(text);

  _Question _parseApiQuestion(Map<String, dynamic> item) {
    final text = item['question_text'] as String;
    final cleanedText = text.replaceFirst(RegExp(r'^[০-৯\d]+\.\s*'), '');
    final optionsList = item['options'] as List;
    return _Question(
      id: item['id'] as int,
      type: 'mcq', // API only supports MCQ currently
      text: BanglaText.forDisplay(cleanedText),
      options: optionsList.map((o) {
        return _Option(
          id: o['id'] as int,
          text: BanglaText.forDisplay(o['option_text'] as String),
        );
      }).toList(),
      correctOptionId: (item['correct_option_id'] as int?) ?? -1,
      subject: widget.subject ?? '',
      explanation: _displayOrNull(item['explanation'] as String?),
      appearances: _ExamAppearance.listFromJson(item['appearances']),
    );
  }

  Future<Map<String, dynamic>> _checkAnswer(int questionId, int selectedOptionId) async {
    // The correct option is already embedded in the question payload (see
    // `_parseApiQuestion`/`_loadDemoQuestions`), so grading is instant and
    // never waits on a network round-trip.
    final q = _questions.firstWhere((question) => question.id == questionId);
    final isCorrect = selectedOptionId == q.correctOptionId;

    if (!HiveStorage.isDemoMode()) {
      // Record the answer server-side (XP/streak/hearts/mastery bookkeeping)
      // without blocking the instant feedback above.
      _recordAnswer(questionId, selectedOptionId);
      if (!isCorrect) HeartsService.loseOne();
    }

    return {
      'is_correct': isCorrect,
      'correct_option_id': q.correctOptionId,
      // Local estimate shown immediately; reconciled with the backend's
      // authoritative total once `_recordAnswer` resolves.
      'xp_earned': isCorrect ? _xpPerCorrectAnswer : 0,
      'total_xp': null,
    };
  }

  void _recordAnswer(int questionId, int selectedOptionId) {
    final examTypeId = HiveStorage.getActiveExamTypeId() ?? 1;
    // Tracked so the journey/home refetch after this quiz waits for it and
    // shows this session's correct answers.
    ProgressSync.track(DioClient()
        .post(
          ApiEndpoints.submitAnswer,
          data: {
            'exam_type_id': examTypeId,
            'question_id': questionId,
            'selected_option_id': selectedOptionId,
            'session_type': (widget.topicId == null && widget.lessonId > 0) ? 'lesson' : 'practice',
            'session_id': null,
          },
        )
        .then((response) {
          final data = response.data['data'] as Map<String, dynamic>?;
          final hearts = (data?['hearts'] as Map<String, dynamic>?)?['current'] as int?;
          if (hearts != null) HeartsService.applyServerCount(hearts);
          final totalXp = data?['total_xp'] as int?;
          if (totalXp == null) return;
          final profile = HiveStorage.getUserProfile() ?? <String, dynamic>{};
          profile['xp'] = totalXp;
          HiveStorage.saveUserProfile(profile);
        })
        .catchError((e) {
          // 403: no hearts left — show the refill prompt.
          if (e is DioException && e.response?.statusCode == 403) {
            HeartsService.markEmpty();
          }
          debugPrint('[QUIZ] Failed to record answer $questionId: $e');
        }));
  }

  static const int _xpPerCorrectAnswer = 10;

  void _onAnswer(bool isCorrect, [int? xpEarned, int? totalXp]) {
    if (isCorrect) {
      final earned = xpEarned ?? _xpPerCorrectAnswer;
      setState(() {
        _score++;
        _totalXpEarned += earned;
      });
      FeedbackService.playCorrect();
      HiveStorage.addXp(earned);
      // Keep `profile['xp']` — the single source of truth read by the
      // profile screen and the persistent XP header — up to date in both
      // modes: live mode gets the backend's authoritative running total,
      // demo mode (no backend total) accumulates the same 10-per-correct
      // rule locally on top of whatever profile map already exists.
      final profile = HiveStorage.getUserProfile() ?? <String, dynamic>{};
      profile['xp'] = totalXp ?? ((profile['xp'] as num?)?.toInt() ?? 0) + earned;
      HiveStorage.saveUserProfile(profile);
      if (mounted) {
        FloatingXpText.show(context, xp: earned);
      }
      final q = _questions[_currentIndex];
      if (q.subject.isNotEmpty) {
        HiveStorage.incrementCorrectQuestionsCount(q.subject);
      }
    } else {
      FeedbackService.playWrong();
    }
  }

  void _nextQuestion() async {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      // Quiz complete
      _stopwatch.stop();
      final elapsed = _stopwatch.elapsed;
      final timeStr =
          '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
      final accuracy = _questions.isEmpty ? 0 : ((_score / _questions.length) * 100).round();
      final points = _totalXpEarned;

      // Streak + completion writes run in the background so the result screen
      // opens immediately. The journey/home refetch awaits ProgressSync, so the
      // next topic still unlocks and counts are fresh when the user gets back.
      ProgressSync.track(_syncCompletion(accuracy));

      // Fetched when the quiz loaded, so it's normally ready; never hold the
      // result screen for it (null just skips the leaderboard reveal).
      final beforeLeaderboard = await (_beforeLeaderboardFuture ?? Future.value(null))
          .timeout(const Duration(milliseconds: 500), onTimeout: () => null);

      if (mounted) {
        context.pushReplacement(
          AppRoutes.quizCompleted,
          extra: {
            'time_taken': timeStr,
            'accuracy': accuracy,
            'points': points,
            'before_leaderboard': beforeLeaderboard,
          },
        );
      }
    }
  }

  Future<void> _syncCompletion(int accuracy) async {
    // Only real lessons are completed via /lessons/{id}/complete. A topic quiz
    // used to pass its topic id here, which marked an unrelated lesson complete.
    await StreakService.updateStreak(
      lessonId: widget.topicId == null ? widget.lessonId : 0,
      score: accuracy,
    );

    // Mark the checkpoint complete so the journey advances to the next Topic.
    if (widget.topicId != null && !HiveStorage.isDemoMode()) {
      try {
        await DioClient()
            .post(
              ApiEndpoints.completeTopic(widget.topicId!),
              data: {'score': accuracy},
            )
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('[QUIZ] Failed to complete topic ${widget.topicId}: $e');
      }
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Retry',
                  onTap: _loadQuestions,
                  height: AppSizes.buttonHeightMd,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('No questions available.'),
        ),
      );
    }

    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: QuizAppBar(
        current: _currentIndex + 1,
        total: _questions.length,
        onBack: () => context.go(AppRoutes.home),
        onMenu: _showLeaveDialog,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildQuestionType(q),
          // Out of hearts: answers would be rejected, so block the quiz
          // behind the refill prompt until the hearts are back.
          if (!HiveStorage.isDemoMode())
            ValueListenableBuilder<Box>(
              valueListenable: HiveStorage.userBoxListenable,
              builder: (context, box, _) => HiveStorage.getHearts() > 0
                  ? const SizedBox.shrink()
                  : const Positioned.fill(child: OutOfHeartsToast()),
            ),
        ],
      ),
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
          onCheckAnswer: _checkAnswer,
        );
      default: // mcq
        return McqQuestionWidget(
          question: q,
          onNext: _nextQuestion,
          onAnswer: _onAnswer,
          onCheckAnswer: _checkAnswer,
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
  final AnswerCallback onAnswer;
  final Future<Map<String, dynamic>> Function(int questionId, int optionId) onCheckAnswer;

  const McqQuestionWidget({
    super.key,
    required this.question,
    required this.onNext,
    required this.onAnswer,
    required this.onCheckAnswer,
  });

  @override
  State<McqQuestionWidget> createState() => _McqQuestionWidgetState();
}

class _McqQuestionWidgetState extends State<McqQuestionWidget> {
  int? _selectedIndex;
  bool _answered = false;
  bool? _isCorrect;
  int? _correctOptionId;
  bool _checking = false;

  void _select(int index) {
    if (_answered || _checking) return;
    setState(() {
      if (_selectedIndex == index) {
        _selectedIndex = null;
      } else {
        _selectedIndex = index;
      }
    });
  }

  void _check() async {
    if (_selectedIndex == null || _answered || _checking) return;
    setState(() => _checking = true);
    final selectedOption = widget.question.options[_selectedIndex!];
    try {
      final result = await widget.onCheckAnswer(widget.question.id, selectedOption.id);
      if (!mounted) return;
      final isCorrect = result['is_correct'] as bool;
      final correctId = result['correct_option_id'] as int;
      final xpEarned = result['xp_earned'] as int?;
      final totalXp = result['total_xp'] as int?;
      setState(() {
        _answered = true;
        _isCorrect = isCorrect;
        _correctOptionId = correctId;
        _checking = false;
      });
      widget.onAnswer(isCorrect, xpEarned, totalXp);
    } catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
    }
  }

  AnswerState _stateFor(int index) {
    if (!_answered) {
      return index == _selectedIndex ? AnswerState.selected : AnswerState.idle;
    }
    final optionId = widget.question.options[index].id;
    if (optionId == _correctOptionId) return AnswerState.correct;
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
                Text('Give the correct answer.',
                    style: AppTextStyles.questionLabel),
                const SizedBox(height: 32),

                // Question text
                Center(
                  child: Text(
                    widget.question.text,
                    style: AppTextStyles.questionText,
                    textAlign: TextAlign.center,
                  ),
                ),

                // "Appeared in" exam-year tags (e.g. BCS-60, NTRCA 2023) —
                // shown below-right of the question text when this question
                // has repeated across exam years/types.
                if (widget.question.appearances.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ExamAppearanceRow(appearances: widget.question.appearances),
                ],

                const SizedBox(height: 40),

                // Options
                ...List.generate(
                  widget.question.options.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AnswerOptionTile(
                      text: widget.question.options[i].text,
                      state: _stateFor(i),
                      onTap: () => _select(i),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom interactive bar
        QuizBottomBar(
          answered: _answered,
          isCorrect: _isCorrect,
          hasSelection: _selectedIndex != null && !_checking,
          onCheck: _check,
          onSkip: widget.onNext,
          onNext: () {
            setState(() {
              _selectedIndex = null;
              _answered = false;
              _isCorrect = null;
              _correctOptionId = null;
            });
            widget.onNext();
          },
          explanation: widget.question.explanation,
          onExplanation: () {
            if (widget.question.explanation != null) {
              _showExplanationBottomSheet(context, widget.question.explanation!);
            }
          },
        ),
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
  final AnswerCallback onAnswer;

  const MatchQuestionWidget(
      {super.key,
      required this.question,
      required this.onNext,
      required this.onAnswer});

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
        widget.onAnswer(false);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted)
            setState(() {
              _wrong.clear();
              _hasError = false;
            });
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
                    text: cols[i].text,
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
          _ErrorBar(onGotIt: () => setState(() => _hasError = false))
        else
          QuizBottomBar(
            answered: _allMatched,
            isCorrect: true,
            hasSelection: false,
            onCheck: () {},
            onSkip: widget.onNext,
            onNext: () {
              setState(() {
                _matched.clear();
                _allMatched = false;
              });
              widget.onNext();
            },
            explanation: widget.question.explanation,
            onExplanation: () {
              if (widget.question.explanation != null) {
                _showExplanationBottomSheet(context, widget.question.explanation!);
              }
            },
          ),
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
  final AnswerCallback onAnswer;
  final Future<Map<String, dynamic>> Function(int questionId, int optionId) onCheckAnswer;

  const FillBlankQuestionWidget({
    super.key,
    required this.question,
    required this.onNext,
    required this.onAnswer,
    required this.onCheckAnswer,
  });

  @override
  State<FillBlankQuestionWidget> createState() =>
      _FillBlankQuestionWidgetState();
}

class _FillBlankQuestionWidgetState extends State<FillBlankQuestionWidget> {
  String? _selectedWord;
  int? _selectedIndex;
  bool _answered = false;
  bool? _isCorrect;
  bool _checking = false;

  void _selectWord(int index, String word) {
    if (_answered || _checking) return;
    setState(() {
      if (_selectedIndex == index) {
        _selectedWord = null;
        _selectedIndex = null;
      } else {
        _selectedWord = word;
        _selectedIndex = index;
      }
    });
  }

  void _submit() async {
    if (_selectedIndex == null || _answered || _checking) return;
    setState(() => _checking = true);
    final selectedOption = widget.question.options[_selectedIndex!];
    try {
      final result = await widget.onCheckAnswer(widget.question.id, selectedOption.id);
      if (!mounted) return;
      final isCorrect = result['is_correct'] as bool;
      final xpEarned = result['xp_earned'] as int?;
      final totalXp = result['total_xp'] as int?;
      setState(() {
        _isCorrect = isCorrect;
        _answered = true;
        _checking = false;
      });
      widget.onAnswer(isCorrect, xpEarned, totalXp);
    } catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
    }
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
                        border: Border(
                            bottom: BorderSide(
                                color: _selectedWord != null
                                    ? AppColors.primary
                                    : AppColors.textHint,
                                width: 2)),
                      ),
                      child: Text(
                        _selectedWord ?? '',
                        style: AppTextStyles.questionText.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (parts.length > 1)
                      Text(parts[1], style: AppTextStyles.questionText),
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
                      word: word.text,
                      isPlaced: isPlaced,
                      isSelected: false,
                      onTap: () => _selectWord(i, word.text),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),

        // Bottom interactive bar
        QuizBottomBar(
          answered: _answered,
          isCorrect: _isCorrect,
          hasSelection: _selectedWord != null && !_checking,
          onCheck: _submit,
          onSkip: widget.onNext,
          onNext: () {
            setState(() {
              _selectedWord = null;
              _selectedIndex = null;
              _answered = false;
              _isCorrect = null;
            });
            widget.onNext();
          },
          explanation: widget.question.explanation,
          onExplanation: () {
            if (widget.question.explanation != null) {
              _showExplanationBottomSheet(context, widget.question.explanation!);
            }
          },
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
  final AnswerCallback onAnswer;

  const HearTouchQuestionWidget(
      {super.key,
      required this.question,
      required this.onNext,
      required this.onAnswer});

  @override
  State<HearTouchQuestionWidget> createState() =>
      _HearTouchQuestionWidgetState();
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
                Text('Touch what you hear.',
                    style: AppTextStyles.questionLabel),
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
                          color: _isPlaying
                              ? AppColors.primaryDark
                              : AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6))
                          ],
                        ),
                        child: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        boxShadow: const [
                          BoxShadow(color: AppColors.shadowColor, blurRadius: 4)
                        ],
                      ),
                      child: Text('Listen carefully!',
                          style: AppTextStyles.bodySmall
                              .copyWith(fontWeight: FontWeight.w600)),
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
                        word: widget.question.options[i].text,
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
                      word: widget.question.options[i].text,
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
        QuizBottomBar(
          answered: _answered,
          isCorrect: _selectedIndices.isNotEmpty,
          hasSelection: _selectedIndices.isNotEmpty,
          onCheck: _submit,
          onSkip: widget.onNext,
          onNext: () {
            setState(() {
              _selectedIndices.clear();
              _answered = false;
              _isPlaying = false;
            });
            widget.onNext();
          },
          explanation: widget.question.explanation,
          onExplanation: () {
            if (widget.question.explanation != null) {
              _showExplanationBottomSheet(context, widget.question.explanation!);
            }
          },
        ),
      ],
    );
  }
}

void _showExplanationBottomSheet(BuildContext context, String explanation) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 8),
                Text('Explanation', style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              explanation.isNotEmpty ? explanation : 'No explanation available for this question.',
              style: AppTextStyles.bodyMedium.copyWith(height: 1.5, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Got it',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}

class QuizBottomBar extends StatelessWidget {
  final bool answered;
  final bool? isCorrect;
  final bool hasSelection;
  final VoidCallback onCheck;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final String? explanation;
  final VoidCallback? onExplanation;

  const QuizBottomBar({
    super.key,
    required this.answered,
    this.isCorrect,
    required this.hasSelection,
    required this.onCheck,
    required this.onSkip,
    required this.onNext,
    this.explanation,
    this.onExplanation,
  });

  @override
  Widget build(BuildContext context) {
    if (!answered) {
      return Container(
        padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding, 12, AppSizes.screenPadding, 0),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider, width: 1.5)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppButton.outlined(
                      label: 'Skip',
                      onTap: onSkip,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Check',
                      onTap: hasSelection ? onCheck : null,
                      variant: hasSelection ? AppButtonVariant.primary : AppButtonVariant.disabled,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    }

    final correct = isCorrect ?? false;
    final showExplanation = !correct && explanation != null && explanation!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding, 16, AppSizes.screenPadding, 0),
      decoration: BoxDecoration(
        color: correct ? AppColors.feedbackCorrectBg : AppColors.feedbackWrongBg,
        border: Border(
          top: BorderSide(
            color: correct ? AppColors.feedbackCorrectBorder : AppColors.feedbackWrongBorder,
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: correct ? AppColors.primary : AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      correct ? '✓' : '✕',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  correct ? 'Correct!' : 'Incorrect',
                  style: AppTextStyles.h4.copyWith(
                    color: correct ? AppColors.answerCorrectText : AppColors.answerWrongText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (showExplanation) ...[
                  Expanded(
                    child: AppButton.outlined(
                      label: 'Explanation',
                      onTap: onExplanation,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: AppButton(
                    label: 'Next',
                    onTap: onNext,
                    variant: correct ? AppButtonVariant.primary : AppButtonVariant.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared bottom bar widgets (legacy/fallback)
// ─────────────────────────────────────────────

class _FeedbackBar extends StatelessWidget {
  final bool isCorrect;
  final VoidCallback onContinue;

  const _FeedbackBar({required this.isCorrect, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding, 16, AppSizes.screenPadding, 0),
      decoration: BoxDecoration(
        color:
            isCorrect ? AppColors.feedbackCorrectBg : AppColors.feedbackWrongBg,
        border: Border(
          top: BorderSide(
            color: isCorrect ? AppColors.feedbackCorrectBorder : AppColors.feedbackWrongBorder,
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isCorrect ? AppColors.primary : AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    isCorrect ? '✓' : '✕',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct!' : 'Incorrect',
                style: AppTextStyles.h4.copyWith(
                  color: isCorrect ? AppColors.answerCorrectText : AppColors.answerWrongText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            AppButton(
              label: 'Continue',
              onTap: onContinue,
              variant: isCorrect ? AppButtonVariant.primary : AppButtonVariant.accent,
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
      padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding, 16, AppSizes.screenPadding, 0),
      decoration: BoxDecoration(
        color: AppColors.feedbackWrongBg,
        border: Border(
          top: BorderSide(
            color: AppColors.feedbackWrongBorder,
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error occurred',
                style: AppTextStyles.h4.copyWith(color: AppColors.answerWrongText, fontWeight: FontWeight.w700)),
            Text('Try again',
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.answerWrongText)),
            const SizedBox(height: 12),
            AppButton.danger(
              label: 'Got it',
              onTap: onGotIt,
              height: AppSizes.buttonHeightMd,
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
      padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding, 12, AppSizes.screenPadding, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppButton(
              label: 'Continue',
              onTap: null,
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
      padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding, 12, AppSizes.screenPadding, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: 'Continue',
              onTap: enabled ? onContinue : null,
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

  const _LeaveLessonDialog(
      {required this.onKeepLearning, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXxl)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding, 24, AppSizes.screenPadding, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 20),
            Text('Leaving Already?', style: AppTextStyles.h1),
            const SizedBox(height: 12),
            Text(
              "Wait, there's only 1 minute left\nin this lesson!",
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Keep Learning',
              onTap: onKeepLearning,
              variant: AppButtonVariant.primary,
            ),
            const SizedBox(height: 12),
            AppButton.outlined(
              label: 'Yes, Leave Now',
              onTap: onLeave,
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
  final List<_Option> options;
  final int correctOptionId;
  final String subject;
  final String? explanation;
  final List<_ExamAppearance> appearances;

  const _Question({
    required this.id,
    required this.type,
    required this.text,
    required this.options,
    required this.correctOptionId,
    this.subject = '',
    this.explanation,
    this.appearances = const [],
  });
}

class _Option {
  final int id;
  final String text;

  const _Option({
    required this.id,
    required this.text,
  });
}

/// Right-aligned row of `ExamTagChip`s for a question's exam-year
/// appearances. Caps at 4 visible chips with a trailing "+N more" chip to
/// avoid layout blowup on heavily-repeated questions.
class _ExamAppearanceRow extends StatelessWidget {
  final List<_ExamAppearance> appearances;
  static const int _maxVisible = 4;

  const _ExamAppearanceRow({required this.appearances});

  @override
  Widget build(BuildContext context) {
    final labels = appearances
        .map((a) => a.displayLabel)
        .whereType<String>()
        .toList();
    if (labels.isEmpty) return const SizedBox.shrink();

    final visible = labels.take(_maxVisible).toList();
    final overflow = labels.length - visible.length;

    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final label in visible) ExamTagChip(label: label),
          if (overflow > 0) ExamTagChip(label: '+$overflow more'),
        ],
      ),
    );
  }
}

/// A single exam-type + year the question has appeared in (e.g. "BCS-60").
class _ExamAppearance {
  final String examTypeName;
  final String? examTypeCode;
  final int? year;
  final String? sourceBatch;

  const _ExamAppearance({
    required this.examTypeName,
    this.examTypeCode,
    this.year,
    this.sourceBatch,
  });

  /// Prefer the free-text source_batch (e.g. "BCS-60") if present, else fall
  /// back to "{examTypeCode} {year}" (e.g. "NTRCA 2023"). Null if neither.
  String? get displayLabel {
    if (sourceBatch != null && sourceBatch!.trim().isNotEmpty) {
      return sourceBatch;
    }
    if (year != null) {
      return '${examTypeCode ?? examTypeName} $year';
    }
    return null;
  }

  static List<_ExamAppearance> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => _ExamAppearance(
              examTypeName: m['exam_type_name'] as String? ?? '',
              examTypeCode: m['exam_type_code'] as String?,
              year: m['year'] as int?,
              sourceBatch: m['source_batch'] as String?,
            ))
        .toList();
  }
}
