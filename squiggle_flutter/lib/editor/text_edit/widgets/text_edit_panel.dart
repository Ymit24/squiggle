import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:squiggle_flutter/theme/squiggle_spacing.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class _AcceptTextIntent extends Intent {
  const _AcceptTextIntent();
}

const _fieldMinLines = 3;
const _fieldMaxLines = 5;

/// Minimum width needed for the Cancel/Accept button row, excluding panel padding.
const textEditPanelButtonRowMinWidth = 154.0;

/// Minimum width for the positioned edit panel, including padding.
const textEditPanelMinWidth =
    kTextEditPanelPadding * 2 + textEditPanelButtonRowMinWidth;

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

  void _accept() => widget.onAccept(_controller.text);

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;
    final colors = theme.colors;

    return Material(
      color: colors.mantle,
      elevation: 4,
      borderRadius: BorderRadius.circular(theme.radii.textEditPanel),
      child: DecoratedBox(
        decoration: theme.decorations.textEditPanel(),
        child: Padding(
          padding: EdgeInsets.all(spacing.textEditPanelPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: widget.maxHeight),
                child: Shortcuts(
                  shortcuts: const {
                    SingleActivator(
                      LogicalKeyboardKey.enter,
                      meta: true,
                    ): _AcceptTextIntent(),
                    SingleActivator(
                      LogicalKeyboardKey.enter,
                      control: true,
                    ): _AcceptTextIntent(),
                  },
                  child: Actions(
                    actions: {
                      _AcceptTextIntent: CallbackAction<_AcceptTextIntent>(
                        onInvoke: (_) {
                          _accept();
                          return null;
                        },
                      ),
                    },
                    child: TextField(
                      focusNode: widget.textFocusNode,
                      controller: _controller,
                      autofocus: true,
                      minLines: _fieldMinLines,
                      maxLines: _fieldMaxLines,
                      style: theme.typography.inputText,
                      decoration: theme.decorations.textField(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacing.textEditButtonSpacing),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: spacing.textEditButtonSpacing,
                runSpacing: spacing.textEditButtonSpacing,
                children: [
                  _PanelButton(
                    label: 'Cancel',
                    onPressed: widget.onCancel,
                  ),
                  _PanelButton(
                    label: 'Accept',
                    isPrimary: true,
                    onPressed: _accept,
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
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: theme.decorations.panelButton(
            isPrimary: widget.isPrimary,
            isHovering: _hovering,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.textEditButtonHorizontalPadding,
              vertical: spacing.textEditButtonVerticalPadding,
            ),
            child: Text(
              widget.label,
              style: theme.typography.panelButtonLabel(
                isPrimary: widget.isPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
