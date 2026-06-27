// ignore_for_file: always_specify_types, directives_ordering
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/storage/hive_storage.dart';
import 'core/services/feedback_service.dart';
import 'core/services/app_toast.dart';

/// Shows a native Android/iOS toast via platform channel.
/// Works BEFORE the Flutter widget tree exists — fires even on a black screen.
void _nativeToast(String msg) {
  debugPrint('[STARTUP] $msg');
  Fluttertoast.showToast(
    msg: msg,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: const Color(0xFF212121),
    textColor: Colors.white,
    fontSize: 13.0,
  );
}

Future<void> main() async {
  // ── Step 1: Bind Flutter to native layer ──────
  WidgetsFlutterBinding.ensureInitialized();
  _nativeToast('⏳ [1/3] App starting…');

  // ── Step 2: Global Flutter error handler ─────
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    debugPrint('[FLUTTER_ERROR] $msg');
    _nativeToast('❌ Flutter error: $msg');
    FlutterError.presentError(details);
  };

  // ── Step 3: Initialize Hive local storage ────
  // Hive.initFlutter() can block indefinitely on corrupted/locked storage.
  // Timeout after 5s so we always reach runApp() and show the freeze in a toast.
  try {
    _nativeToast('⏳ [2/3] Loading storage…');
    await HiveStorage.init().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _nativeToast('⚠️ Storage timed out — continuing without cache');
        debugPrint('[STARTUP] ❌ HiveStorage.init() timed out after 5s');
      },
    );
    _nativeToast('✅ [2/3] Storage ready');
  } catch (e) {
    _nativeToast('⚠️ Storage error (non-fatal): $e');
    debugPrint('[STARTUP] ❌ Hive init failed: $e');
  }

  // ── Step 4: Pre-load audio assets (non-blocking) ──
  FeedbackService.init().catchError((Object e) {
    debugPrint('[STARTUP] ⚠️ FeedbackService init failed (non-fatal): $e');
  });

  // ── Step 5: Run App ───────────────────────────
  _nativeToast('⏳ [3/3] Launching…');
  debugPrint('[STARTUP] Calling runApp…');
  runApp(
    const ProviderScope(
      child: QuizloApp(),
    ),
  );
}

class QuizloApp extends ConsumerWidget {
  const QuizloApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Quizlo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      // Wire global toast key so AppToast.show() works without a BuildContext
      scaffoldMessengerKey: AppToast.messengerKey,
    );
  }
}
