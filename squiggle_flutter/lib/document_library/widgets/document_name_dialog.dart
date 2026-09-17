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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;

    return AlertDialog(
      backgroundColor: theme.colors.base,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colors.surface1),
      ),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      title: Text(
        widget.title,
        style: theme.typography.inputText.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 17,
          letterSpacing: -0.2,
        ),
      ),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _controller,
          autofocus: true,
          selectAllOnFocus: true,
          style: theme.typography.inputText.copyWith(fontSize: 14.5),
          decoration: InputDecoration(
            hintText: 'Canvas name',
            hintStyle: TextStyle(
              color: theme.colors.subtext0.withValues(alpha: 0.6),
            ),
            isDense: true,
            filled: true,
            fillColor: theme.colors.surface0,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colors.surface1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colors.surface1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: theme.colors.accent.withValues(alpha: 0.7),
                width: 1.4,
              ),
            ),
          ),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: theme.colors.subtext0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('Cancel'),
        ),
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) => FilledButton(
            onPressed: value.text.trim().isEmpty ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: theme.colors.text,
              foregroundColor: Colors.black87,
              disabledBackgroundColor: theme.colors.surface0,
              disabledForegroundColor: theme.colors.subtext0.withValues(
                alpha: 0.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: Text(
              widget.confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
