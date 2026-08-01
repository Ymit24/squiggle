import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/bloc/notifier_stream.dart';
import 'package:squiggle_flutter/editor/commands/commands.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  group('EditorBloc', () {
    late EditorContext context;

    setUp(() {
      context = EditorContext(
        document: Document.fromFeatures([
          Feature(origin: const Offset(0, 0), size: const Size(100, 100), kind: const FeatureKindRectangle()),
        ]),
      );
    });

    test('subscribes to document changes via watch handler', () async {
      final bloc = EditorBloc(context: context);
      bloc.add(const RequestWatchEditorStateEvent());
      await bloc.stream.first;

      var documentChanged = false;
      final subscription = notifierChangesStream(context.document).listen((_) {
        documentChanged = true;
      });

      context.execute(
        MoveFeatureCommand(
          context.document.features.first.id,
          const Offset(10, 10),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(documentChanged, isTrue);
      expect(
        context.document.features.first.origin,
        const Offset(10, 10),
      );
      await subscription.cancel();
      await bloc.close();
    });

    test('emits selection when model updates', () async {
      final bloc = EditorBloc(context: context);
      bloc.add(const RequestWatchEditorStateEvent());
      await bloc.stream.first;

      context.selection.selectFeature(context.document.features.first.id);
      await bloc.stream.firstWhere((s) => s.selectedFeatures.isNotEmpty);

      expect(bloc.state.selectedFeatures.length, 1);
      await bloc.close();
    });

    test('deletes selected features and clears selection', () async {
      final featureId = context.document.features.first.id;
      context.selection.selectFeature(featureId);

      final bloc = EditorBloc(context: context);
      bloc.add(const DeleteSelectedFeaturesEvent());
      await Future<void>.delayed(Duration.zero);

      expect(context.document.features, isEmpty);
      expect(context.selection.selectedFeatures, isEmpty);
      await bloc.close();
    });
  });
}
