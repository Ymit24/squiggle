import 'dart:ui';

import 'json_helpers.dart';

sealed class FeatureKind {
  const FeatureKind({
    required this.strokeColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;

  Map<String, dynamic> toJson() => {
    'type': type,
    'strokeColor': strokeColor.toARGB32(),
    'fillColor': fillColor.toARGB32(),
    'strokeWidth': strokeWidth,
  };

  String get type;

  factory FeatureKind.fromJson(Map<String, dynamic> json) {
    final style = (
      strokeColor: colorFromJson(json['strokeColor']),
      fillColor: colorFromJson(json['fillColor']),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
    );
    return switch (json['type']) {
      'rectangle' => RectangleKind._fromStyle(style),
      'circle' => CircleKind._fromStyle(style),
      'text' => TextKind(
        json['contents'] as String,
        fontSize: (json['fontSize'] as num).toDouble(),
        horizontalAlignment: json['horizontalAlignment'] as String,
        verticalAlignment: json['verticalAlignment'] as String,
        strokeColor: style.strokeColor,
        fillColor: style.fillColor,
        strokeWidth: style.strokeWidth,
      ),
      'polyline' => PolylineKind(
        [
          for (final point in json['localPoints'] as List<dynamic>)
            offsetFromJson(point as Map<String, dynamic>),
        ],
        strokeColor: style.strokeColor,
        fillColor: style.fillColor,
        strokeWidth: style.strokeWidth,
      ),
      'image' => ImageKind(
        json['imageId'] as String,
        strokeColor: style.strokeColor,
        fillColor: style.fillColor,
        strokeWidth: style.strokeWidth,
      ),
      _ => throw FormatException('Unknown feature kind: ${json['type']}'),
    };
  }
}

typedef _Style = ({Color strokeColor, Color fillColor, double strokeWidth});

final class RectangleKind extends FeatureKind {
  const RectangleKind({
    required super.strokeColor,
    required super.fillColor,
    required super.strokeWidth,
  });
  RectangleKind._fromStyle(_Style style)
    : this(
        strokeColor: style.strokeColor,
        fillColor: style.fillColor,
        strokeWidth: style.strokeWidth,
      );
  @override
  String get type => 'rectangle';
}

final class CircleKind extends FeatureKind {
  const CircleKind({
    required super.strokeColor,
    required super.fillColor,
    required super.strokeWidth,
  });
  CircleKind._fromStyle(_Style style)
    : this(
        strokeColor: style.strokeColor,
        fillColor: style.fillColor,
        strokeWidth: style.strokeWidth,
      );
  @override
  String get type => 'circle';
}

final class TextKind extends FeatureKind {
  const TextKind(
    this.contents, {
    required this.fontSize,
    required this.horizontalAlignment,
    required this.verticalAlignment,
    required super.strokeColor,
    required super.fillColor,
    required super.strokeWidth,
  });
  final String contents;
  final double fontSize;
  final String horizontalAlignment;
  final String verticalAlignment;
  @override
  String get type => 'text';
  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'contents': contents,
    'fontSize': fontSize,
    'horizontalAlignment': horizontalAlignment,
    'verticalAlignment': verticalAlignment,
  };
}

final class PolylineKind extends FeatureKind {
  const PolylineKind(
    this.localPoints, {
    required super.strokeColor,
    required super.fillColor,
    required super.strokeWidth,
  });
  final List<Offset> localPoints;
  @override
  String get type => 'polyline';
  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'localPoints': localPoints.map(offsetToJson).toList(),
  };
}

final class ImageKind extends FeatureKind {
  const ImageKind(
    this.imageId, {
    required super.strokeColor,
    required super.fillColor,
    required super.strokeWidth,
  });
  final String imageId;
  @override
  String get type => 'image';
  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'imageId': imageId};
}
