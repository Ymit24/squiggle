import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/preferences/preferences.dart';

import '../support/test_database.dart';
import '../support/test_preferences.dart';

enum _Size { small, large }

const _flag = BoolPreference('test.flag', true);
const _size = EnumPreference('test.size', _Size.small, _Size.values);

void main() {
  test('unset preferences read their defaults', () {
    final preferences = testPreferences();

    expect(preferences.get(_flag), isTrue);
    expect(preferences.get(_size), _Size.small);
  });

  test('set notifies once per change and persists across loads', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final preferences = await Preferences.load(database.appStateDao);
    var notifications = 0;
    preferences.addListener(() => notifications++);

    await preferences.set(_flag, false);
    await preferences.set(_flag, false);
    await preferences.set(_size, _Size.large);

    expect(notifications, 2);
    final reloaded = await Preferences.load(database.appStateDao);
    expect(reloaded.get(_flag), isFalse);
    expect(reloaded.get(_size), _Size.large);
  });

  test('unreadable stored values fall back to the default', () {
    final preferences = testPreferences({
      'test.flag': 'maybe',
      'test.size': 'medium',
    });

    expect(preferences.get(_flag), isTrue);
    expect(preferences.get(_size), _Size.small);
  });

  testWidgets('watchPreference rebuilds when its value changes', (
    tester,
  ) async {
    final preferences = testPreferences();
    await tester.pumpWidget(
      withPreferences(
        Builder(
          builder: (context) => Text(
            context.watchPreference(_size).name,
            textDirection: TextDirection.ltr,
          ),
        ),
        preferences,
      ),
    );
    expect(find.text('small'), findsOneWidget);

    await preferences.set(_size, _Size.large);
    await tester.pump();
    expect(find.text('large'), findsOneWidget);
  });
}
