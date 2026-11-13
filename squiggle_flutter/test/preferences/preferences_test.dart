import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/preferences/preferences.dart';

import '../support/test_database.dart';

enum _Size { small, large }

const _flag = BoolPreference('test.flag', true);
const _size = EnumPreference('test.size', _Size.small, _Size.values);

void main() {
  late AppDatabase database;

  setUp(() => database = createTestDatabase());
  tearDown(() => database.close());

  test('unset preferences read their defaults', () {
    final preferences = Preferences(dao: database.appStateDao);

    expect(preferences.get(_flag), isTrue);
    expect(preferences.get(_size), _Size.small);
  });

  test('set notifies once per change and persists across loads', () async {
    final preferences = Preferences(dao: database.appStateDao);
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
    final preferences = Preferences(
      dao: database.appStateDao,
      values: {'test.flag': 'maybe', 'test.size': 'medium'},
    );

    expect(preferences.get(_flag), isTrue);
    expect(preferences.get(_size), _Size.small);
  });
}
