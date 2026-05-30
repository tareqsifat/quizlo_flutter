import 'package:equatable/equatable.dart';

/// ─────────────────────────────────────────────
/// Error / Failure Hierarchy (Clean Architecture)
/// ─────────────────────────────────────────────

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Network connectivity failure
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection.'});
}

/// API returned an error response
class ApiFailure extends Failure {
  final Map<String, List<String>>? fieldErrors;

  const ApiFailure({
    required super.message,
    super.statusCode,
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, statusCode, fieldErrors];
}

/// Client-side validation failure
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

/// Authentication / token failure
class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Session expired. Please sign in again.'});
}

/// Cache / local storage failure
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Local data error.'});
}

/// Unknown / unexpected failure
class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'Something went wrong. Please try again.'});
}

/// ─────────────────────────────────────────────
/// API Exception — thrown by data sources
/// ─────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? fieldErrors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors,
  });

  factory ApiException.fromResponse(Map<String, dynamic> json, int? statusCode) {
    final message = json['message'] as String? ?? 'An error occurred.';
    Map<String, List<String>>? fieldErrors;

    if (json['errors'] is Map) {
      fieldErrors = (json['errors'] as Map).map(
        (key, value) => MapEntry(
          key.toString(),
          (value as List).map((e) => e.toString()).toList(),
        ),
      );
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      fieldErrors: fieldErrors,
    );
  }

  ApiFailure toFailure() => ApiFailure(
    message: message,
    statusCode: statusCode,
    fieldErrors: fieldErrors,
  );

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// ─────────────────────────────────────────────
/// Failure Mapper — converts exceptions to Failures
/// ─────────────────────────────────────────────
class FailureMapper {
  static Failure map(Object error) {
    if (error is ApiException) return error.toFailure();
    if (error is NetworkException) return NetworkFailure(message: error.message);
    return const UnknownFailure();
  }
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({this.message = 'Connection failed.'});
}
