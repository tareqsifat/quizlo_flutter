import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';

class FeedbackService {
  static final AudioPlayer _correctPlayer = AudioPlayer();
  static final AudioPlayer _wrongPlayer = AudioPlayer();
  static final AudioPlayer _completePlayer = AudioPlayer();
  static bool _initialized = false;
  // Tracks an in-flight init() call so concurrent callers await the same
  // Future instead of racing to setAsset() the same players in parallel.
  static Future<void>? _initFuture;

  /// Pre-loads correct and wrong sound files to ensure low latency playback.
  static Future<void> init() {
    if (_initialized) return Future.value();
    return _initFuture ??= _doInit().whenComplete(() => _initFuture = null);
  }

  static Future<void> _doInit() async {
    try {
      // Pre-load assets
      await _correctPlayer.setAsset('assets/audio/correct.mp3');
      await _wrongPlayer.setAsset('assets/audio/wrong.wav');
      await _completePlayer.setAsset('assets/audio/lesson_complete.wav');

      await _correctPlayer.setLoopMode(LoopMode.off);
      await _wrongPlayer.setLoopMode(LoopMode.off);
      await _completePlayer.setLoopMode(LoopMode.off);

      _initialized = true;
    } catch (e) {
      debugPrint('[FeedbackService] init failed: $e');
    }
  }

  /// Play the success sound for a correct answer.
  static Future<void> playCorrect() async {
    try {
      await init();
      await _correctPlayer.seek(Duration.zero);
      await _correctPlayer.play();
    } catch (e) {
      debugPrint('[FeedbackService] playCorrect failed: $e');
    }
  }

  /// Play the wrong sound and vibrate the device for 0.7 seconds (700 milliseconds).
  static Future<void> playWrong() async {
    try {
      await init();
      await _wrongPlayer.seek(Duration.zero);
      await _wrongPlayer.play();

      // Trigger vibration for 0.7 seconds
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 700);
      }
    } catch (e) {
      debugPrint('[FeedbackService] playWrong failed: $e');
    }
  }

  /// Play the lesson complete sound.
  static Future<void> playLessonComplete() async {
    try {
      await init();
      await _completePlayer.seek(Duration.zero);
      await _completePlayer.play();
    } catch (e) {
      debugPrint('[FeedbackService] playLessonComplete failed: $e');
    }
  }

  /// Cleanup audio players on app shutdown.
  static void dispose() {
    _correctPlayer.dispose();
    _wrongPlayer.dispose();
    _completePlayer.dispose();
    _initialized = false;
    _initFuture = null;
  }
}
