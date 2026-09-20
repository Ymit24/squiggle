import 'package:flutter/material.dart';

export 'inspector_color_capability.dart';
export 'inspector_end_cap_capability.dart';
export 'inspector_numeric_capability.dart';
export 'inspector_text_alignment_capability.dart';

abstract class InspectorCapability<T> {
  InspectorCapability({
    required this.fieldKey,
    required this.label,
    required this.values,
    required this.callbacks,
  });
  String fieldKey;
  String label;
  List<T> values;
  List<Function(T)> callbacks;
  T get activeValue => values.first;
  bool get isMixed => values.toSet().length > 1;
  void merge(InspectorCapability<T> other) {
    values.addAll(other.values);
    callbacks.addAll(other.callbacks);
  }

  InspectorCapabilityFieldShell build(
    BuildContext context,
    void Function(T) onUpdate,
  );
  void apply(T value) {
    for (final callback in callbacks) {
      callback(value);
    }
  }
}

class InspectorCapabilityFieldShell extends StatelessWidget {
  const InspectorCapabilityFieldShell({
    super.key,
    required this.child,
    required this.label,
  });
  final Widget child;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [Text(label), child],
  );
}
