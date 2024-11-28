// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

void main() {
  test("LineSegmentImplicitization", () {
    final lineSegment =
        LineSegment(p0: Point(x: 1, y: 2), p1: Point(x: 4, y: 3));
    final implicitLine = lineSegment.implicitPolynomial;
    expect(implicitLine.valueAt(lineSegment.startingPoint), 0);
    expect(implicitLine.valueAt(lineSegment.endingPoint), 0);
    expect(implicitLine.valueAt(lineSegment.point(at: 0.25)), 0);
    expect(implicitLine.valueAt(Point(x: 0, y: 5)), 10);
    expect(implicitLine.valueAt(Point(x: 2, y: -1)), -10);
    // check the implicit line composed with a parametric line
    final otherLineSegment =
        LineSegment(p0: Point(x: 0, y: 5), p1: Point(x: 2, y: -1));
    final xPolynomial = BernsteinPolynomialN(
        coefficients: otherLineSegment.xPolynomial.coefficients);
    final yPolynomial = BernsteinPolynomialN(
        coefficients: otherLineSegment.yPolynomial.coefficients);
    final polynomialComposedWithLine =
        implicitLine.value(xPolynomial, yPolynomial);
    expect(polynomialComposedWithLine.value(at: 0), 10);
    expect(polynomialComposedWithLine.value(at: 1), -10);
  });

  test("QuadraticCurveImplicitization", () {
    final quadraticCurve = QuadraticCurve(
      p0: Point(x: 0, y: 2),
      p1: Point(x: 1, y: 0),
      p2: Point(x: 2, y: 2),
    );
    final implicitQuadratic = quadraticCurve.implicitPolynomial;
    expect(implicitQuadratic.valueAt(quadraticCurve.startingPoint), 0);
    expect(implicitQuadratic.valueAt(quadraticCurve.endingPoint), 0);
    expect(implicitQuadratic.valueAt(quadraticCurve.point(at: 0.25)), 0);
    final valueAbove = implicitQuadratic.valueAt(Point(x: 1, y: 2));
    final valueBelow = implicitQuadratic.valueAt(Point(x: 1, y: 0));
    expect(valueAbove, greaterThan(0));
    expect(valueBelow, lessThan(0));
    // check the implicit quadratic composed with an parametric quadratic
    final otherQuadratic = QuadraticCurve(
      p0: Point(x: 1, y: 2),
      p1: Point(x: 1, y: 1),
      p2: Point(x: 1, y: 0),
    );
    final polynomialComposedWithQuadratic = implicitQuadratic.value(
        otherQuadratic.xPolynomial, otherQuadratic.yPolynomial);
    expect(polynomialComposedWithQuadratic.value(at: 0), valueAbove);
    expect(polynomialComposedWithQuadratic.value(at: 0.5), 0);
    expect(polynomialComposedWithQuadratic.value(at: 1), valueBelow);
  });

  test("CubicImplicitization", () {
    final cubicCurve = CubicCurve(
      p0: Point(x: 0, y: 0),
      p1: Point(x: 1, y: 1),
      p2: Point(x: 2, y: 0),
      p3: Point(x: 3, y: 1),
    );
    final implicitCubic = cubicCurve.implicitPolynomial;
    expect(implicitCubic.valueAt(cubicCurve.startingPoint), 0);
    expect(implicitCubic.valueAt(cubicCurve.endingPoint), 0);
    expect(implicitCubic.valueAt(cubicCurve.point(at: 0.25)), 0);
    final valueAbove = implicitCubic.valueAt(Point(x: 1, y: 1));
    final valueBelow = implicitCubic.valueAt(Point(x: 2, y: 0));
    expect(valueAbove, greaterThan(0));
    expect(valueBelow, lessThan(0));
    // check the implicit quadratic composed with a parametric line
    final lineSegment =
        LineSegment(p0: Point(x: 1, y: 1), p1: Point(x: 2, y: 0));
    final polynomialComposedWithLineSegment =
        implicitCubic.value(lineSegment.xPolynomial, lineSegment.yPolynomial);
    expect(polynomialComposedWithLineSegment.value(at: 0), valueAbove);
    expect(polynomialComposedWithLineSegment.value(at: 1), valueBelow);
    expect(polynomialComposedWithLineSegment.value(at: 0.5), 0);
  });
}
