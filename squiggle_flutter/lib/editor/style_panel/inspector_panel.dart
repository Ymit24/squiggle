import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_capability.dart';

Iterable<InspectorCapabilityFieldShell> buildInspectorPanel(
  BuildContext context,
  EditorContext editorContext,
  List<Feature> features,
) {
  final callbacksByFieldKey = <String, InspectorCapability>{};
  for (final capability in features.expand(
    (feature) => feature.kind.buildInspectorCapabilities(),
  )) {
    final fieldKey = capability.fieldKey;
    if (callbacksByFieldKey.containsKey(fieldKey)) {
      callbacksByFieldKey[fieldKey]!.merge(capability);
    } else {
      callbacksByFieldKey[fieldKey] = capability;
    }
  }
  return callbacksByFieldKey.values.map(
    (capability) => capability.build(context, (result) {
      editorContext.history.run('Inspector Update', (transaction) {
        transaction.watch(features);
        capability.apply(result);
      });
    }),
  );
}
