import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

const _panelPadding = 12.0;
const _buttonSpacing = 8.0;
const _fieldMinLines = 3;
const _fieldMaxLines = 5;

class TextEditPanel extends StatefulWidget {
  const TextEditPanel({
    super.key,
    required this.textFocusNode,
    required this.initialContents,
    required this.maxHeight,
    required this.onCancel,
    required this.onAccept,
  });

  final FocusNode textFocusNode;
  final String initialContents;
  final double maxHeight;
  final VoidCallback onCancel;
  final ValueChanged<String> onAccept;

  @override
  State<TextEditPanel> createState() => _TextEditPanelState();
}

class _TextEditPanelState extends State<TextEditPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContents);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SquiggleColors.mantle,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: SquiggleColors.surface1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(_panelPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: widget.maxHeight),
                child: TextField(
                  focusNode: widget.textFocusNode,
                  controller: _controller,
                  autofocus: true,
                  minLines: _fieldMinLines,
                  maxLines: _fieldMaxLines,
                  style: const TextStyle(
                    color: SquiggleColors.text,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: SquiggleColors.surface0,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: SquiggleColors.surface1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: SquiggleColors.surface1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: SquiggleColors.accent),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _buttonSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _PanelButton(
                    label: 'Cancel',
                    onPressed: widget.onCancel,
                  ),
                  const SizedBox(width: _buttonSpacing),
                  _PanelButton(
                    label: 'Accept',
                    isPrimary: true,
                    onPressed: () => widget.onAccept(_controller.text),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelButton extends StatefulWidget {
  const _PanelButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  State<_PanelButton> createState() => _PanelButtonState();
}

class _PanelButtonState extends State<_PanelButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isPrimary
        ? SquiggleColors.accent.withValues(alpha: _hovering ? 0.85 : 1)
        : (_hovering ? SquiggleColors.surface0 : SquiggleColors.surface1);
    final textColor = widget.isPrimary
        ? SquiggleColors.base
        : SquiggleColors.text;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              widget.label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: widget.isPrimary ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
