// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'dart:math';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

void main() {
  test("Operators", () {
    final p1 = Point(x: 1.25, y: 2.0);
    final p2 = Point(x: -3.0, y: 4.5);
    expect(p1 + p2, Point(x: -1.75, y: 6.5));
    expect(p1 - p2, Point(x: 4.25, y: -2.5));
    expect(p1 * 2.0, Point(x: 2.5, y: 4.0));
    expect(p2 / 0.5, Point(x: -6.0, y: 9.0));
    expect(-p2, Point(x: 3.0, y: -4.5));
    expect(p1[0], 1.25);
    expect(p1[1], 2.0);

    var p3 = Point(x: 5.0, y: 3.0);
    p3 += Point(x: 1.0, y: -2.0);
    expect(p3, Point(x: 6.0, y: 1.0));

    var p4 = Point(x: 2.0, y: 9.0);
    p4 -= Point(x: 2.0, y: 8.0);
    expect(p4, Point(x: 0.0, y: 1.0));

    var p5 = Point(x: 9.25, y: 4.25);
    p5 = p5.copyWith(at: (0, 1.25));
    p5 = p5.copyWith(at: (1, 6.25));
    expect(p5[0], 1.25);
    expect(p5[1], 6.25);
  });

  test("Functions", () {
    final a = Point(x: 3, y: 4);
    final b = Point(x: -1, y: 5);
    expect(a.dot(b), 17);
    expect(a.cross(b), 19);
    expect(a.length, 5);
    expect(a.lengthSquared, 25);
    expect(a.normalize(), Point(x: 3.0 / 5.0, y: 4.0 / 5.0));
    expect(distance(a, b), sqrt(17.0));
    expect(distanceSquared(a, b), 17.0);
    expect(a.perpendicular, Point(x: -4, y: 3));
  });
}
