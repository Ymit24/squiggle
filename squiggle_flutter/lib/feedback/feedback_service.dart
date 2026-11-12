import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:squiggle_flutter/database/daos/app_state_dao.dart';
import 'package:squiggle_flutter/feedback/feedback_connection.dart';
import 'package:squiggle_flutter/feedback/feedback_report.dart';

/// Stores the report server connection and sends reports to it.
class FeedbackService {
  FeedbackService({
    required this._appStateDao,
    http.Client? client,
    Future<String> Function()? appVersion,
    String? platform,
  }) : _client = client ?? http.Client(),
       _appVersion = appVersion ?? _packageVersion,
       _platform = platform ?? Platform.operatingSystem;

  static const _timeout = Duration(seconds: 15);

  final AppStateDao _appStateDao;
  final http.Client _client;
  final Future<String> Function() _appVersion;
  final String _platform;

  Future<FeedbackConnection?> loadConnection() async {
    final stored = await _appStateDao.feedbackConnection();
    if (stored == null) return null;
    return FeedbackConnection(
      serverUrl: Uri.parse(stored.url),
      apiToken: stored.token,
    );
  }

  Future<void> saveConnection(FeedbackConnection connection) =>
      _appStateDao.setFeedbackConnection(
        url: connection.serverUrl.toString(),
        token: connection.apiToken,
      );

  /// Throws [FeedbackException] unless the server accepts the token.
  Future<void> testConnection(FeedbackConnection connection) => _send(
    () => _client.get(
      connection.endpoint('v1/auth'),
      headers: connection.authHeaders,
    ),
  );

  Future<SubmittedReport> submit(
    FeedbackConnection connection,
    FeedbackReport report,
  ) async {
    final body = jsonEncode({
      'kind': report.kind.name,
      'title': report.title,
      'description': report.description,
      'app_version': await _appVersion(),
      'platform': _platform,
    });
    final response = await _send(
      () => _client.post(
        connection.endpoint('v1/reports'),
        headers: {
          ...connection.authHeaders,
          'Content-Type': 'application/json',
        },
        body: body,
      ),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return SubmittedReport(
      number: json['number'] as int,
      url: Uri.parse(json['url'] as String),
    );
  }

  void close() => _client.close();

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on Exception {
      throw const FeedbackException("Couldn't reach the report server.");
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    throw FeedbackException(_errorMessage(response));
  }

  /// The server's own message when it sent one.
  static String _errorMessage(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      if (json is Map && json['message'] is String) {
        return json['message'] as String;
      }
    } on FormatException {
      // Not one of the server's JSON errors; fall through.
    }
    return 'The report server responded with ${response.statusCode}.';
  }

  static Future<String> _packageVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (info.buildNumber.isEmpty) return info.version;
    return '${info.version}+${info.buildNumber}';
  }
}

/// A failure to show the user as-is.
class FeedbackException implements Exception {
  const FeedbackException(this.message);

  final String message;

  @override
  String toString() => message;
}
