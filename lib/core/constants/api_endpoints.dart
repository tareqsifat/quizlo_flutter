/// ─────────────────────────────────────────────
/// Quizlo API Endpoints
/// Base URL: https://quizlobackend-production.up.railway.app/api/v1
/// ─────────────────────────────────────────────
abstract class ApiEndpoints {
  static const String baseUrl =
      'https://quizlobackend-production.up.railway.app/api/v1/';
  // No staging environment — production only

  // ── Authentication ─────────────────────────
  static const String sendOtp = 'auth/send-otp';
  static const String verifyOtp = 'auth/verify-otp';
  static const String refreshToken = 'auth/refresh-token';
  static const String login = 'auth/login';
  static const String register = 'auth/register';
  static const String logout = 'auth/logout';
  static const String googleToken = 'auth/google/token'; // Flutter mobile Google Sign-In

  // ── Exam Types ─────────────────────────────
  static const String examTypes = 'exam-types';
  static const String userExamTypes = 'user/exam-types';
  static String setExamTypePrimary(int id) => 'user/exam-types/$id/set-primary';
  static String removeExamType(int id) => 'user/exam-types/$id';

  // ── User Profile ───────────────────────────
  static const String userProfile = 'user/profile';
  static const String updateProfile = 'user/profile';
  static const String updateDailyGoal = 'user/daily-goal';

  // ── Content ────────────────────────────────
  static const String subjects = 'subjects';
  static String subjectLessons(int subjectId) => 'subjects/$subjectId/lessons';
  static String lessonQuestions(int lessonId) => 'lessons/$lessonId/questions';
  static String completeLesson(int lessonId) => 'lessons/$lessonId/complete';

  // ── Answer Submission ──────────────────────
  static const String submitAnswer = 'questions/answer';

  // ── Gamification ───────────────────────────
  static const String gamificationDashboard = 'gamification/dashboard';
  static const String streak = 'gamification/streak';
  static const String streakFreeze = 'gamification/streak/freeze';
  static const String hearts = 'gamification/hearts';
  static const String heartRefill = 'gamification/hearts/refill';
  static const String coins = 'gamification/coins';
  static const String spendCoins = 'gamification/coins/spend';

  // ── League ─────────────────────────────────
  static const String leagueCurrent = 'league/current';
  static const String leagueHistory = 'league/history';

  // ── Model Tests ────────────────────────────
  static const String modelTests = 'model-tests';
  static String startModelTest(int testId) => 'model-tests/$testId/start';
  static String submitModelTest(int sessionId) => 'exam-sessions/$sessionId/submit';

  // ── Progress ───────────────────────────────
  static const String progressOverview = 'progress/overview';
  static const String progressHeatmap = 'progress/heatmap';
  static const String progressSubjects = 'progress/subjects';

  // ── Achievements ───────────────────────────
  static const String achievements = 'achievements';

  // ── Notifications ──────────────────────────
  static const String notifications = 'notifications';
  static const String markNotificationRead = 'notifications/{id}/read';
  static const String fcmToken = 'notifications/fcm-token';

  // ── HTTP Config ────────────────────────────
  static const int connectTimeout = 30000;  // 30s
  static const int receiveTimeout = 30000;  // 30s
  static const int sendTimeout = 30000;     // 30s
}
