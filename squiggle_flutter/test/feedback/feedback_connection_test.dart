import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/feedback/feedback_connection.dart';

void main() {
  group('FeedbackConnection', () {
    test('accepts https anywhere and http only on loopback', () {
      expect(
        FeedbackConnection.validateServerUrl('https://box.ts.net'),
        isNull,
      );
      expect(
        FeedbackConnection.validateServerUrl(' http://localhost:8787 '),
        isNull,
      );
      expect(
        FeedbackConnection.validateServerUrl('http://box.ts.net'),
        contains('https'),
      );
      expect(FeedbackConnection.validateServerUrl('box.ts.net'), isNotNull);
      expect(FeedbackConnection.validateServerUrl(''), isNotNull);
      expect(
        FeedbackConnection.validateServerUrl('https://box.ts.net/?a=1'),
        isNotNull,
      );
    });

    test('endpoints keep any path prefix on the server URL', () {
      FeedbackConnection at(String url) =>
          FeedbackConnection(serverUrl: Uri.parse(url), apiToken: 't');

      expect(
        at('https://box.ts.net').endpoint('v1/reports').toString(),
        'https://box.ts.net/v1/reports',
      );
      expect(
        at('https://box.ts.net/feedback').endpoint('v1/auth').toString(),
        'https://box.ts.net/feedback/v1/auth',
      );
      expect(
        at('https://box.ts.net/feedback/').endpoint('v1/auth').toString(),
        'https://box.ts.net/feedback/v1/auth',
      );
    });
  });
}
