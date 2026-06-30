import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/domain/entities.dart';
import '../../../core/services/app_toast.dart';

/// ─────────────────────────────────────────────
/// Auth Repository — handles all auth API calls
/// ─────────────────────────────────────────────

// Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(DioClient());
});

/// Singleton GoogleSignIn instance — scoped to this auth feature
final _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
);

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
    debugPrint('[AUTH] Initializing auth state…');
    try {
      final isAuth = await SecureStorage.isAuthenticated()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('[AUTH] ⚠️ _init auth check timed out');
        AppToast.show('⚠️ Auth init timed out. Please restart the app.', isError: true);
        return false;
      });
      if (isAuth) {
        final cached = HiveStorage.getUserProfile();
        if (cached != null) {
          debugPrint('[AUTH] ✅ Restored session from cache');
          state = AsyncValue.data(User.fromJson(cached));
        } else {
          debugPrint('[AUTH] Authenticated but no cached profile');
          state = const AsyncValue.data(null);
        }
      } else {
        debugPrint('[AUTH] Not authenticated');
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      debugPrint('[AUTH] ❌ _init failed: $e');
      AppToast.showError('Auth init error: $e');
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
      rethrow;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    debugPrint('[AUTH][SignUp] Attempting registration for $email');
    try {
      await _repository.register(
        name: name,
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      debugPrint('[AUTH][SignUp] ❌ Registration failed — $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<bool> verifyEmail({
    required String email,
    required String otp,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.verifyEmail(email: email, otp: otp);
      await SecureStorage.saveAccessToken(result.$1.accessToken);
      await SecureStorage.saveRefreshToken(result.$1.refreshToken);
      await HiveStorage.saveUserProfile(result.$2.toJson());
      state = AsyncValue.data(result.$2);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<bool> sendVerification(String email) async {
    try {
      await _repository.sendVerification(email);
      return true;
    } catch (e) {
      AppToast.showError(FailureMapper.map(e).message);
      return false;
    }
  }

  Future<bool> sendForgetPasswordOtp(String email) async {
    try {
      await _repository.sendForgetPasswordOtp(email);
      return true;
    } catch (e) {
      AppToast.showError(FailureMapper.map(e).message);
      return false;
    }
  }

  Future<bool> updatePassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _repository.updatePassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      AppToast.showError(FailureMapper.map(e).message);
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      AppToast.showError(FailureMapper.map(e).message);
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = const AsyncValue.loading();
    debugPrint('[AUTH][Google] Starting Google Sign-In flow…');
    try {
      final result = await _repository.loginWithGoogle();
      debugPrint('[AUTH][Google] ✅ Google Sign-In success — user: ${result.$2.toJson()}');
      await SecureStorage.saveAccessToken(result.$1.accessToken);
      await SecureStorage.saveRefreshToken(result.$1.refreshToken);
      await HiveStorage.saveUserProfile(result.$2.toJson());
      state = AsyncValue.data(result.$2);
      return true;
    } catch (e) {
      debugPrint('[AUTH][Google] ❌ Google Sign-In failed — $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    try { await _repository.logout(); } catch (_) {}
    await _googleSignIn.signOut();
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
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    debugPrint('[REPO][SignUp] POST ${ApiEndpoints.register} → name=$name email=$email');
    try {
      final response = await _client.post(ApiEndpoints.register, data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });
      debugPrint('[REPO][SignUp] ✅ HTTP ${response.statusCode} — ${response.data}');
    } on DioException catch (e) {
      debugPrint('[REPO][SignUp] ❌ HTTP ${e.response?.statusCode} — ${e.response?.data}');
      throw ApiException.fromResponse(
        e.response?.data as Map<String, dynamic>? ?? {},
        e.response?.statusCode,
      );
    }
  }

  /// Send verification email OTP
  Future<void> sendVerification(String email) async {
    try {
      await _client.post(ApiEndpoints.sendVerification, data: {'email': email});
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data as Map<String, dynamic>? ?? {},
        e.response?.statusCode,
      );
    }
  }

  /// Verify email via OTP
  Future<(AuthTokens, User)> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _client.post(ApiEndpoints.verification, data: {
        'email': email,
        'otp': otp,
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
  Future<void> sendForgetPasswordOtp(String email) async {
    try {
      await _client.post(ApiEndpoints.sendForgetPasswordOtp, data: {'email': email});
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data as Map<String, dynamic>? ?? {},
        e.response?.statusCode,
      );
    }
  }

  /// Reset/update password using OTP
  Future<void> updatePassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _client.post(ApiEndpoints.updatePassword, data: {
        'email': email,
        'otp': otp,
        'password': newPassword,
        'password_confirmation': newPassword,
      });
    } on DioException catch (e) {
      throw ApiException.fromResponse(
        e.response?.data as Map<String, dynamic>? ?? {},
        e.response?.statusCode,
      );
    }
  }

  /// Change password using existing password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _client.post(ApiEndpoints.changePassword, data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      });
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

  /// Google Sign-In — mobile flow
  Future<(AuthTokens, User)> loginWithGoogle() async {
    debugPrint('[REPO][Google] Step 1 — opening native Google account picker…');
    final googleAccount = await _googleSignIn.signIn();
    if (googleAccount == null) {
      debugPrint('[REPO][Google] ⚠️  User cancelled the Google account picker.');
      throw const ApiException(message: 'Google sign-in was cancelled.', statusCode: 0);
    }
    debugPrint('[REPO][Google] ✅ Step 1 — account selected: ${googleAccount.email} (id: ${googleAccount.id})');

    debugPrint('[REPO][Google] Step 2 — fetching Google auth tokens…');
    final googleAuth = await googleAccount.authentication;
    final accessToken = googleAuth.accessToken;
    if (accessToken == null) {
      debugPrint('[REPO][Google] ❌ Step 2 — accessToken is null');
      throw const ApiException(message: 'Failed to obtain Google access token.', statusCode: 0);
    }
    debugPrint('[REPO][Google] ✅ Step 2 — accessToken obtained');

    debugPrint('[REPO][Google] Step 3 — POST ${ApiEndpoints.googleToken}');
    try {
      final response = await _client.post(
        ApiEndpoints.googleToken,
        data: {'access_token': accessToken},
      );
      debugPrint('[REPO][Google] ✅ Step 3 — HTTP ${response.statusCode}');
      final data = response.data['data'] as Map<String, dynamic>;
      final tokens = AuthTokens.fromJson(data['token'] as Map<String, dynamic>);
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      return (tokens, user);
    } on DioException catch (e) {
      debugPrint('[REPO][Google] ❌ Step 3 — HTTP ${e.response?.statusCode}');
      throw ApiException.fromResponse(
        e.response?.data as Map<String, dynamic>? ?? {},
        e.response?.statusCode,
      );
    }
  }
}
