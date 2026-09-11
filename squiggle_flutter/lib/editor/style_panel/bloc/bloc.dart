import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/notifier_stream.dart';
import 'package:squiggle_flutter/models/node_layout.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/event.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/state.dart';
import 'package:squiggle_flutter/editor/style_panel/style_presets.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';

class StylePanelBloc extends Bloc<StylePanelEvent, StylePanelState> {
  StylePanelBloc({required this.context})
    : super(const StylePanelHiddenState()) {
    on<RequestWatchStylePanelStateEvent>(_onRequestWatchStylePanelState);
    on<SetStrokePresetEvent>(_onSetStrokePreset);
    on<ClearStrokeEvent>(_onClearStroke);
    on<SetFillPresetEvent>(_onSetFillPreset);
    on<ClearFillEvent>(_onClearFill);
    on<SetStrokeWidthEvent>(_onSetStrokeWidth);
    on<SetFontSizeEvent>(_onSetFontSize);
    on<SetTextHorizontalAlignmentEvent>(_onSetTextHorizontalAlignment);
    on<SetTextVerticalAlignmentEvent>(_onSetTextVerticalAlignment);
    on<AlignNodesEvent>(_onAlignNodes);
    on<DistributeNodesEvent>(_onDistributeNodes);
  }

  final EditorContext context;

  Future<void> _onRequestWatchStylePanelState(
    RequestWatchStylePanelStateEvent event,
    Emitter<StylePanelState> emit,
  ) async {
    emit(_deriveState());

    await emit.forEach(
      notifierChangesStream(context),
      onData: (_) => _deriveState(),
    );
  }

  StylePanelState _deriveState() {
    final selectedNodeIds = List<NodeId>.of(context.selection.selectedNodes);
    if (selectedNodeIds.isEmpty) {
      return const StylePanelHiddenState();
    }

    final kinds = selectedNodeIds
        .map(context.document.featureById)
        .whereType<Feature>()
        .map((feature) => feature.kind)
        .toList();
    final showStyleControls = kinds.isNotEmpty;
    if (!showStyleControls && selectedNodeIds.length < 2) {
      return const StylePanelHiddenState();
    }

    final isStrokeNone = kinds.every((kind) => !kind.hasVisibleStroke);
    final isFillNone = kinds.every((kind) => !kind.hasVisibleFill);

    final strokeColorStates = kinds.map(_strokeColorStateKey).toSet();
    final strokeWidthStates = kinds.map(_strokeWidthStateKey).toSet();
    final fillStates = kinds.map(_fillStateKey).toSet();

    final strokeMixed = strokeColorStates.length > 1;
    final strokeWidthMixed = strokeWidthStates.length > 1;
    final fillMixed = fillStates.length > 1;

    int? activeStrokePresetIndex;
    if (showStyleControls && !strokeMixed && !isStrokeNone) {
      activeStrokePresetIndex = strokePresetIndexForColor(
        kinds.first.strokeColor,
      );
    }

    int? activeFillPresetIndex;
    if (!fillMixed && !isFillNone) {
      activeFillPresetIndex = fillPresetIndexForColor(kinds.first.fillColor);
    }

    StrokeWidthPreset? activeStrokeWidth;
    if (showStyleControls && !strokeWidthMixed) {
      activeStrokeWidth = StrokeWidthPreset.fromWidth(kinds.first.strokeWidth);
    }

    final textKinds = kinds.whereType<FeatureKindText>().toList();
    final showFontSize = textKinds.isNotEmpty;

    var fontSizeMixed = false;
    FontSizePreset? activeFontSize;
    if (showFontSize) {
      final fontSizeStates = textKinds.map((kind) => kind.fontSize).toSet();
      fontSizeMixed = fontSizeStates.length > 1;
      if (!fontSizeMixed) {
        activeFontSize = FontSizePreset.fromSize(textKinds.first.fontSize);
      }
    }

    var horizontalAlignmentMixed = false;
    TextHorizontalAlignment? activeHorizontalAlignment;
    var verticalAlignmentMixed = false;
    TextVerticalAlignment? activeVerticalAlignment;
    if (showFontSize) {
      final horizontalStates = textKinds
          .map((kind) => kind.horizontalAlignment)
          .toSet();
      horizontalAlignmentMixed = horizontalStates.length > 1;
      if (!horizontalAlignmentMixed) {
        activeHorizontalAlignment = textKinds.first.horizontalAlignment;
      }

      final verticalStates = textKinds
          .map((kind) => kind.verticalAlignment)
          .toSet();
      verticalAlignmentMixed = verticalStates.length > 1;
      if (!verticalAlignmentMixed) {
        activeVerticalAlignment = textKinds.first.verticalAlignment;
      }
    }

    return StylePanelShowingState(
      selectedNodeIds: selectedNodeIds,
      showStyleControls: showStyleControls,
      activeStrokePresetIndex: activeStrokePresetIndex,
      isStrokeNone: isStrokeNone,
      strokeMixed: strokeMixed,
      strokeWidthMixed: strokeWidthMixed,
      activeFillPresetIndex: activeFillPresetIndex,
      isFillNone: isFillNone,
      fillMixed: fillMixed,
      activeStrokeWidth: activeStrokeWidth,
      canClearStroke: !isStrokeNone,
      canClearFill: !isFillNone,
      showFontSize: showFontSize,
      fontSizeMixed: fontSizeMixed,
      activeFontSize: activeFontSize,
      horizontalAlignmentMixed: horizontalAlignmentMixed,
      activeHorizontalAlignment: activeHorizontalAlignment,
      verticalAlignmentMixed: verticalAlignmentMixed,
      activeVerticalAlignment: activeVerticalAlignment,
    );
  }

