import 'dart:ui';

/// Shared primitive conversions for feature persistence and inspector fields.
Color decodeStyleColor(Object? raw) {
  if (raw is! int || raw < 0 || raw > 0xFFFFFFFF) {
    throw const FormatException('Expected an ARGB color integer.');
  }
  return Color(raw);
}

double decodeStyleNumber(Object? raw) {
  if (raw is! num || !raw.isFinite) {
    throw const FormatException('Expected a finite number.');
  }
  return raw.toDouble();
}

T decodeStyleEnum<T extends Enum>(Object? raw, List<T> values, {T? fallback}) {
  if (raw is String) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
  }
  if (fallback != null) return fallback;
  throw ArgumentError.value(raw, 'raw', 'Unknown enum value.');
}
