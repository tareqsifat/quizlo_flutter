// ignore_for_file: always_specify_types, directives_ordering
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/storage/hive_storage.dart';
import 'core/services/feedback_service.dart';
import 'core/services/app_toast.dart';

Future<void> main() async {
  // ── Step 1: Bind Flutter to native layer ──────
  WidgetsFlutterBinding.ensureInitialized();

  // ── Step 2: Global Flutter error handler ─────
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('[FLUTTER_ERROR] ${details.exceptionAsString()}');
    FlutterError.presentError(details);
  };

  // ── Step 3: Initialize Hive local storage ────
  try {
    debugPrint('[STARTUP] Initializing Hive storage…');
    await HiveStorage.init();
    debugPrint('[STARTUP] ✅ Hive storage ready.');
  } catch (e, st) {
    debugPrint('[STARTUP] ❌ Hive init failed: $e\n$st');
    // Non-fatal — app can still run without persistent cache
  }

  // ── Step 4: Pre-load audio assets (non-blocking) ──
  FeedbackService.init().catchError((Object e) {
    debugPrint('[STARTUP] ⚠️  FeedbackService init failed (non-fatal): $e');
  });

  // ── Step 5: Run App ───────────────────────────
  debugPrint('[STARTUP] Launching QuizloApp…');
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
