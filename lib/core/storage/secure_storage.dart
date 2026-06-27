import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'hive_storage.dart';


/// ─────────────────────────────────────────────
/// Secure Storage — Wraps flutter_secure_storage
/// For JWT access/refresh tokens
/// ─────────────────────────────────────────────
class SecureStorage {
  // ── Android: use encryptedSharedPreferences with resetOnError
  // resetOnError: true — if the Keystore is corrupt/locked, the storage
  // resets instead of hanging indefinitely (causing black screen).
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true, // ← CRITICAL: prevents black screen on Keystore failure
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Keys ───────────────────────────────────
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyIsSkipAuth = 'is_skip_auth';

  // ── Access Token ───────────────────────────
  static Future<void> saveAccessToken(String token) =>
      _storage.write(key: _keyAccessToken, value: token);

  static Future<String?> getAccessToken() =>
      _storage.read(key: _keyAccessToken);

  static Future<void> deleteAccessToken() =>
      _storage.delete(key: _keyAccessToken);

  // ── Refresh Token ──────────────────────────
  static Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _keyRefreshToken, value: token);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _keyRefreshToken);

  static Future<void> deleteRefreshToken() =>
      _storage.delete(key: _keyRefreshToken);

  // ── User ID ────────────────────────────────
  static Future<void> saveUserId(int userId) =>
      _storage.write(key: _keyUserId, value: userId.toString());

  static Future<int?> getUserId() async {
    final val = await _storage.read(key: _keyUserId);
    return val != null ? int.tryParse(val) : null;
  }

  // ── Skip Auth (DEV ONLY) ───────────────────
  /// When true, app simulates authenticated state without real tokens.
  /// Remove the skip-auth button to remove this path in production.
  static Future<void> setSkipAuth(bool skip) =>
      _storage.write(key: _keyIsSkipAuth, value: skip.toString());

  static Future<bool> isSkipAuth() async {
    final val = await _storage.read(key: _keyIsSkipAuth);
    return val == 'true';
  }

  // ── Auth Check ─────────────────────────────
  static Future<bool> isAuthenticated() async {
    try {
      final skipAuth = await isSkipAuth();
      if (skipAuth) return true; // DEV bypass

      // Synchronous Hive bypass for Demo Mode
      if (HiveStorage.isDemoMode()) return true;

      final token = await getAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('[SecureStorage] isAuthenticated error: $e');
      return false; // fail-open: treat as unauthenticated, never freeze
    }
  }

  // ── Clear All ──────────────────────────────
  static Future<void> clearAll() => _storage.deleteAll();
}
