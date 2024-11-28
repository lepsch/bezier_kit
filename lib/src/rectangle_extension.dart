// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'dart:math' hide Point;

import 'package:bezier_kit/src/point.dart';

extension RectangleExtension on Rectangle {
  Point get origin => Point(x: left.toDouble(), y: top.toDouble());
}
