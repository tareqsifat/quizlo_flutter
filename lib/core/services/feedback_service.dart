import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';

class FeedbackService {
  static final AudioPlayer _correctPlayer = AudioPlayer();
  static final AudioPlayer _wrongPlayer = AudioPlayer();
  static bool _initialized = false;

  /// Pre-loads correct and wrong sound files to ensure low latency playback.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      // Pre-load assets
      await _correctPlayer.setAsset('assets/audio/correct.mp3');
      await _wrongPlayer.setAsset('assets/audio/wrong.wav');

      await _correctPlayer.setLoopMode(LoopMode.off);
      await _wrongPlayer.setLoopMode(LoopMode.off);

      _initialized = true;
    } catch (_) {
      // Silent catch or simple log
    }
  }

  /// Play the success sound for a correct answer.
  static Future<void> playCorrect() async {
    try {
      await init();
      await _correctPlayer.seek(Duration.zero);
      await _correctPlayer.play();
    } catch (_) {
      // Ignore audio playback errors
    }
  }

  /// Play the wrong sound and vibrate the device for 0.7 seconds (700 milliseconds).
  static Future<void> playWrong() async {
    try {
      await init();
      // Play audio concurrently
      _wrongPlayer.seek(Duration.zero).then((_) => _wrongPlayer.play());

      // Trigger vibration for 0.7 seconds
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 700);
      }
    } catch (_) {
      // Ignore vibration/audio errors
    }
  }

  /// Cleanup audio players on app shutdown.
  static void dispose() {
    _correctPlayer.dispose();
    _wrongPlayer.dispose();
    _initialized = false;
  }
}
