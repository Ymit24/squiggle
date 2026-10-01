import 'dart:ui';
import 'package:data_models/data_models.dart' as data;
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/tools/create_feature_tool.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/create_text_tool.dart';
import 'package:squiggle_flutter/tools/drawing_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

void main() {
  test('named profiles use UUIDs and Scratch retains its fixed ID', () {
    final editor = EditorContext(document: Document());
    addTearDown(editor.dispose);
    final first = editor.brushes.create('First');
    final second = editor.brushes.create('Second');
    expect(
      first.id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(second.id, isNot(first.id));
    final restored = Document.fromDataModel(
      data.Document.decode(editor.document.toDataModel().encode()),
    );
    expect(restored.session.activeBrushId, second.id);
    expect(restored.session.scratch.id, 'scratch');
  });

  test(
    'drawing capability supplies fresh defaults without changing tool templates',
    () {
      final editor = EditorContext(document: Document());
      addTearDown(editor.dispose);
      final rectangleTool = CreateFeatureTool.rect();
      editor.brushes.setField('strokeWidth', 16.0);
      for (final tool in [rectangleTool, CreateLineTool(), CreateTextTool()]) {
        editor.setTool(tool);
        expect(tool, isA<DrawingTool>());
        final first = editor.drawingInspectorKind!;
        final second = editor.drawingInspectorKind!;
        expect(identical(first, second), isFalse);
        expect(
          first.toDataModel()['strokeWidth'] ?? defaultStrokeWidth,
          tool is CreateTextTool ? defaultStrokeWidth : 16.0,
        );
      }
      expect(
        (rectangleTool.kind as FeatureKindRectangle).strokeWidth,
        defaultStrokeWidth,
      );
      editor.setTool(SelectTool());
      expect(editor.tool.activeTool, isNot(isA<DrawingTool>()));
      expect(editor.drawingInspectorKind, isNull);
    },
  );

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
    'session round trips serialized styles, Scratch, active ID and unknown fields',
    () {
      final editor = EditorContext(document: Document());
      addTearDown(editor.dispose);
      editor.brushes.setField('fontSize', 36.0);
      editor.brushes.setField('futureStyle', {'kind': 'shadow'});
      final brush = editor.brushes.create('Construction');
      editor.brushes.setField(
        'strokeColor',
        const Color(0xFFFFAA00).toARGB32(),
      );
      editor.brushes.setField('strokeType', StrokeType.dashed.name);
      editor.brushes.setField('strokeWidth', 3.0);
      editor.brushes.setField('endEndCap', LineEndCap.arrow.name);
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
    editor.brushes.addListener(() => sessionChanges++);
    final brush = editor.brushes.create('Actual');
    editor.brushes.setField('strokeWidth', 16.0);
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
    editor.brushes.clearField('strokeWidth');
    expect(
      (editor.drawingInspectorKind as FeatureKindPolyline).strokeWidth,
      defaultStrokeWidth,
    );
    expect(editor.brushes.active.id, brush.id);
    expect(brush.values, isEmpty);
    expect(editor.history.canUndo, isFalse);
    expect(sessionChanges, 3);
  });

  test('active deletion preserves drawing style; Scratch is protected', () {
    final editor = EditorContext(document: Document());
    addTearDown(editor.dispose);
    editor.brushes.setField('fillColor', const Color(0xFF112233).toARGB32());
    final brush = editor.brushes.create('Actual');
    editor.brushes.setField('strokeWidth', 16.0);
    editor.brushes.rename(brush.id, 'Renamed');
    editor.brushes.delete(brush.id);
    expect(editor.brushes.active.isScratch, isTrue);
    expect(editor.brushes.active.values, {
      'fillColor': const Color(0xFF112233).toARGB32(),
      'strokeWidth': 16.0,
    });
    editor.brushes.delete(BrushProfile.scratchId);
    editor.brushes.rename(BrushProfile.scratchId, 'Other');
    expect(editor.brushes.active.name, 'Scratch');
    expect(editor.document.session.brushes, hasLength(1));
  });

  test('replacing documents restores session without sharing mutable maps', () {
    final first = EditorContext(document: Document());
    addTearDown(first.dispose);
    first.brushes.create('Local');
    first.brushes.setField('strokeWidth', 3.0);
    final second = EditorContext(document: Document());
    addTearDown(second.dispose);
    final controller = second.brushes;
    var notifications = 0;
    controller.addListener(() => notifications++);
    second.loadDocument(first.document);
    expect(identical(second.brushes, controller), isTrue);
    expect(notifications, 1);
    second.brushes.setField('strokeWidth', 16.0);
    expect(first.brushes.active.values['strokeWidth'], 3.0);
    expect(second.brushes.active.name, 'Local');
    second.loadDocument(Document());
    controller.setField('fontSize', 36.0);
    expect(second.document.session.scratch.values, {'fontSize': 36.0});
    expect(first.brushes.active.values, {'strokeWidth': 3.0});
  });
}
