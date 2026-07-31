import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';

class FeedbackService {
  static final AudioPlayer _correctPlayer = AudioPlayer();
  static final AudioPlayer _wrongPlayer = AudioPlayer();
  static final AudioPlayer _completePlayer = AudioPlayer();
  static final Random _random = Random();
  static bool _initialized = false;
  // Cached at init so playWrong() doesn't wait on a platform-channel round
  // trip before it can vibrate.
  static bool _hasVibrator = false;
  // Tracks an in-flight init() call so concurrent callers await the same
  // Future instead of racing to setAsset() the same players in parallel.
  static Future<void>? _initFuture;

  static const List<String> _correctAssets = <String>[
    'assets/audio/correct_1.wav',
    'assets/audio/correct_2.wav',
    'assets/audio/correct_3.wav',
    'assets/audio/correct_4.wav',
    'assets/audio/correct_5.wav',
    'assets/audio/correct_6.wav',
    'assets/audio/correct_7.wav',
  ];

  static const List<String> _wrongAssets = <String>[
    'assets/audio/wrong_1.wav',
    'assets/audio/wrong_2.wav',
    'assets/audio/wrong_3.wav',
  ];

  static const List<String> _lessonCompleteAssets = <String>[
    'assets/audio/lession_complete_1.wav',
    'assets/audio/lession_complete_2.wav',
    'assets/audio/lession_complete_3.wav',
    'assets/audio/lesson_complete_4.wav',
  ];

  static String _randomOf(List<String> assets) =>
      assets[_random.nextInt(assets.length)];

  /// Pre-loads a sound for each category to ensure low latency on first playback.
  static Future<void> init() {
    if (_initialized) return Future.value();
    return _initFuture ??= _doInit().whenComplete(() => _initFuture = null);
  }

  static Future<void> _doInit() async {
    try {
      // Pre-load one asset per category so the players are warm.
      await _correctPlayer.setAsset(_randomOf(_correctAssets));
      await _wrongPlayer.setAsset(_randomOf(_wrongAssets));
      await _completePlayer.setAsset(_randomOf(_lessonCompleteAssets));

      await _correctPlayer.setLoopMode(LoopMode.off);
      await _wrongPlayer.setLoopMode(LoopMode.off);
      await _completePlayer.setLoopMode(LoopMode.off);

      _hasVibrator = await Vibration.hasVibrator() ?? false;

      _initialized = true;
    } catch (e) {
      debugPrint('[FeedbackService] init failed: $e');
    }
  }

  /// Play a randomly chosen success sound for a correct answer.
  static Future<void> playCorrect() async {
    try {
      await init();
      await _correctPlayer.setAsset(_randomOf(_correctAssets));
      await _correctPlayer.play();
    } catch (e) {
      debugPrint('[FeedbackService] playCorrect failed: $e');
    }
  }

  /// Vibrate the device for 0.7 seconds (700 milliseconds) and play a
  /// randomly chosen wrong sound. Vibration fires first and doesn't wait on
  /// audio loading/playback so the haptic hit lands right on tap.
  static Future<void> playWrong() async {
    try {
      await init();

      if (_hasVibrator) {
        Vibration.vibrate(duration: 700);
      }

      await _wrongPlayer.setAsset(_randomOf(_wrongAssets));
      // just_audio's play() future only resolves once the clip finishes, so
      // it's left unawaited to avoid holding this call open pointlessly.
      unawaited(_wrongPlayer.play());
    } catch (e) {
      debugPrint('[FeedbackService] playWrong failed: $e');
    }
  }

  /// Play a randomly chosen lesson complete sound.
  static Future<void> playLessonComplete() async {
    try {
      await init();
      await _completePlayer.setAsset(_randomOf(_lessonCompleteAssets));
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
