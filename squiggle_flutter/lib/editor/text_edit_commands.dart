import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/feature_kinds/feature_kind.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';

/// Applies [contents] (default: the field's current draft) as one undoable
/// step and closes the text edit; does nothing when no edit is open.
///
/// Synchronous on purpose: callers commit right before something else acts on
/// the document, such as a tool starting a drag. Set [selectCreated] to false
/// when the commit comes from a click that picks the selection itself.
void commitTextEdit(
  EditorContext context, {
  String? contents,
  bool selectCreated = true,
}) {
  final session = context.textEdit.session;
  if (session == null) return;
  final text = contents ?? context.textEdit.draft;

  switch (session) {
    case EditTextEditSession(:final feature):
      if (feature.kind is LabelCapable) {
        final label = feature.kind as LabelCapable;
        context.history.run('Edit text', (transaction) {
          transaction.watch([feature]);
          label.setLabel(feature, text);
        }, container: feature.parent);
      }
    case CreateTextEditSession(:final worldOrigin):
      if (text.isNotEmpty) {
        final feature = newTextFeatureAt(
          worldOrigin,
          text,
          configureKind: context.brushes.active.applyTo,
        );
        context.history.run('Create text', (transaction) {
          transaction.add(feature);
        });
        if (selectCreated) context.selectCreatedFeature(feature);
      }
  }
  context.endTextEdit();
}
