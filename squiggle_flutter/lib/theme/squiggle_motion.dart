import 'package:flutter/foundation.dart';

/// Shared motion durations for UI state changes.
@immutable
class SquiggleMotion {
  const SquiggleMotion({required this.fast, required this.standard});

  final Duration fast;
  final Duration standard;

  static const standardMotion = SquiggleMotion(
    fast: Duration(milliseconds: 150),
    standard: Duration(milliseconds: 160),
  );

  SquiggleMotion copyWith({Duration? fast, Duration? standard}) {
    return SquiggleMotion(
      fast: fast ?? this.fast,
      standard: standard ?? this.standard,
    );
  }

  SquiggleMotion lerp(SquiggleMotion other, double t) {
    Duration lerpDuration(Duration a, Duration b) => Duration(
      microseconds:
          (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
              .round(),
    );

    return SquiggleMotion(
      fast: lerpDuration(fast, other.fast),
      standard: lerpDuration(standard, other.standard),
    );
  }
}
