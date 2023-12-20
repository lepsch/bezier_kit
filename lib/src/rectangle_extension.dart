import 'dart:math' hide Point;

import 'package:bezier_kit/src/point.dart';

extension RectangleExtension on Rectangle {
  Point get origin => Point(x: left.toDouble(), y: top.toDouble());
}
