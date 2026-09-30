import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondash_message_channel/irondash_message_channel.dart';
import 'package:provider/provider.dart';
import 'package:super_native_extensions/src/native/context.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/shortcuts/shortcuts.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/services/node_clipboard.dart';

EditorContext selectedContext() {
  final context = EditorContext(
    document: Document.fromFeatures([
      for (var i = 0; i < 3; i++)
        Feature(
          origin: Offset(i * 100, 20),
          size: const Size(40, 60),
          kind: FeatureKindRectangle(),
        ),
    ]),
  );
  context.selection.setSelection(
    context.document.nodes.take(2).map((node) => node.id),
  );
  return context;
}

Future<void> pumpShortcuts(
  WidgetTester tester,
  EditorContext context, {
  bool textEditOpen = false,
  Widget child = const SizedBox.expand(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<EditorContext>.value(value: context),
          RepositoryProvider<ImageRepository>(create: (_) => ImageRepository()),
        ],
        child: BlocProvider(
          create: (_) => ToolbarBloc(context: context),
          child: Material(
            child: ToolShortcuts(textEditOpen: textEditOpen, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pressShortcut(
  WidgetTester tester,
  LogicalKeyboardKey modifier,
  LogicalKeyboardKey key,
  String platform, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(modifier, platform: platform);
  if (shift) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift, platform: platform);
  }
  await tester.sendKeyEvent(key, platform: platform);
  if (shift) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift, platform: platform);
  }
  await tester.sendKeyUpEvent(modifier, platform: platform);
  await tester.pump();
}

void main() {
  final clipboard = MockMessageChannelContext();
  var writes = 0;
  var nextProviderId = 0;
  final providers = <int, Map<dynamic, dynamic>>{};
  String? copiedText;
  Completer<void>? writeCompletion;

  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
    setContextOverride(clipboard);
    clipboard.registerMockMethodCallHandler('DataProviderManager', (call) {
      if (call.method == 'registerDataProvider') {
        providers[++nextProviderId] = call.arguments as Map;
        return nextProviderId;
      }
      if (call.method == 'unregisterDataProvider') return null;
      throw StateError('Unexpected provider method: ${call.method}');
    });
    clipboard.registerMockMethodCallHandler('ClipboardWriter', (call) async {
      expectSync(call.method, 'writeToClipboard');
      writes++;
      final provider = providers[(call.arguments as Iterable).single]!;
      final representations = provider['representations'] as Iterable;
      copiedText = representations.first['data'] as String;
      await writeCompletion?.future;
      return null;
    });
  });
  setUp(() {
    writes = 0;
    copiedText = null;
    writeCompletion = null;
    providers.clear();
  });

  for (final platform in ['macos', 'linux', 'windows']) {
    final modifier = platform == 'macos'
        ? LogicalKeyboardKey.meta
        : LogicalKeyboardKey.control;
    testWidgets('$platform cut waits for copy and supports one undo/redo', (
      tester,
    ) async {
      final context = selectedContext();
      final before = context.document.toDataModel().toJson();
      final selectedIds = context.selection.selectedNodeIds.toList();
      final remainingId = context.document.nodes.last.id;
      writeCompletion = Completer<void>();
      await pumpShortcuts(tester, context);
      await pressShortcut(tester, modifier, LogicalKeyboardKey.keyX, platform);
      expect(writes, 1);
      expect(isSquiggleNodesClipboardText(copiedText!), isTrue);
      final payload = jsonDecode(
        copiedText!.substring('squiggle-nodes:2:'.length),
      );
      expect(payload['nodes'], hasLength(2));
      expect(context.document.toDataModel().toJson(), before);
      expect(context.selection.selectedNodeIds, selectedIds);
      expect(context.history.canUndo, isFalse);
      writeCompletion!.complete();
      await tester.pumpAndSettle();
      expect(context.document.nodes.map((node) => node.id), [remainingId]);
      expect(context.selection.selectedNodeIds, isEmpty);
      final after = context.document.toDataModel().toJson();
      await pressShortcut(tester, modifier, LogicalKeyboardKey.keyZ, platform);
      expect(context.document.toDataModel().toJson(), before);
      expect(context.history.canUndo, isFalse);
      await pressShortcut(
        tester,
        modifier,
        LogicalKeyboardKey.keyZ,
        platform,
        shift: true,
      );
      expect(context.document.toDataModel().toJson(), after);
      expect(context.history.canRedo, isFalse);
      expect(writes, 1);
    });
    testWidgets('$platform cut with empty selection is a no-op', (
      tester,
    ) async {
      final context = selectedContext();
      context.selection.setSelection([]);
      await pumpShortcuts(tester, context);
      await pressShortcut(tester, modifier, LogicalKeyboardKey.keyX, platform);
      expect(context.document.nodes, hasLength(3));
      expect(context.history.canUndo, isFalse);
      expect(writes, 0);
    });
    testWidgets('$platform cut preserves native text editing', (tester) async {
      final context = selectedContext();
      final focus = FocusNode();
      final controller = TextEditingController(text: 'hello world');
      String? textClipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            textClipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(focus.dispose);
      addTearDown(controller.dispose);
      debugDefaultTargetPlatformOverride = switch (platform) {
        'macos' => TargetPlatform.macOS,
        'windows' => TargetPlatform.windows,
        _ => TargetPlatform.linux,
      };
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await pumpShortcuts(
        tester,
        context,
        textEditOpen: true,
        child: TextField(focusNode: focus, controller: controller),
      );
      focus.requestFocus();
      await tester.pumpAndSettle();
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      );
      await tester.pumpAndSettle();
      await pressShortcut(tester, modifier, LogicalKeyboardKey.keyX, platform);
      await tester.pumpAndSettle();
      expect(controller.text, ' world');
      expect(textClipboard, 'hello');
      expect(focus.hasFocus, isTrue);
      expect(context.document.nodes, hasLength(3));
      expect(context.selection.selectedNodeIds, hasLength(2));
      expect(context.history.canUndo, isFalse);
      expect(writes, 0);
      debugDefaultTargetPlatformOverride = null;
    });
  }
  testWidgets('failed clipboard copy leaves nodes and history unchanged', (
    tester,
  ) async {
    final context = selectedContext();
    final before = context.document.toDataModel().toJson();
    writeCompletion = Completer<void>();
    final cut = cutSelectedNodesToClipboard(
      context: context,
      imageRepository: ImageRepository(),
    );
    final failure = expectLater(cut, throwsA(isA<PlatformException>()));
    await tester.pump();
    expect(writes, 1);
    writeCompletion!.completeError(PlatformException(code: 'clipboard_failed'));
    await failure;
    expect(context.document.toDataModel().toJson(), before);
    expect(context.selection.selectedNodeIds, hasLength(2));
    expect(context.history.canUndo, isFalse);
  });
}
