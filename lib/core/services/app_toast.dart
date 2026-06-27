import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────
/// AppToast — Global toast helper
/// Works from anywhere via a GlobalKey on the root ScaffoldMessenger.
/// Use AppToast.show() to surface messages during startup / freezes.
/// ─────────────────────────────────────────────
class AppToast {
  AppToast._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Show an info / debug toast from anywhere in the app.
  static void show(
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 5),
  }) {
    Color bg;
    if (isSuccess) {
      bg = const Color(0xFF2E7D32); // green-800
    } else if (isError) {
      bg = const Color(0xFFC62828); // red-800
    } else {
      bg = const Color(0xFF37474F); // blue-grey-800
    }

    messengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isSuccess
                    ? Icons.check_circle_outline
                    : isError
                        ? Icons.error_outline
                        : Icons.info_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: bg,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  static void showInfo(String message) => show(message);
  static void showError(String message) => show(message, isError: true);
  static void showSuccess(String message) => show(message, isSuccess: true);
}
