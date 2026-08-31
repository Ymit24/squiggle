import 'dart:ui';

Map<String, dynamic> offsetToJson(Offset value) => {
  'x': value.dx,
  'y': value.dy,
};

Offset offsetFromJson(Map<String, dynamic> json) =>
    Offset((json['x'] as num).toDouble(), (json['y'] as num).toDouble());

Map<String, dynamic> sizeToJson(Size value) => {
  'width': value.width,
  'height': value.height,
};

Size sizeFromJson(Map<String, dynamic> json) =>
    Size((json['width'] as num).toDouble(), (json['height'] as num).toDouble());

Color colorFromJson(Object? value) => Color(value as int);
