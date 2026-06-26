/// Metadata for a persisted document file.
class DocumentInfo {
  const DocumentInfo({
    required this.id,
    required this.name,
    required this.updatedAt,
    required this.featureCount,
  });

  final String id;
  final String name;
  final DateTime updatedAt;
  final int featureCount;

  DocumentInfo copyWith({
    String? id,
    String? name,
    DateTime? updatedAt,
    int? featureCount,
  }) {
    return DocumentInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      updatedAt: updatedAt ?? this.updatedAt,
      featureCount: featureCount ?? this.featureCount,
    );
  }
}
