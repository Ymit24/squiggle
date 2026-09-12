import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/bloc/notifier_stream.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  group('EditorBloc', () {
    late EditorContext context;

    setUp(() {
      context = EditorContext(
        document: Document.fromFeatures([
          Feature(
            origin: const Offset(0, 0),
            size: const Size(100, 100),
            kind: const FeatureKindRectangle(),
          ),
        ]),
      );
    });

    test('subscribes to document changes via watch handler', () async {
      final bloc = EditorBloc(context: context);
      bloc.add(const RequestWatchEditorStateEvent());
      await bloc.stream.first;

      var documentChanged = false;
      final subscription = notifierChangesStream(context.history).listen((_) {
        documentChanged = true;
      });

      final feature = context.document.nodes.first;
      context.history.run('Move feature', (transaction) {
        transaction.update(
          feature,
          (feature) => feature.origin = const Offset(10, 10),
        );
      });
      await Future<void>.delayed(Duration.zero);

      expect(documentChanged, isTrue);
      expect(context.document.nodes.first.origin, const Offset(10, 10));
      await subscription.cancel();
      await bloc.close();
    });

    test('emits selection when model updates', () async {
      final bloc = EditorBloc(context: context);
      bloc.add(const RequestWatchEditorStateEvent());
      await bloc.stream.first;

      context.selection.selectNode(context.document.nodes.first.id);
      await bloc.stream.firstWhere((s) => s.selectedNodeIds.isNotEmpty);

      expect(bloc.state.selectedNodeIds.length, 1);
      await bloc.close();
    });
  });
}
