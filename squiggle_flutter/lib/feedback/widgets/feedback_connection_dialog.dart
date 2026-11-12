import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/feedback/feedback_connection.dart';
import 'package:squiggle_flutter/feedback/feedback_service.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';
import 'package:squiggle_flutter/widgets/squiggle_dialog.dart';
import 'package:squiggle_flutter/widgets/squiggle_text_field.dart';

/// Edits where reports are sent. Resolves to the saved connection, or null
/// when cancelled.
Future<FeedbackConnection?> showFeedbackConnectionDialog(BuildContext context) {
  return showDialog<FeedbackConnection>(
    context: context,
    builder: (context) => const _FeedbackConnectionDialog(),
  );
}

class _FeedbackConnectionDialog extends StatefulWidget {
  const _FeedbackConnectionDialog();

  @override
  State<_FeedbackConnectionDialog> createState() =>
      _FeedbackConnectionDialogState();
}

class _FeedbackConnectionDialogState extends State<_FeedbackConnectionDialog> {
  final _url = TextEditingController();
  final _token = TextEditingController();
  bool _busy = false;
  ({String text, bool ok})? _status;

  FeedbackService get _service => context.read<FeedbackService>();

  @override
  void initState() {
    super.initState();
    _service.loadConnection().then(_prefill);
  }

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.squiggleTheme.colors;
    final status = _status;
    return SquiggleDialog(
      title: 'Report server',
      icon: LucideIcons.server,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          SquiggleTextField(
            controller: _url,
            autofocus: true,
            hintText: 'https://your-server.ts.net',
          ),
          SquiggleTextField(
            controller: _token,
            hintText: 'API token',
            obscureText: true,
            onSubmitted: (_) => _save(),
          ),
          if (status != null)
            Text(
              status.text,
              style: TextStyle(
                color: status.ok ? colors.accent : colors.danger,
                fontSize: 12.5,
              ),
            ),
        ],
      ),
      actions: [
        SquiggleButton(
          onPressed: () => Navigator.of(context).pop(),
          label: 'Cancel',
          variant: SquiggleButtonVariant.ghost,
        ),
        SquiggleButton(
          onPressed: _busy ? null : _test,
          label: 'Test connection',
          variant: SquiggleButtonVariant.secondary,
        ),
        SquiggleButton(onPressed: _busy ? null : _save, label: 'Save'),
      ],
    );
  }

  void _prefill(FeedbackConnection? connection) {
    if (!mounted || connection == null) return;
    _url.text = connection.serverUrl.toString();
    _token.text = connection.apiToken;
  }

  /// The entered connection, or null after showing why it is unusable.
  FeedbackConnection? _parse() {
    final urlError = FeedbackConnection.validateServerUrl(_url.text);
    final token = _token.text.trim();
    final error = urlError ?? (token.isEmpty ? 'Enter the API token.' : null);
    setState(() => _status = error == null ? null : (text: error, ok: false));
    if (error != null) return null;
    return FeedbackConnection(
      serverUrl: Uri.parse(_url.text.trim()),
      apiToken: token,
    );
  }

  Future<void> _test() async {
    final connection = _parse();
    if (connection == null) return;
    setState(() => _busy = true);
    final status = await _service
        .testConnection(connection)
        .then((_) => (text: 'Connected.', ok: true))
        .onError<FeedbackException>((e, _) => (text: e.message, ok: false));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = status;
    });
  }

  Future<void> _save() async {
    final connection = _parse();
    if (connection == null) return;
    await _service.saveConnection(connection);
    if (mounted) Navigator.of(context).pop(connection);
  }
}
