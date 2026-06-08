import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/domain/entities.dart';
import '../../../core/storage/hive_storage.dart';

/// ─────────────────────────────────────────────
/// Quiz Repository — Questions + Answers
/// ─────────────────────────────────────────────

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(DioClient());
});

// Quiz session state
final quizSessionProvider = StateNotifierProvider.family<QuizSessionNotifier, QuizSessionState, int>((ref, lessonId) {
  return QuizSessionNotifier(
    repository: ref.read(quizRepositoryProvider),
    lessonId: lessonId,
  );
});

/// Quiz session state model
class QuizSessionState {
  final List<Question> questions;
  final int currentIndex;
  final int score;
  final bool isLoading;
  final String? error;
  final bool isComplete;

  const QuizSessionState({
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.isLoading = true,
    this.error,
    this.isComplete = false,
  });

  Question? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get total => questions.length;

  QuizSessionState copyWith({
    List<Question>? questions,
    int? currentIndex,
    int? score,
    bool? isLoading,
    String? error,
    bool? isComplete,
  }) {
    return QuizSessionState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class QuizSessionNotifier extends StateNotifier<QuizSessionState> {
  final QuizRepository _repository;
  final int _lessonId;

  QuizSessionNotifier({
    required QuizRepository repository,
    required int lessonId,
  }) : _repository = repository,
       _lessonId = lessonId,
       super(const QuizSessionState()) {
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final examTypeId = HiveStorage.getActiveExamTypeId() ?? 1;
      final questions = await _repository.getLessonQuestions(
        lessonId: _lessonId,
        examTypeId: examTypeId,
      );
      state = state.copyWith(questions: questions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void answerQuestion({
    required int questionId,
    required int selectedOptionId,
    required bool isCorrect,
  }) {
    if (isCorrect) {
      state = state.copyWith(score: state.score + 1);
    }
    // Submit to API in background (fire-and-forget)
    _repository.submitAnswer(
      questionId: questionId,
      selectedOptionId: selectedOptionId,
      examTypeId: HiveStorage.getActiveExamTypeId() ?? 1,
    );
  }

  void nextQuestion() {
    if (state.currentIndex >= state.questions.length - 1) {
      state = state.copyWith(isComplete: true);
    } else {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }
}

/// Quiz Repository (data source)
class QuizRepository {
  final DioClient _client;

  QuizRepository(this._client);

  Future<List<Question>> getLessonQuestions({
    required int lessonId,
    required int examTypeId,
  }) async {
    try {
      final response = await _client.get(
        ApiEndpoints.lessonQuestions(lessonId),
        queryParams: {'exam_type_id': examTypeId},
      );
      final data = response.data['data'] as List;
      return data
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data as Map<String, dynamic>? ?? {},
        e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> submitAnswer({
    required int questionId,
    required int selectedOptionId,
    required int examTypeId,
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.submitAnswer,
        data: {
          'question_id': questionId,
          'selected_option_id': selectedOptionId,
          'exam_type_id': examTypeId,
        },
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data as Map<String, dynamic>? ?? {},
        e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> completeLesson({
    required int lessonId,
    required int examTypeId,
    required int score,
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.completeLesson(lessonId),
        data: {
          'exam_type_id': examTypeId,
          'score': score,
        },
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data as Map<String, dynamic>? ?? {},
        e.response?.statusCode,
      );
    }
  }
}
