// GENERATED CODE — DO NOT MODIFY BY HAND
// ignore_for_file: always_specify_types, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/storage/hive_storage.dart';
import 'core/services/feedback_service.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorage.init();
  FeedbackService.init();
  
  // Don't await — init notifications after app is running
  NotificationService.init().catchError((e) {
    debugPrint('NotificationService init failed: $e');
  });
  
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
    );
  }
}
