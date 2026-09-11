/// Metadata for a persisted document file.
class DocumentInfo {
  const DocumentInfo({
    required this.id,
    required this.name,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final DateTime updatedAt;

  DocumentInfo copyWith({String? id, String? name, DateTime? updatedAt}) {
    return DocumentInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
