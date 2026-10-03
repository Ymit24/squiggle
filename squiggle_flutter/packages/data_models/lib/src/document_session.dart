import 'package:data_models/src/brush_profile.dart';

/// Persisted editor preferences, independent of document content and undo.
class DocumentSession {
  const DocumentSession({
    this.brushes = const [],
    this.activeBrushId = 'scratch',
  });

  factory DocumentSession.fromJson(Map<String, dynamic> json) =>
      DocumentSession(
        brushes: [
          for (final brush in json['brushes'] as List<dynamic>? ?? [])
            BrushProfile.fromJson(brush as Map<String, dynamic>),
        ],
        activeBrushId: json['activeBrushId'] as String? ?? 'scratch',
      );

  final List<BrushProfile> brushes;
  final String activeBrushId;

  Map<String, dynamic> toJson() => {
    'activeBrushId': activeBrushId,
    'brushes': brushes.map((brush) => brush.toJson()).toList(),
  };
}
