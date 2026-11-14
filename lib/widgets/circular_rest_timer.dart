import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:greyskull_lp/models/training_state.dart';
import 'package:greyskull_lp/services/timer_cue_service.dart';
import 'package:greyskull_lp/services/workout_notification_service.dart';
import 'package:greyskull_lp/themes/gs_tokens.dart';

/// Circular arc rest timer (parity with the old app's round countdown).
///
/// Clean-room: custom painter + platform sounds/haptics, no third-party assets.
class CircularRestTimer extends StatefulWidget {
  const CircularRestTimer({
    super.key,
    required this.seconds,
    required this.soundEnabled,
    this.countUp = true,
    this.size = 2,
    this.coachingText,
    this.onDismissed,
  });

  final int seconds;
  final bool soundEnabled;
  final bool countUp;

  /// 1 = small, 2 = medium, 3 = large.
  final int size;
  final String? coachingText;
  final VoidCallback? onDismissed;

  @override
  State<CircularRestTimer> createState() => _CircularRestTimerState();
}

class _CircularRestTimerState extends State<CircularRestTimer> {
  Timer? _ticker;
  late int _elapsed;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _elapsed = 0;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _elapsed += 1;
      if (_elapsed >= widget.seconds) {
        _elapsed = widget.seconds;
        _finished = true;
        _ticker?.cancel();
      }
    });
    if (_finished) {
      _fireEndCue();
    } else if (widget.seconds - _elapsed <= 3) {
      _fireTickCue();
    }
  }

  void _fireEndCue() {
    // The notification is independent of the audible cue.
    if (trainingState.workoutNotifications) {
      WorkoutNotificationService.instance.showRestComplete();
    }
    if (!widget.soundEnabled) return;
    // Original generated tone + haptic (no third-party audio).
    TimerCueService.instance.restFinished();
    HapticFeedback.heavyImpact();
  }

  void _fireTickCue() {
    if (!widget.soundEnabled) return;
    TimerCueService.instance.countdownTickCue();
    HapticFeedback.selectionClick();
  }

  int get _displaySeconds =>
      widget.countUp ? _elapsed : (widget.seconds - _elapsed).clamp(0, 9999);

  String get _label {
    final value = _displaySeconds;
    return '${value ~/ 60}:${(value % 60).toString().padLeft(2, '0')}';
  }

  double get _progress =>
      widget.seconds == 0 ? 0 : (_elapsed / widget.seconds).clamp(0.0, 1.0);

  double get _diameter => switch (widget.size) {
        1 => 54,
        3 => 90,
        _ => 68,
      };

  void _adjust(int delta) {
    setState(() {
      _elapsed = (_elapsed - delta).clamp(0, widget.seconds);
      _finished = _elapsed >= widget.seconds;
    });
  }

  void _skip() {
    _ticker?.cancel();
    widget.onDismissed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.gs;
    final accent = _finished ? tokens.ok : tokens.accent;

    return Row(
      children: <Widget>[
        SizedBox(
          width: _diameter,
          height: _diameter,
          child: CustomPaint(
            painter: _ArcPainter(
              progress: _progress,
              color: accent,
              trackColor: tokens.surface2,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    _label,
                    style: TextStyle(
                      fontFamily: GsFont.mono,
                      fontSize: _diameter * 0.21,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _finished
                        ? 'NEXT SET'
                        : widget.countUp
                            ? 'ELAPSED'
                            : 'REMAINING',
                    style: TextStyle(
                      fontFamily: GsFont.body,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _finished ? 'Rest complete' : 'Rest',
                style: TextStyle(
                  fontFamily: GsFont.body,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: accent,
                ),
              ),
              if (widget.coachingText != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  widget.coachingText!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: GsFont.body,
                    fontSize: 11,
                    height: 1.35,
                    color: tokens.muted,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Wrap(
                spacing: 2,
                children: <Widget>[
                  TextButton(
                    onPressed: () => _adjust(-15),
                    style: _compactButtonStyle(tokens),
                    child: const Text('-15 s'),
                  ),
                  TextButton(
                    onPressed: () => _adjust(15),
                    style: _compactButtonStyle(tokens),
                    child: const Text('+15 s'),
                  ),
                  TextButton(
                    onPressed: _skip,
                    style: _compactButtonStyle(tokens),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  ButtonStyle _compactButtonStyle(GsTokens tokens) {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minimumSize: const Size(0, 28),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: tokens.accent,
      textStyle: TextStyle(
        fontFamily: GsFont.body,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * 0.08;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    paint.color = trackColor;
    canvas.drawArc(
        rect.deflate(stroke / 2), -math.pi / 2, 2 * math.pi, false, paint);

    paint.color = color;
    canvas.drawArc(
      rect.deflate(stroke / 2),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
