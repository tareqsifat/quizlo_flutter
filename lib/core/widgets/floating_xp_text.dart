import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Fire-and-forget "+XP" popup that swoops across the screen along a
/// quadratic Bezier arc, fades out, and removes itself.
///
/// Plug-and-play: call [FloatingXpText.show] from anywhere with a
/// [BuildContext] that sits under a [Navigator]/[Overlay] (any normal
/// in-app context, e.g. inside a button's `onPressed`).
///
/// ```dart
/// FloatingXpText.show(context, xp: 10);
/// ```
class FloatingXpText {
  FloatingXpText._();

  static void show(
    BuildContext context, {
    int xp = 10,
    String? label,
    Color color = AppColors.coinGold,
    Color strokeColor = const Color(0xFF7A4B00),
  }) {
    final overlayState = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FloatingXpAnimation(
        text: label ?? '+$xp XP',
        screenSize: screenSize,
        color: color,
        strokeColor: strokeColor,
        onCompleted: () => entry.remove(),
      ),
    );

    overlayState.insert(entry);
  }
}

class _FloatingXpAnimation extends StatefulWidget {
  const _FloatingXpAnimation({
    required this.text,
    required this.screenSize,
    required this.color,
    required this.strokeColor,
    required this.onCompleted,
  });

  final String text;
  final Size screenSize;
  final Color color;
  final Color strokeColor;
  final VoidCallback onCompleted;

  @override
  State<_FloatingXpAnimation> createState() => _FloatingXpAnimationState();
}

class _FloatingXpAnimationState extends State<_FloatingXpAnimation>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 1000);
  // Last 200ms of a 1000ms animation == last 20% of the timeline.
  static const double _fadeStart = 0.8;
  // Elastic pop-in finishes in the first 150ms.
  static const double _popInEnd = 0.15;
  // Eases travel along the arc with a slight overshoot past the end point
  // before settling — reads as a snap rather than a perfectly smooth glide.
  static const Curve _flightCurve = Curves.easeOutBack;
  // Side-to-side wobble riding perpendicular to the arc, decaying to zero
  // by the end so the path isn't a mathematically perfect curve.
  static const double _wobbleAmplitude = 14.0;
  static const double _wobbleCycles = 2.5;

  late final AnimationController _controller;
  late final Offset _start;
  late final Offset _control;
  late final Offset _end;

  @override
  void initState() {
    super.initState();

    final w = widget.screenSize.width;
    final h = widget.screenSize.height;

    // Enters 30% above the bottom-left corner, exits 30% below the
    // top-right corner (measured as a fraction of screen height).
    _start = Offset(0, h * 0.7);
    _end = Offset(w, h * 0.3);

    // Bow the control point away from the straight diagonal so the
    // path swoops instead of running in a straight line.
    final mid = Offset.lerp(_start, _end, 0.5)!;
    final delta = _end - _start;
    final normal = Offset(-delta.dy, delta.dx) / delta.distance;
    _control = mid + normal * (h * 0.32);

    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onCompleted();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Quadratic Bezier: B(t) = (1-t)^2 P0 + 2(1-t)t P1 + t^2 P2
  /// `t` isn't clamped to [0, 1] here — [_flightCurve] briefly overshoots
  /// past 1.0, and the Bezier formula extrapolates smoothly past `_end` in
  /// that case, giving the little overshoot-then-settle "snap".
  Offset _bezierPoint(double t) {
    final oneMinusT = 1 - t;
    final a = oneMinusT * oneMinusT;
    final b = 2 * oneMinusT * t;
    final c = t * t;
    return Offset(
      a * _start.dx + b * _control.dx + c * _end.dx,
      a * _start.dy + b * _control.dy + c * _end.dy,
    );
  }

  /// Small decaying wobble perpendicular to the straight start→end line, so
  /// the flight isn't a perfectly smooth arc.
  Offset _wobbleOffset(double t) {
    final delta = _end - _start;
    final normal = Offset(-delta.dy, delta.dx) / delta.distance;
    final decay = (1 - t).clamp(0.0, 1.0);
    final wiggle = math.sin(t * _wobbleCycles * 2 * math.pi) * _wobbleAmplitude * decay;
    return normal * wiggle;
  }

  @override
  Widget build(BuildContext context) {
    // Positioned must be the direct child of the Overlay's Stack, so
    // IgnorePointer/Opacity/Transform are nested *inside* it rather
    // than wrapping it — wrapping it would silently stop the offsets
    // from having any effect.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final curvedT = _flightCurve.transform(t);
        final position = _bezierPoint(curvedT) + _wobbleOffset(t);

        final opacity = t <= _fadeStart
            ? 1.0
            : (1.0 - (t - _fadeStart) / (1 - _fadeStart)).clamp(0.0, 1.0);

        final popScale = t >= _popInEnd
            ? 1.0
            : Curves.elasticOut.transform(t / _popInEnd).clamp(0.0, 1.3);

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: popScale,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: _XpLabel(
        text: widget.text,
        color: widget.color,
        strokeColor: widget.strokeColor,
      ),
    );
  }
}

class _XpLabel extends StatelessWidget {
  const _XpLabel({
    required this.text,
    required this.color,
    required this.strokeColor,
  });

  final String text;
  final Color color;
  final Color strokeColor;

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.fredoka(fontSize: 40, fontWeight: FontWeight.w600, height: 1);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Thick outline pass, drawn behind the fill so the text pops
        // against any background.
        Text(
          text,
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..color = strokeColor,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.25),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        // Fill pass on top.
        Text(text, style: baseStyle.copyWith(color: color)),
      ],
    );
  }
}
