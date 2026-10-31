/// Tracks progress writes (answer submissions, topic/lesson completion) that
/// run in the background after a quiz, so the result screen can open right
/// away while screens that show progress still read fresh numbers: they await
/// [settled] before refetching.
class ProgressSync {
  ProgressSync._();

  static Future<void> _pending = Future.value();

  /// Adds [write] to the pending set. Failures are swallowed here; callers
  /// log their own errors.
  static void track(Future<void> write) {
    final previous = _pending;
    _pending = Future.wait([previous, write.catchError((_) {})]);
  }

  /// Completes once every tracked write has finished, or after [timeout] so a
  /// hung request never blocks a screen from loading.
  static Future<void> settled({Duration timeout = const Duration(seconds: 10)}) {
    return _pending.timeout(timeout, onTimeout: () {});
  }
}
