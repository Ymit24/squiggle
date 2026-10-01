import 'dart:ui';
import 'package:data_models/data_models.dart' as data;
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/tools/create_feature_tool.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';

void main() {
  test('old documents get Scratch and invalid active IDs recover', () {
    final old = Document.fromDataModel(
      data.Document.decode('{"version":2,"name":"Old","nodes":[]}'),
    );
    expect(old.session.activeBrush.isScratch, isTrue);
    expect(old.session.activeBrush.values, isEmpty);
    final restored = Document.fromDataModel(
      data.Document(
        session: data.DocumentSession(
          activeBrushId: 'missing',
          brushes: [data.BrushProfile(id: 'one', name: 'One')],
        ),
      ),
    );
    expect(restored.session.activeBrush.isScratch, isTrue);
  });

  test(
    'session round trips typed styles, Scratch, active ID and unknown fields',
    () {
      final editor = EditorContext(document: Document());
      addTearDown(editor.dispose);
      editor.setDrawingField('fontSize', 36.0);
      editor.setDrawingField('futureStyle', {'kind': 'shadow'});
      final brush = editor.createBrush('Construction');
      editor.setDrawingField('strokeColor', const Color(0xFFFFAA00));
      editor.setDrawingField('strokeType', StrokeType.dashed);
      editor.setDrawingField('strokeWidth', 3.0);
      editor.setDrawingField('endEndCap', LineEndCap.arrow);
      final restored = Document.fromDataModel(
        data.Document.decode(editor.document.toDataModel().encode()),
      );
      expect(restored.session.activeBrushId, brush.id);
      expect(restored.session.activeBrush.values, brush.values);
      expect(restored.session.scratch.values, {
        'fontSize': 36.0,
        'futureStyle': {'kind': 'shadow'},
      });
      expect(
        restored.toDataModel().session.brushes.last.values['strokeType'],
        'dashed',
      );
    },
  );

  test('named edits are direct, sparse and never enter canvas history', () {
    final editor = EditorContext(document: Document());
    addTearDown(editor.dispose);
    var sessionChanges = 0;
    editor.sessionChanges.addListener(() => sessionChanges++);
    final brush = editor.createBrush('Actual');
    editor.setDrawingField('strokeWidth', 16.0);
    editor.setTool(CreateFeatureTool.rect());
    expect(
      (editor.drawingInspectorKind as FeatureKindRectangle).strokeWidth,
      16,
    );
    editor.setTool(CreateLineTool());
    expect(
      (editor.drawingInspectorKind as FeatureKindPolyline).strokeWidth,
      16,
    );
    editor.clearDrawingField('strokeWidth');
    expect(
      (editor.drawingInspectorKind as FeatureKindPolyline).strokeWidth,
      defaultStrokeWidth,
    );
    expect(editor.activeBrush.id, brush.id);
    expect(brush.values, isEmpty);
    expect(editor.history.canUndo, isFalse);
    expect(sessionChanges, 3);
  });

  test('active deletion preserves drawing style; Scratch is protected', () {
    final editor = EditorContext(document: Document());
    addTearDown(editor.dispose);
    editor.setDrawingField('fillColor', const Color(0xFF112233));
    final brush = editor.createBrush('Actual');
    editor.setDrawingField('strokeWidth', 16.0);
    editor.renameBrush(brush.id, 'Renamed');
    editor.deleteBrush(brush.id);
    expect(editor.activeBrush.isScratch, isTrue);
    expect(editor.activeBrush.values, {
      'fillColor': const Color(0xFF112233),
      'strokeWidth': 16.0,
    });
    editor.deleteBrush(BrushProfile.scratchId);
    editor.renameBrush(BrushProfile.scratchId, 'Other');
    expect(editor.activeBrush.name, 'Scratch');
    expect(editor.document.session.brushes, hasLength(1));
  });

  test('replacing documents restores session without sharing mutable maps', () {
    final first = EditorContext(document: Document());
    addTearDown(first.dispose);
    first.createBrush('Local');
    first.setDrawingField('strokeWidth', 3.0);
    final second = EditorContext(document: Document());
    addTearDown(second.dispose);
    second.loadDocument(first.document);
    second.setDrawingField('strokeWidth', 16.0);
    expect(first.activeBrush.values['strokeWidth'], 3.0);
    expect(second.activeBrush.name, 'Local');
  });
}
