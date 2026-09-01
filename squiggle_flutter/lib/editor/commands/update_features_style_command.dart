import 'dart:ui';

import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

import 'command.dart';

/// Updates style fields on the features identified by [ids], snapshotting
/// previous kinds and sizes for undo.
///
/// Only non-null style fields are applied.
final class UpdateFeaturesStyleCommand extends Command {
  UpdateFeaturesStyleCommand({
    required this.ids,
    this.strokeColor,
    this.fillColor,
    this.strokeWidth,
    this.fontSize,
    this.horizontalAlignment,
    this.verticalAlignment,
  });

  final List<FeatureId> ids;
  final Color? strokeColor;
  final Color? fillColor;
  final double? strokeWidth;
  final double? fontSize;
  final TextHorizontalAlignment? horizontalAlignment;
  final TextVerticalAlignment? verticalAlignment;
  Map<FeatureId, FeatureKind>? _previousKinds;
  Map<FeatureId, Size>? _previousSizes;

  @override
  void redo(Document document) {
    _previousKinds ??= {};
    if (fontSize != null) {
      _previousSizes ??= {};
    }
    for (final id in ids) {
      final feature = document.featureById(id);
      if (feature == null) continue;

      _previousKinds!.putIfAbsent(id, () => feature.kind);
      if (fontSize != null && feature.kind is FeatureKindText) {
        _previousSizes!.putIfAbsent(id, () => feature.size);
      }
      final newKind = switch (feature.kind) {
        FeatureKindText() => feature.kind.copyWithStyle(
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
          fontSize: fontSize,
          horizontalAlignment: horizontalAlignment,
          verticalAlignment: verticalAlignment,
        ),
        _ => feature.kind.copyWithStyle(
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
        ),
      };

      if (fontSize != null && newKind is FeatureKindText) {
        final size = newKind.measureContents(
          width: feature.size.width,
          fontSize: newKind.fontSize,
        );
        feature.setKind(newKind, newSize: size);
      } else {
        feature.setKind(newKind);
      }
    }
  }

  @override
  void undo(Document document) {
    final previousKinds = _previousKinds;
    if (previousKinds == null) return;

    for (final entry in previousKinds.entries) {
      final feature = document.featureById(entry.key);
      if (feature == null) continue;
      feature.setKind(entry.value, newSize: _previousSizes?[entry.key]);
    }
  }
}
