import 'package:flutter/widgets.dart';

import '../models/camera.dart';

/// Exposes the current viewport camera for actions such as image paste placement.
class ViewportRepository {
  Camera? camera;
  Size viewportSize = Size.zero;

  Offset? worldCenterAtViewportCenter() {
    final currentCamera = camera;
    if (currentCamera == null || viewportSize == Size.zero) {
      return null;
    }
    return currentCamera.screenToWorld(viewportSize.center(Offset.zero));
  }
}
