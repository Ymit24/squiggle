import 'package:flutter/foundation.dart';

/// Layout and timing tokens for toggle switches in Squiggle's UI chrome.
@immutable
class SquiggleSwitchTokens {
  const SquiggleSwitchTokens({
    this.trackWidth = 36,
    this.trackHeight = 20,
    this.thumbInset = 3,
    this.transitionDuration = const Duration(milliseconds: 120),
  });

  final double trackWidth;
  final double trackHeight;
  final double thumbInset;
  final Duration transitionDuration;

  static const standard = SquiggleSwitchTokens();

  double get thumbSize => trackHeight - thumbInset * 2;
}
