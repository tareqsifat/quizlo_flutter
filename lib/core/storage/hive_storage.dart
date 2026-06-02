import 'package:hive_flutter/hive_flutter.dart';

/// ─────────────────────────────────────────────
/// Hive Storage — Lightweight local cache
/// For user profile, settings, recently viewed
/// ─────────────────────────────────────────────
class HiveStorage {
  static const String _boxUser = 'user_box';
  static const String _boxSettings = 'settings_box';
  static const String _boxCache = 'cache_box';
  static const String _boxOnboarding = 'onboarding_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxUser);
    await Hive.openBox(_boxSettings);
    await Hive.openBox(_boxCache);
    await Hive.openBox(_boxOnboarding);
  }

  // ── User Box ───────────────────────────────
  static Box get _user => Hive.box(_boxUser);

  static Future<void> saveUserProfile(Map<String, dynamic> data) =>
      _user.put('profile', data);

  static Map<String, dynamic>? getUserProfile() {
    final data = _user.get('profile');
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }

  static Future<void> saveActiveExamTypeId(int id) =>
      _user.put('active_exam_type_id', id);

  static int? getActiveExamTypeId() =>
      _user.get('active_exam_type_id') as int?;

  static Future<void> setDemoMode(bool isDemo) =>
      _user.put('is_demo_mode', isDemo);

  static bool isDemoMode() =>
      _user.get('is_demo_mode', defaultValue: false) as bool;

  static Future<void> clearUser() => _user.clear();

  // ── Onboarding Box ─────────────────────────
  static Box get _onboarding => Hive.box(_boxOnboarding);

  static Future<void> setOnboardingDone(bool done) =>
      _onboarding.put('onboarding_done', done);

  static bool isOnboardingDone() =>
      _onboarding.get('onboarding_done', defaultValue: false) as bool;

  static Future<void> setExamTypeSelected(bool selected) =>
      _onboarding.put('exam_type_selected', selected);

  static bool isExamTypeSelected() =>
      _onboarding.get('exam_type_selected', defaultValue: false) as bool;

  // ── Settings Box ───────────────────────────
  static Box get _settings => Hive.box(_boxSettings);

  static Future<void> setDailyGoal(int goal) =>
      _settings.put('daily_goal', goal);

  static int getDailyGoal() =>
      _settings.get('daily_goal', defaultValue: 20) as int;

  static Future<void> setNotificationsEnabled(bool enabled) =>
      _settings.put('notifications_enabled', enabled);

  static bool isNotificationsEnabled() =>
      _settings.get('notifications_enabled', defaultValue: true) as bool;

  // ── Cache Box ──────────────────────────────
  static Box get _cache => Hive.box(_boxCache);

  static Future<void> cacheExamTypes(List<Map<String, dynamic>> data) =>
      _cache.put('exam_types', data);

  static List<Map<String, dynamic>>? getCachedExamTypes() {
    final data = _cache.get('exam_types');
    if (data == null) return null;
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> clearCache() => _cache.clear();

  // ── Full Reset ─────────────────────────────
  static Future<void> clearAll() async {
    await _user.clear();
    await _settings.clear();
    await _cache.clear();
    await _onboarding.clear();
  }
}
