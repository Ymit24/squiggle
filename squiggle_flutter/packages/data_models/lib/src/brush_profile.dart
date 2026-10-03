class BrushProfile {
  const BrushProfile({
    required this.id,
    required this.name,
    this.values = const {},
  });

  factory BrushProfile.fromJson(Map<String, dynamic> json) => BrushProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    values: Map<String, dynamic>.from(json['values'] as Map? ?? {}),
  );

  final String id;
  final String name;
  final Map<String, dynamic> values;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'values': values};
}
