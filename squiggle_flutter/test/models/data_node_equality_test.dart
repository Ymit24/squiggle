import 'package:data_models/data_models.dart' as data;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('features use deep value equality', () {
    final first = _feature(1);
    final equal = _feature(1);
    final changed = _feature(1, strokeWidth: 3);

    expect(first, equal);
    expect(first.hashCode, equal.hashCode);
    expect(first, isNot(changed));
  });

  test('groups use recursive value equality', () {
    final first = data.Group(
      id: 1,
      originX: 10,
      originY: 20,
      children: [_feature(2)],
    );
    final equal = data.Group(
      id: 1,
      originX: 10,
      originY: 20,
      children: [_feature(2)],
    );
    final changed = data.Group(
      id: 1,
      originX: 10,
      originY: 20,
      children: [_feature(3)],
    );

    expect(first, equal);
    expect(first.hashCode, equal.hashCode);
    expect(first, isNot(changed));
  });
}

data.Feature _feature(int id, {double strokeWidth = 2}) => data.Feature(
  id: id,
  originX: 10,
  originY: 20,
  width: 100,
  height: 80,
  content: {
    'type': 'rectangle',
    'style': {
      'strokeWidth': strokeWidth,
      'dash': ['solid'],
    },
  },
);
