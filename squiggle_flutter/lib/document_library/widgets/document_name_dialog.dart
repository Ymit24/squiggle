import 'package:flutter/material.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';
import 'package:squiggle_flutter/widgets/squiggle_dialog.dart';
import 'package:squiggle_flutter/widgets/squiggle_text_field.dart';

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
    return SquiggleDialog(
      title: widget.title,
      content: SquiggleTextField(
        controller: _controller,
        autofocus: true,
        hintText: 'Canvas name',
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        SquiggleButton(
          onPressed: () => Navigator.of(context).pop(),
          label: 'Cancel',
          variant: SquiggleButtonVariant.ghost,
        ),
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) => SquiggleButton(
            onPressed: value.text.trim().isEmpty ? null : _submit,
            label: widget.confirmLabel,
          ),
        ),
      ],
    );
  }
}
