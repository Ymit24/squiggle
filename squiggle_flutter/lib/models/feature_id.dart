/// Identifier for a document feature.
class FeatureId {
  const FeatureId(this.value);

  final int value;

  factory FeatureId.newId(int id) => FeatureId(id);

  FeatureId next() => FeatureId(value + 1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeatureId && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'FeatureId($value)';
}

const FeatureId noId = FeatureId(0);
