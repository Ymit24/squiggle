import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

Future<String?> showDocumentNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialName = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _DocumentNameDialog(
      title: title,
      confirmLabel: confirmLabel,
      initialName: initialName,
    ),
  );
}

class _DocumentNameDialog extends StatefulWidget {
  const _DocumentNameDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
  });

  final String title;
  final String confirmLabel;
  final String initialName;

  @override
  State<_DocumentNameDialog> createState() => _DocumentNameDialogState();
}

class _DocumentNameDialogState extends State<_DocumentNameDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;

    return AlertDialog(
      backgroundColor: theme.colors.mantle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
        side: BorderSide(color: theme.colors.surface1),
      ),
      title: Text(
        widget.title,
        style: theme.typography.inputText.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          style: theme.typography.inputText,
          decoration: theme.decorations.textField(),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: theme.colors.subtext0)),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            widget.confirmLabel,
            style: TextStyle(
              color: theme.colors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
