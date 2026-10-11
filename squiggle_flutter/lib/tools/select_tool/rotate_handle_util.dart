import 'dart:ui';

import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/node.dart';

class RotateHandle {
  RotateHandle({required this.node});

  final Node node;
}

class RotateHandleUtil {
  static RotateHandle? hitTest(Node node, Offset worldPoint, Camera camera) {
    final handleOffset = -camera.screenLengthToWorldLength(25);

    final worldRotateHandleCenterPoint =
        rotatePoint(
          node.center(),
          node.origin.translate(node.localBounds().width / 2, handleOffset),
          node.localRotationAngle,
        ) +
        node.center();

    if ((worldPoint - worldRotateHandleCenterPoint).distance < 50) {
      return RotateHandle(node: node);
    }

    return null;
  }
}
