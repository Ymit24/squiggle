import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/label_layout.dart';
import 'package:squiggle_flutter/painting/text_painter.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

/// Flutter's `RenderEditable` wraps text at `width - (caret width + 1)`, and
/// that 1 is private to the framework. Guarded by inline_text_editor_test.
const _caretGap = 1.0;

/// A [TextField] placed exactly over the canvas text it edits.
///
/// Typesetting happens in world units with [canvasTextStyle] (the style the
/// canvas painter uses), then the whole field is scaled by the camera, so line
/// breaks and glyph positions match the rendered text at any zoom. Selection,
/// caret movement, IME, and clipboard all come from the stock text field.
///
/// Must be a child of a [Stack] that shares the canvas's coordinate space.
class InlineTextEditor extends StatelessWidget {
  const InlineTextEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.layout,
    required this.editorContext,
    required this.onTapOutside,
    this.outlined = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueGetter<LabelLayout> layout;
  final EditorContext editorContext;
  final VoidCallback onTapOutside;

  /// Whether to frame the field. Shapes already have their own outline.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final accent = context.squiggleTheme.colors.accent;
    // One screen pixel in world units; decorations are sized with it so they
    // stay crisp regardless of zoom.
    return ListenableBuilder(
      // Vertical alignment follows the text height; scale follows the camera.
      listenable: Listenable.merge([controller, editorContext]),
      builder: (context, _) {
        final camera = editorContext.camera;
        final pixel = camera.zoom;
        final cursorWidth = 1.5 * pixel;
        final layout = this.layout();
        final origin = camera.worldToScreen(layout.textOrigin(controller.text));
        return Positioned(
          left: origin.dx,
          top: origin.dy,
          child: Transform.scale(
            scale: 1 / camera.zoom,
            alignment: Alignment.topLeft,
            child: SizedBox(
              // Widened by the caret margin so text wraps at the painter's
              // width; aligned text still lines up since layout starts at x=0.
              width: layout.bounds.width + cursorWidth + _caretGap,
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.noScaling),
                child: Material(
                  type: MaterialType.transparency,
                  child: TextSelectionTheme(
                    data: TextSelectionThemeData(
                      selectionColor: accent.withValues(alpha: 0.4),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (outlined) _outline(accent, pixel),
                        _textField(layout, cursorWidth),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _outline(Color accent, double pixel) {
    return Positioned.fill(
      left: -4 * pixel,
      top: -4 * pixel,
      right: -4 * pixel,
      bottom: -4 * pixel,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: accent, width: pixel),
          ),
        ),
      ),
    );
  }

  Widget _textField(LabelLayout layout, double cursorWidth) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textAlign: layout.horizontalAlignment.textAlign,
      style: canvasTextStyle(layout.fontSize, color: layout.color),
      cursorColor: layout.color,
      cursorWidth: cursorWidth,
      onTapOutside: (_) => onTapOutside(),
      decoration: const InputDecoration.collapsed(hintText: null),
    );
  }
}
