import 'package:flutter/widgets.dart';

class PointerRecord {
  PointerRecord({
    required this.pointer,
    required this.buttons,
    required this.screenPosition,
    required this.timeStamp,
  });
  final int pointer;
  final int buttons;
  final Offset screenPosition;
  final Duration timeStamp;
}
