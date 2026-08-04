import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/storage/hive_storage.dart';

/// ─────────────────────────────────────────────
/// Profile Repository — GET /user/profile
/// Demo Mode has no real backend account behind it (see HiveStorage
/// .isDemoMode usage across the app), so it never calls this endpoint —
/// the profile screen renders its existing local/demo values instead.
/// ─────────────────────────────────────────────

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(DioClient());
});

/// Re-fetch by calling `ref.refresh(userProfileProvider.future)`.
/// Null in Demo Mode (by design) or if the fetch fails — the screen falls
/// back to the cached Hive profile (populated at login) in either case.
final userProfileProvider = FutureProvider.autoDispose<UserProfileData?>((ref) async {
  if (HiveStorage.isDemoMode()) return null;
  try {
    return await ref.watch(profileRepositoryProvider).getProfile();
  } catch (_) {
    return null;
  }
});

class ExamTypeEnrollment {
  final int id;
  final String name;
  final String code;
  final bool isPrimary;

  const ExamTypeEnrollment({
    required this.id,
    required this.name,
    required this.code,
    required this.isPrimary,
  });

  factory ExamTypeEnrollment.fromJson(Map<String, dynamic> json) => ExamTypeEnrollment(
        id: json['id'] as int,
        name: json['name'] as String,
        code: json['code'] as String,
        isPrimary: json['is_primary'] as bool? ?? false,
      );
}

class UserProfileData {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final int dailyGoal;
  final List<ExamTypeEnrollment> examTypes;

  const UserProfileData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.dailyGoal,
    required this.examTypes,
  });

  ExamTypeEnrollment? get primaryExamType {
    for (final e in examTypes) {
      if (e.isPrimary) return e;
    }
    return examTypes.isNotEmpty ? examTypes.first : null;
  }

  factory UserProfileData.fromJson(Map<String, dynamic> json) => UserProfileData(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        avatar: json['avatar'] as String?,
        dailyGoal: json['daily_goal'] as int? ?? 20,
        examTypes: (json['exam_types'] as List? ?? [])
            .map((e) => ExamTypeEnrollment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ProfileRepository {
  final DioClient _client;

  ProfileRepository(this._client);

  Future<UserProfileData> getProfile() async {
    try {
      final response = await _client.get(ApiEndpoints.userProfile);
      final data = response.data['data'] as Map<String, dynamic>;
      return UserProfileData.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data as Map<String, dynamic>? ?? {},
        e.response?.statusCode,
      );
    }
  }
}
