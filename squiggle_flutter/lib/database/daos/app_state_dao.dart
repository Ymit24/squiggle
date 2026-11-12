import 'package:drift/drift.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/database/tables/app_state.dart';

part 'app_state_dao.g.dart';

@DriftAccessor(tables: [AppState])
class AppStateDao extends DatabaseAccessor<AppDatabase>
    with _$AppStateDaoMixin {
  AppStateDao(super.attachedDatabase);

  static const _activeDocumentIdKey = 'activeDocumentId';
  static const _feedbackServerUrlKey = 'feedbackServerUrl';
  static const _feedbackApiTokenKey = 'feedbackApiToken';

  Future<String?> activeDocumentId() => _get(_activeDocumentIdKey);

  Future<void> setActiveDocumentId(String id) => _set(_activeDocumentIdKey, id);

  /// Where in-app bug/idea reports are sent, or null until configured.
  Future<({String url, String token})?> feedbackConnection() async {
    final url = await _get(_feedbackServerUrlKey);
    final token = await _get(_feedbackApiTokenKey);
    if (url == null || token == null) return null;
    return (url: url, token: token);
  }

  Future<void> setFeedbackConnection({
    required String url,
    required String token,
  }) => transaction(() async {
    await _set(_feedbackServerUrlKey, url);
    await _set(_feedbackApiTokenKey, token);
  });

  Future<String?> _get(String key) async {
    final row = await (select(
      appState,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _set(String key, String value) => into(appState)
      .insertOnConflictUpdate(AppStateCompanion.insert(key: key, value: value));
}
