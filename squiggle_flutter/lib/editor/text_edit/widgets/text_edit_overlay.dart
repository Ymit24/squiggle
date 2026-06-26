import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/editor/text_edit/widgets/text_edit_panel.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

const _panelMaxWidth = 400.0;
const _panelMaxHeight = 200.0;
const _panelOffsetBelow = 4.0;

class TextEditOverlay extends StatefulWidget {
  const TextEditOverlay({
    super.key,
    required this.state,
    required this.viewportSize,
  });

  final TextEditOpen state;
  final Size viewportSize;

  @override
  State<TextEditOverlay> createState() => _TextEditOverlayState();
}

class _TextEditOverlayState extends State<TextEditOverlay> {
  final _textFocusNode = FocusNode();
  final _panelKey = GlobalKey();
  double? _panelHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _textFocusNode.requestFocus();
      _measurePanel();
    });
  }

  void _measurePanel() {
    final box = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final height = box.size.height;
    if (_panelHeight != height) {
      setState(() => _panelHeight = height);
    }
  }

  @override
  void dispose() {
    _textFocusNode.dispose();
    super.dispose();
  }

  void _cancel() {
    context.read<TextEditBloc>().add(const TextEditCancelled());
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final bounds = widget.state.canvasLocalBounds;
    final panelWidth =
        bounds.width.clamp(textEditPanelMinWidth, _panelMaxWidth);
    final left = bounds.left.clamp(0.0, widget.viewportSize.width - panelWidth);
    var top = bounds.top + _panelOffsetBelow;
    final panelHeight = _panelHeight;
    if (panelHeight != null) {
      top = top.clamp(0.0, widget.viewportSize.height - panelHeight);
    }

    return Positioned.fill(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: (_) {},
        onPointerPanZoomStart: (_) {},
        onPointerPanZoomUpdate: (_) {},
        onPointerPanZoomEnd: (_) {},
        child: FocusScope(
          autofocus: true,
          child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                _cancel();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _cancel,
                  child: ColoredBox(
                    color: theme.colors.scrim,
                  ),
                ),
                Positioned(
                  left: left,
                  top: top,
                  width: panelWidth,
                  child: TextEditPanel(
                    key: _panelKey,
                    textFocusNode: _textFocusNode,
                    initialContents: widget.state.initialContents,
                    maxHeight: _panelMaxHeight,
                    onCancel: _cancel,
                    onAccept: (contents) {
                      context.read<TextEditBloc>().add(
                        TextEditSubmitted(contents),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
