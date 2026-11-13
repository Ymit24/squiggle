import 'package:flutter/foundation.dart';

/// A typed, app-wide setting stored as a string under [key].
///
/// Features declare their preferences next to the code that reads them and
/// access values through `Preferences`.
@immutable
abstract class Preference<T> {
  const Preference(this.key, this.defaultValue);

  final String key;
  final T defaultValue;

  String encode(T value);

  /// The stored value, or null when [raw] is not one this preference writes.
  T? decode(String raw);
}

class BoolPreference extends Preference<bool> {
  const BoolPreference(super.key, super.defaultValue);

  @override
  String encode(bool value) => '$value';

  @override
  bool? decode(String raw) => bool.tryParse(raw);
}

/// Stores an enum by name, so reordering [values] keeps saved choices.
class EnumPreference<E extends Enum> extends Preference<E> {
  const EnumPreference(super.key, super.defaultValue, this.values);

  final List<E> values;

  @override
  String encode(E value) => value.name;

  @override
  E? decode(String raw) => values.asNameMap()[raw];
}
