import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/feedback/feedback_connection.dart';
import 'package:squiggle_flutter/feedback/feedback_report.dart';
import 'package:squiggle_flutter/feedback/feedback_service.dart';

import '../support/test_database.dart';

final _connection = FeedbackConnection(
  serverUrl: Uri.parse('https://box.ts.net'),
  apiToken: 'secret',
);

const _report = FeedbackReport(
  kind: FeedbackKind.feature,
  title: 'Snap to grid',
  description: 'Would help alignment',
);

void main() {
  late AppDatabase database;

  setUp(() => database = createTestDatabase());
  tearDown(() => database.close());

  FeedbackService service(MockClientHandler handler) => FeedbackService(
    appStateDao: database.appStateDao,
    client: MockClient(handler),
    appVersion: () async => '0.2.34+77',
    platform: 'linux',
  );

  test('saves and reloads the connection', () async {
    final feedback = service((_) async => http.Response('', 500));
    expect(await feedback.loadConnection(), isNull);

    await feedback.saveConnection(_connection);
    final loaded = await feedback.loadConnection();

    expect(loaded?.serverUrl, _connection.serverUrl);
    expect(loaded?.apiToken, 'secret');
  });

  test('submits the report with auth and app details', () async {
    late http.Request sent;
    final feedback = service((request) async {
      sent = request;
      return http.Response(
        jsonEncode({'number': 7, 'url': 'https://github.com/o/r/issues/7'}),
        201,
      );
    });

    final submitted = await feedback.submit(_connection, _report);

    expect(submitted.number, 7);
    expect(submitted.url.toString(), 'https://github.com/o/r/issues/7');
    expect(sent.method, 'POST');
    expect(sent.url.toString(), 'https://box.ts.net/v1/reports');
    expect(sent.headers['Authorization'], 'Bearer secret');
    expect(jsonDecode(sent.body), {
      'kind': 'feature',
      'title': 'Snap to grid',
      'description': 'Would help alignment',
      'app_version': '0.2.34+77',
      'platform': 'linux',
    });
  });

  test('surfaces the server error message', () async {
    final feedback = service(
      (_) async => http.Response(
        jsonEncode({'error': 'rate_limited', 'message': 'Slow down.'}),
        429,
      ),
    );

    await expectLater(
      feedback.submit(_connection, _report),
      throwsA(
        isA<FeedbackException>().having(
          (e) => e.message,
          'message',
          'Slow down.',
        ),
      ),
    );
  });

  test('falls back to the status code for non-JSON errors', () async {
    final feedback = service((_) async => http.Response('<html>', 502));

    await expectLater(
      feedback.testConnection(_connection),
      throwsA(
        isA<FeedbackException>().having(
          (e) => e.message,
          'message',
          contains('502'),
        ),
      ),
    );
  });

  test('reports unreachable servers', () async {
    final feedback = service((_) async => throw http.ClientException('down'));

    await expectLater(
      feedback.testConnection(_connection),
      throwsA(
        isA<FeedbackException>().having(
          (e) => e.message,
          'message',
          "Couldn't reach the report server.",
        ),
      ),
    );
  });

  test('connection test hits the auth endpoint', () async {
    late http.Request sent;
    final feedback = service((request) async {
      sent = request;
      return http.Response('', 204);
    });

    await feedback.testConnection(_connection);

    expect(sent.method, 'GET');
    expect(sent.url.toString(), 'https://box.ts.net/v1/auth');
    expect(sent.headers['Authorization'], 'Bearer secret');
  });
}
