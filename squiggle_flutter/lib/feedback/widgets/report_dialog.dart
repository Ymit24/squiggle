import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/feedback/feedback_report.dart';
import 'package:squiggle_flutter/feedback/feedback_service.dart';
import 'package:squiggle_flutter/feedback/widgets/feedback_connection_dialog.dart';
import 'package:squiggle_flutter/feedback/widgets/report_kind_toggle.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';
import 'package:squiggle_flutter/widgets/squiggle_dialog.dart';
import 'package:squiggle_flutter/widgets/squiggle_text_field.dart';

/// Collects a bug report or idea and files it as a GitHub issue through the
/// report server.
Future<void> showReportDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _ReportDialog(),
  );
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  var _kind = FeedbackKind.bug;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return SquiggleDialog(
      title: 'Report a bug or idea',
      icon: LucideIcons.messageSquarePlus,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          ReportKindToggle(kind: _kind, onChanged: _setKind),
          SquiggleTextField(
            controller: _title,
            autofocus: true,
            hintText: 'Short title',
            maxLength: maxFeedbackTitleLength,
          ),
          SquiggleTextField(
            controller: _description,
            hintText: 'Details (optional)',
            maxLength: maxFeedbackDescriptionLength,
            minLines: 4,
            maxLines: 10,
          ),
          if (error != null)
            Text(
              error,
              style: TextStyle(
                color: context.squiggleTheme.colors.danger,
                fontSize: 12.5,
              ),
            ),
        ],
      ),
      actions: [
        SquiggleButton(
          onPressed: _sending
              ? null
              : () => showFeedbackConnectionDialog(context),
          label: 'Server…',
          variant: SquiggleButtonVariant.ghost,
        ),
        SquiggleButton(
          onPressed: () => Navigator.of(context).pop(),
          label: 'Cancel',
          variant: SquiggleButtonVariant.ghost,
        ),
        ValueListenableBuilder(
          valueListenable: _title,
          builder: (context, value, _) => SquiggleButton(
            onPressed: value.text.trim().isEmpty || _sending ? null : _submit,
            label: _sending ? 'Sending…' : 'Send',
          ),
        ),
      ],
    );
  }

  void _setKind(FeedbackKind kind) => setState(() => _kind = kind);

  Future<void> _submit() async {
    final service = context.read<FeedbackService>();
    setState(() {
      _sending = true;
      _error = null;
    });
    var connection = await service.loadConnection();
    if (!mounted) return;
    connection ??= await showFeedbackConnectionDialog(context);
    if (!mounted) return;
    if (connection == null) {
      setState(() => _sending = false);
      return;
    }
    final report = FeedbackReport(
      kind: _kind,
      title: _title.text.trim(),
      description: _description.text.trim(),
    );
    try {
      final submitted = await service.submit(connection, report);
      if (mounted) _close(submitted);
    } on FeedbackException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
    }
  }

  void _close(SubmittedReport submitted) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Filed as issue #${submitted.number}')),
    );
  }
}
