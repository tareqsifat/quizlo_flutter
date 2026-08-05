import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';
import '../services/app_toast.dart';

final _logger = Logger();

/// ─────────────────────────────────────────────
/// Dio HTTP Client — Centralized networking
/// Handles JWT injection, token refresh, logging
/// ─────────────────────────────────────────────
class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiEndpoints.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiEndpoints.receiveTimeout),
        sendTimeout: const Duration(milliseconds: ApiEndpoints.sendTimeout),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    _dio.interceptors.addAll([
      _AuthInterceptor(_dio),
      _LogInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  // ── Convenience Methods ────────────────────
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) =>
      _dio.get(path, queryParameters: queryParams);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) =>
      _dio.delete(path);
}

/// ─────────────────────────────────────────────
/// Auth Interceptor
/// Injects Bearer token + handles 401 refresh
/// ─────────────────────────────────────────────
class _AuthInterceptor extends QueuedInterceptorsWrapper {
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for public endpoints
    final publicPaths = [
      ApiEndpoints.sendOtp,
      ApiEndpoints.verifyOtp,
      ApiEndpoints.refreshToken,
      ApiEndpoints.login,
      ApiEndpoints.register,
      ApiEndpoints.examTypes,
    ];
    if (publicPaths.contains(options.path)) {
      return handler.next(options);
    }

    // Skip auth for skip-auth dev mode
    final skipAuth = await SecureStorage.isSkipAuth();
    if (skipAuth) return handler.next(options);

    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await SecureStorage.getRefreshToken();
        if (refreshToken == null) {
          await SecureStorage.clearAll();
          return handler.next(err);
        }

        final refreshDio = Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );
        final response = await refreshDio.post(
          ApiEndpoints.refreshToken,
          data: {
            'grant_type': 'refresh_token',
            'refresh_token': refreshToken,
            'client_id': '2',           // Mobile Passport client
            'client_secret': 'MOBILE_SECRET',
          },
        );

        if (response.statusCode == 200) {
          final data = response.data['data'];
          await SecureStorage.saveAccessToken(data['access_token']);
          await SecureStorage.saveRefreshToken(data['refresh_token']);

          // Retry original request
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer ${data['access_token']}';
          final retryResponse = await _dio.fetch(opts);
          return handler.resolve(retryResponse);
        }
      } catch (_) {
        await SecureStorage.clearAll();
      } finally {
        _isRefreshing = false;
      }
    }
    return handler.next(err);
  }
}

/// ─────────────────────────────────────────────
/// Log Interceptor (debug only)
/// ─────────────────────────────────────────────
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('[API] ${options.method} ${options.path}');
    if (kDebugMode) {
      AppToast.showInfo('📡 ${options.method} /api/v1/${options.path}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('[API] ✓ ${response.statusCode} ${response.requestOptions.path}');
    if (kDebugMode) {
      AppToast.showSuccess(
          '✅ ${response.statusCode} /api/v1/${response.requestOptions.path}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('[API] ✗ ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}');
    if (kDebugMode) {
      AppToast.showError(
          '❌ ${err.response?.statusCode} /api/v1/${err.requestOptions.path}: ${err.message}');
    }
    handler.next(err);
  }
}
