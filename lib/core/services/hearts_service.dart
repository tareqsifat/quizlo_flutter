import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';
import '../network/dio_client.dart';
import '../storage/hive_storage.dart';

/// Keeps the cached heart count (HiveStorage) in step with the backend.
/// Each wrong answer costs a heart; at 0 the backend rejects answers (403)
/// until the hearts are refilled.
class HeartsService {
  HeartsService._();

  /// Loads the current hearts from the server. No-op in demo mode.
  static Future<void> refresh() async {
    if (HiveStorage.isDemoMode()) return;
    try {
      final response = await DioClient().get(ApiEndpoints.hearts);
      final data = response.data['data'] as Map<String, dynamic>;
      await HiveStorage.setHearts(
        data['current_hearts'] as int? ?? 5,
        max: data['max_hearts'] as int?,
      );
    } catch (e) {
      debugPrint('[HEARTS] Failed to load hearts: $e');
    }
  }

  /// Optimistic deduction for a wrong answer, before the server confirms it.
  static Future<void> loseOne() =>
      HiveStorage.setHearts(math.max(0, HiveStorage.getHearts() - 1));

  /// Applies the count from an answer response. The server deducts in a
  /// queued job, so its figure can lag behind ours; only ever lower the count.
  static Future<void> applyServerCount(int current) async {
    if (current < HiveStorage.getHearts()) {
      await HiveStorage.setHearts(current);
    }
  }

  /// The server rejected an answer for having no hearts left.
  static Future<void> markEmpty() => HiveStorage.setHearts(0);

  /// Free refill offered when the hearts run out. A rewarded ad will be shown
  /// before this call in future. Returns false if the refill failed.
  static Future<bool> autoRefill() async {
    try {
      final response = await DioClient().post(ApiEndpoints.heartAutoRefill);
      final data = response.data['data'] as Map<String, dynamic>;
      final max = data['max_hearts'] as int? ?? HiveStorage.getMaxHearts();
      await HiveStorage.setHearts(data['current_hearts'] as int? ?? max, max: max);
      return true;
    } catch (e) {
      debugPrint('[HEARTS] Auto refill failed: $e');
      return false;
    }
  }
}
