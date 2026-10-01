/// Persisted editor preferences, independent of document content and undo.
class DocumentSession {
  const DocumentSession({
    this.brushes = const [],
    this.activeBrushId = 'scratch',
  });

  final List<BrushProfile> brushes;
  final String activeBrushId;

  factory DocumentSession.fromJson(Map<String, dynamic> json) =>
      DocumentSession(
        brushes: [
          for (final brush in json['brushes'] as List<dynamic>? ?? [])
            BrushProfile.fromJson(brush as Map<String, dynamic>),
        ],
        activeBrushId: json['activeBrushId'] as String? ?? 'scratch',
      );

  Map<String, dynamic> toJson() => {
    'activeBrushId': activeBrushId,
    'brushes': brushes.map((brush) => brush.toJson()).toList(),
  };
}

class BrushProfile {
  const BrushProfile({
    required this.id,
    required this.name,
    this.values = const {},
  });

  final String id;
  final String name;
  final Map<String, dynamic> values;

  factory BrushProfile.fromJson(Map<String, dynamic> json) => BrushProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    values: Map<String, dynamic>.from(json['values'] as Map? ?? {}),
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'values': values};
}
