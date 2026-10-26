import 'package:flutter/material.dart';
import 'package:squiggle_flutter/migration/legacy_importer.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

/// Temporary screen shown before the app starts while old file-based data is
/// waiting to be imported. Never merged to `main`.
class MigrationApp extends StatefulWidget {
  const MigrationApp({
    super.key,
    required this.importer,
    required this.onContinue,
  });

  final LegacyImporter importer;
  final VoidCallback onContinue;

  @override
  State<MigrationApp> createState() => _MigrationAppState();
}

class _MigrationAppState extends State<MigrationApp> {
  bool _running = false;
  MigrationReport? _report;
  Object? _error;
  Duration? _elapsed;

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SquiggleThemeData.dark(),
      home: Builder(
        builder: (context) {
          final theme = context.squiggleTheme;
          final style = theme.typography.inputText;
          return Scaffold(
            backgroundColor: theme.colors.mantle,
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import old canvases',
                      style: style.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Squiggle now stores canvases in a database. Importing '
                      'copies your old canvases and images into it; the old '
                      'files are left as they are.',
                      style: style.copyWith(color: theme.colors.subtext0),
                    ),
                    const SizedBox(height: 20),
                    if (report == null)
                      SquiggleButton(
                        onPressed: _running ? null : _run,
                        icon: Icons.download_rounded,
                        label: _running ? 'Importing...' : 'Import',
                      )
                    else ...[
                      Text(
                        '${report.documentsImported} canvases imported '
                        '(${report.documentsAlreadyImported} already there), '
                        '${report.images} images, '
                        '${report.imageNodesDropped} missing images left out, '
                        'in ${_elapsed!.inMilliseconds} ms.',
                        style: style,
                      ),
                      for (final problem in report.problems)
                        Text(
                          'Skipped $problem',
                          style: style.copyWith(color: theme.colors.danger),
                        ),
                      const SizedBox(height: 20),
                      SquiggleButton(
                        onPressed: widget.onContinue,
                        icon: Icons.arrow_forward_rounded,
                        label: 'Continue',
                      ),
                    ],
                    if (_error != null)
                      Text(
                        'Import failed: $_error',
                        style: style.copyWith(color: theme.colors.danger),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _run() async {
    setState(() => _running = true);
    final stopwatch = Stopwatch()..start();
    try {
      final report = await widget.importer.run();
      setState(() {
        _report = report;
        _elapsed = stopwatch.elapsed;
      });
    } on Object catch (error) {
      setState(() => _error = error);
    } finally {
      setState(() => _running = false);
    }
  }
}
