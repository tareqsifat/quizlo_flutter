import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/domain/entities.dart';

/// ─────────────────────────────────────────────
/// Auth Repository — handles all auth API calls
/// ─────────────────────────────────────────────

// Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(DioClient());
});

// State notifier for auth state
final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final isAuth = await SecureStorage.isAuthenticated();
      if (isAuth) {
        final cached = HiveStorage.getUserProfile();
        if (cached != null) {
          state = AsyncValue.data(User.fromJson(cached));
        } else {
          state = const AsyncValue.data(null);
        }
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      state = const AsyncValue.data(null);
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.login(email: email, password: password);
      await SecureStorage.saveAccessToken(result.$1.accessToken);
      await SecureStorage.saveRefreshToken(result.$1.refreshToken);
      await HiveStorage.saveUserProfile(result.$2.toJson());
      state = AsyncValue.data(result.$2);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.register(
        name: name, email: email, password: password,
      );
      await SecureStorage.saveAccessToken(result.$1.accessToken);
      await SecureStorage.saveRefreshToken(result.$1.refreshToken);
      await HiveStorage.saveUserProfile(result.$2.toJson());
      state = AsyncValue.data(result.$2);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    try { await _repository.logout(); } catch (_) {}
    await SecureStorage.clearAll();
    await HiveStorage.clearAll();
    state = const AsyncValue.data(null);
  }
}

/// Auth Repository
class AuthRepository {
  final DioClient _client;

  AuthRepository(this._client);

  /// Login with email + password
  Future<(AuthTokens, User)> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
        'device_name': 'mobile',
      });
      final data = response.data['data'] as Map<String, dynamic>;
      final tokens = AuthTokens.fromJson(data['token'] as Map<String, dynamic>);
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      return (tokens, user);
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data as Map<String, dynamic>? ?? {},
        e.response?.statusCode,
      );
    }
  }

  /// Register new user
  Future<(AuthTokens, User)> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(ApiEndpoints.register, data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'device_name': 'mobile',
      });
      final data = response.data['data'] as Map<String, dynamic>;
      final tokens = AuthTokens.fromJson(data['token'] as Map<String, dynamic>);
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      return (tokens, user);
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data as Map<String, dynamic>? ?? {},
        e.response?.statusCode,
      );
    }
  }

  /// Send OTP for forgot password
  Future<void> sendOtp(String email) async {
    try {
      await _client.post(ApiEndpoints.sendOtp, data: {'email': email});
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data as Map<String, dynamic>? ?? {},
        e.response?.statusCode,
      );
    }
  }

  /// Verify OTP
  Future<String> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _client.post(ApiEndpoints.verifyOtp, data: {
        'email': email,
        'otp': otp,
      });
      return response.data['data']['reset_token'] as String;
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data as Map<String, dynamic>? ?? {},
        e.response?.statusCode,
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    await _client.post(ApiEndpoints.logout);
  }
}
