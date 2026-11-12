import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/feedback/feedback_service.dart';
import 'package:squiggle_flutter/feedback/widgets/report_button.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = createTestDatabase());
  tearDown(() => database.close());

  testWidgets('asks for the server first, then files the report', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final service = FeedbackService(
      appStateDao: database.appStateDao,
      appVersion: () async => '1.0.0',
      platform: 'linux',
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({'number': 7, 'url': 'https://github.com/o/r/issues/7'}),
          201,
        );
      }),
    );

    await tester.pumpWidget(
      Provider.value(
        value: service,
        child: MaterialApp(
          theme: SquiggleThemeData.dark(),
          home: const Scaffold(body: Center(child: ReportButton())),
        ),
      ),
    );

    await tester.tap(find.byType(ReportButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Idea'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Short title'),
      'Snap to grid',
    );
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('Report server'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'https://your-server.ts.net'),
      'https://box.ts.net',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'API token'),
      'secret',
    );
    await tester.tap(find.text('Save'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('Filed as issue #7'), findsOneWidget);
    expect(find.text('Report a bug or idea'), findsNothing);
    expect(requests.single.url.toString(), 'https://box.ts.net/v1/reports');
    expect(jsonDecode(requests.single.body), containsPair('kind', 'feature'));
    expect((await tester.runAsync(service.loadConnection))?.apiToken, 'secret');
  });
}
