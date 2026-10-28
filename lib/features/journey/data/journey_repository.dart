import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/domain/entities.dart';
import '../../../core/storage/hive_storage.dart';

/// ─────────────────────────────────────────────
/// Journey Repository — Topic checkpoint chain
/// ─────────────────────────────────────────────

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return JourneyRepository(DioClient());
});

/// Ordered Topic checkpoints for a subject, keyed by subjectId. autoDispose so
/// reopening the journey always refetches: finishing a quiz goes back to home,
/// which removes this screen, so a cached list would keep the next topic locked.
final topicsProvider =
    FutureProvider.autoDispose.family<List<Topic>, int>((ref, subjectId) async {
  final repository = ref.watch(journeyRepositoryProvider);
  final examTypeId = HiveStorage.getActiveExamTypeId() ?? 1;
  return repository.getTopics(subjectId: subjectId, examTypeId: examTypeId);
});

class JourneyRepository {
  final DioClient _client;

  JourneyRepository(this._client);

  Future<List<Topic>> getTopics({
    required int subjectId,
    required int examTypeId,
  }) async {
    try {
      final response = await _client.get(
        ApiEndpoints.subjectTopics(subjectId),
        queryParams: {'exam_type_id': examTypeId},
      );
      final data = response.data['data'] as List;
      return data
          .map((t) => Topic.fromJson(t as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data as Map<String, dynamic>? ?? {},
        e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> completeTopic({
    required int topicId,
    required int score,
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.completeTopic(topicId),
        data: {'score': score},
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