  String _strokeColorStateKey(FeatureKind kind) {
    if (!kind.hasVisibleStroke) {
      return 'none';
    }
    return 'stroke:${kind.strokeColor.toARGB32()}';
  }

  String _strokeWidthStateKey(FeatureKind kind) {
    return 'width:${kind.strokeWidth}';
  }

  String _fillStateKey(FeatureKind kind) {
    if (!kind.hasVisibleFill) {
      return 'none';
    }
    return 'fill:${kind.fillColor.toARGB32()}';
  }

  List<NodeId> _selectedIdsOrEmpty() {
    final current = state;
    if (current is! StylePanelShowingState) {
      return const [];
    }
    return current.selectedNodeIds;
  }

  void _applyStyleUpdate({
    Color? strokeColor,
    Color? fillColor,
    double? strokeWidth,
    double? fontSize,
    TextHorizontalAlignment? horizontalAlignment,
    TextVerticalAlignment? verticalAlignment,
  }) {
    final ids = _selectedIdsOrEmpty();
    if (ids.isEmpty) return;

    final features = _nodesById(ids).whereType<Feature>();
    if (features.isEmpty) return;
    final container = features.first.parent;
    if (features.any((feature) => !identical(feature.parent, container))) {
      throw StateError('Selected nodes must share a container');
    }
    context.history.run('Change style', (transaction) {
      transaction.watch(features);
      for (final feature in features) {
        final newKind = switch (feature.kind) {
          FeatureKindText() => feature.kind.copyWithStyle(
            strokeColor: strokeColor,
            fillColor: fillColor,
            strokeWidth: strokeWidth,
            fontSize: fontSize,
            horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
          ),
          _ => feature.kind.copyWithStyle(
            strokeColor: strokeColor,
            fillColor: fillColor,
            strokeWidth: strokeWidth,
          ),
        };

        if (fontSize != null && newKind is FeatureKindText) {
          final size = newKind.measureContents(
            width: feature.size.width,
            fontSize: newKind.fontSize,
          );
          feature.setKind(newKind, newSize: size);
        } else {
          feature.setKind(newKind);
        }
      }
    }, container: container);
  }

  void _onSetStrokePreset(
    SetStrokePresetEvent event,
    Emitter<StylePanelState> emit,
  ) {
    if (state is! StylePanelShowingState) return;
    if (event.index < 0 || event.index >= stylePresets.length) return;

    final preset = stylePresets[event.index];
    _applyStyleUpdate(strokeColor: preset.strokeColor);
  }

  void _onClearStroke(ClearStrokeEvent event, Emitter<StylePanelState> emit) {
    final current = state;
    if (current is! StylePanelShowingState || !current.canClearStroke) return;

    _applyStyleUpdate(strokeColor: transparentStrokeColor);
  }

  void _onSetFillPreset(
    SetFillPresetEvent event,
    Emitter<StylePanelState> emit,
  ) {
    if (state is! StylePanelShowingState) return;
    if (event.index < 0 || event.index >= stylePresets.length) return;

    final preset = stylePresets[event.index];
    _applyStyleUpdate(fillColor: preset.fillColor);
  }

  void _onClearFill(ClearFillEvent event, Emitter<StylePanelState> emit) {
    final current = state;
    if (current is! StylePanelShowingState || !current.canClearFill) return;

    _applyStyleUpdate(fillColor: transparentFillColor);
  }

  void _onSetStrokeWidth(
    SetStrokeWidthEvent event,
    Emitter<StylePanelState> emit,
  ) {
    if (state is! StylePanelShowingState) return;

    _applyStyleUpdate(strokeWidth: event.preset.width);
  }

  void _onSetFontSize(SetFontSizeEvent event, Emitter<StylePanelState> emit) {
    if (state is! StylePanelShowingState) return;

    _applyStyleUpdate(fontSize: event.preset.size);
  }

  void _onSetTextHorizontalAlignment(
    SetTextHorizontalAlignmentEvent event,
    Emitter<StylePanelState> emit,
  ) {
    if (state is! StylePanelShowingState) return;

    _applyStyleUpdate(horizontalAlignment: event.alignment);
  }

  void _onSetTextVerticalAlignment(
    SetTextVerticalAlignmentEvent event,
    Emitter<StylePanelState> emit,
  ) {
    if (state is! StylePanelShowingState) return;

    _applyStyleUpdate(verticalAlignment: event.alignment);
  }

  void _onAlignNodes(AlignNodesEvent event, Emitter<StylePanelState> emit) {
    final ids = _selectedIdsOrEmpty();
    if (ids.length < 2) return;

    _applyOffsets(
      computeAlignmentOffsets(context.document, ids, event.alignment),
    );
  }

  void _onDistributeNodes(
    DistributeNodesEvent event,
    Emitter<StylePanelState> emit,
  ) {
    final ids = _selectedIdsOrEmpty();
    if (ids.length < 3) return;

    _applyOffsets(
      computeDistributionOffsets(context.document, ids, event.distribution),
    );
  }

  List<Node> _nodesById(Iterable<NodeId> ids) => [
    for (final id in ids) ?context.document.nodeById(id),
  ];

  void _applyOffsets(Map<NodeId, Offset> offsets) {
    final nodes = _nodesById(offsets.keys);
    if (nodes.isEmpty) return;
    final container = nodes.first.parent;
    if (nodes.any((node) => !identical(node.parent, container))) {
      throw StateError('Selected nodes must share a container');
    }
    context.history.run('Layout selection', (transaction) {
      for (final node in nodes) {
        transaction.update(node, (node) => node.origin += offsets[node.id]!);
      }
    }, container: container);
  }
}
