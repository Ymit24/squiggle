import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/database/app_database.dart';

/// Rebuilds [builder] whenever [preferenceKey] changes in [AppDatabase].
class PreferenceBuilder extends StatelessWidget {
  const PreferenceBuilder({
    super.key,
    required this.preferenceKey,
    this.initialValue,
    required this.builder,
  });

  final String preferenceKey;
  final String? initialValue;
  final Widget Function(BuildContext context, String? value) builder;

  @override
  Widget build(BuildContext context) {
    final preferencesDao = context.read<AppDatabase>().preferencesDao;
    return StreamBuilder<String?>(
      stream: preferencesDao.watchValue(preferenceKey),
      initialData: initialValue,
      builder: (context, snapshot) => builder(context, snapshot.data),
    );
  }
}
