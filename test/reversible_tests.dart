// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

void main() {
  final lineSegment = LineSegment(p0: Point(x: 3, y: 5), p1: Point(x: 6, y: 7));
  final quadraticCurve = QuadraticCurve(
      p0: Point(x: 6, y: 7), p1: Point(x: 7, y: 5), p2: Point(x: 6, y: 3));
  final cubicCurve = CubicCurve(
      p0: Point(x: 6, y: 3),
      p1: Point(x: 5, y: 2),
      p2: Point(x: 4, y: 3),
      p3: Point(x: 3, y: 5));
  final expectedReversedLineSegment =
      LineSegment(p0: Point(x: 6, y: 7), p1: Point(x: 3, y: 5));
  final expectedReversedQuadraticCurve = QuadraticCurve(
      p0: Point(x: 6, y: 3), p1: Point(x: 7, y: 5), p2: Point(x: 6, y: 7));
  final expectedReversedCubicCurve = CubicCurve(
      p0: Point(x: 3, y: 5),
      p1: Point(x: 4, y: 3),
      p2: Point(x: 5, y: 2),
      p3: Point(x: 6, y: 3));

  test("ReversibleLineSegment", () {
    expect(lineSegment.reversed(), expectedReversedLineSegment);
  });

  test("ReversibleQuadraticCurve", () {
    expect(quadraticCurve.reversed(), expectedReversedQuadraticCurve);
  });

  test("ReversibleCubicCurve", () {
    expect(cubicCurve.reversed(), expectedReversedCubicCurve);
  });

  test("ReversiblePathComponent", () {
    final component =
        PathComponent(curves: [lineSegment, quadraticCurve, cubicCurve]);
    final expectedReversedComponent = PathComponent(curves: [
      expectedReversedCubicCurve,
      expectedReversedQuadraticCurve,
      expectedReversedLineSegment
    ]);
    expect(component.reversed(), expectedReversedComponent);
  });

  test("ReversiblePath", () {
    final component1 = PathComponent(
        curve: LineSegment(p0: Point(x: 1, y: 2), p1: Point(x: 3, y: 4)));
    final component2 = PathComponent(
        curve: LineSegment(p0: Point(x: 1, y: -2), p1: Point(x: 3, y: 5)));
    final path = Path(components: [component1, component2]);
    final reversedComponent1 = PathComponent(
        curve: LineSegment(p0: Point(x: 3, y: 4), p1: Point(x: 1, y: 2)));
    final reversedComponent2 = PathComponent(
        curve: LineSegment(p0: Point(x: 3, y: 5), p1: Point(x: 1, y: -2)));
    final expectedRerversedPath =
        Path(components: [reversedComponent1, reversedComponent2]);
    expect(path.reversed(), expectedRerversedPath);
  });
}
