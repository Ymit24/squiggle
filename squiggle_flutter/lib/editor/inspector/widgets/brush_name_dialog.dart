import 'package:flutter/material.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';
import 'package:squiggle_flutter/widgets/squiggle_dialog.dart';
import 'package:squiggle_flutter/widgets/squiggle_text_field.dart';

class BrushNameDialog extends StatefulWidget {
  const BrushNameDialog({super.key, this.initialName, required this.creating});
  final String? initialName;
  final bool creating;

  @override
  State<BrushNameDialog> createState() => _BrushNameDialogState();
}

class _BrushNameDialogState extends State<BrushNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SquiggleDialog(
    title: widget.creating ? 'Create brush' : 'Rename brush',
    content: SquiggleTextField(
      controller: _controller,
      autofocus: true,
      hintText: 'Brush name',
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
          label: widget.creating ? 'Create' : 'Rename',
        ),
      ),
    ],
  );

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }
}
