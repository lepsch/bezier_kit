// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

void main() {
  final line = LineSegment(p0: Point(x: 1, y: 2), p1: Point(x: 3, y: 4));

  final quadratic1 = QuadraticCurve(
      p0: Point(x: 1, y: 2), p1: Point(x: 2, y: 3), p2: Point(x: 3, y: 2));

  final quadratic2 = QuadraticCurve(
      p0: Point(x: 1, y: 1), p1: Point(x: 3, y: 2), p2: Point(x: 1, y: 3));

  final cubic1 = CubicCurve(
      p0: Point(x: 1, y: 2),
      p1: Point(x: 2, y: 3),
      p2: Point(x: 3, y: 2),
      p3: Point(x: 4, y: 2));

  final cubic2 = CubicCurve(
      p0: Point(x: 2, y: 1),
      p1: Point(x: 2, y: 2),
      p2: Point(x: 3, y: 3),
      p3: Point(x: 2, y: 4));
  test("LineSegment", () {
    expect(line.flatness, 0);
    expect(line.flatnessSquared, 0);
  });

  test("QuadraticCurve", () {
    final quadratic1 = QuadraticCurve(
        p0: Point(x: 1, y: 2), p1: Point(x: 2, y: 3), p2: Point(x: 3, y: 2));
    expect(quadratic1.flatnessSquared, 0.25);
    expect(quadratic1.flatness, 0.5);
    final quadratic2 = QuadraticCurve(
        p0: Point(x: 1, y: 1), p1: Point(x: 3, y: 2), p2: Point(x: 1, y: 3));
    expect(quadratic2.flatnessSquared, 1.0);

    final quadratic3 = QuadraticCurve.fromLine(line);
    expect(quadratic3.flatnessSquared, 0.0);
  });

  test("CubicCurve", () {
    expect(cubic1.flatnessSquared, 9.0 / 16.0);
    expect(cubic2.flatnessSquared, 9.0 / 16.0);
    expect(cubic1.flatness, 3.0 / 4.0);
    expect(cubic2.flatness, 3.0 / 4.0);
    expect(CubicCurve.fromQuadratic(quadratic1).flatnessSquared, 0.25);
    expect(CubicCurve.fromQuadratic(quadratic2).flatnessSquared, 1.0);
    expect(CubicCurve.fromLine(line).flatnessSquared, 0.0);
  });
}
