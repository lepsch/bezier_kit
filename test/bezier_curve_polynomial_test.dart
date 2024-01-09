//
//  BezierCurve+PolynomialTests.swift
//  BezierKit
//
//  Created by Holmes Futrell on 1/22/21.
//  Copyright © 2021 Holmes Futrell. All rights reserved.
//

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

import 'bezier_kit_test_helpers.dart';

void main() {
  test("PolynomialLineSegment", () {
    final lineSegment =
        LineSegment(p0: Point(x: 3, y: 4), p1: Point(x: 5, y: 6));
    expect(lineSegment.xPolynomial, BernsteinPolynomial1(b0: 3, b1: 5));
    expect(lineSegment.yPolynomial, BernsteinPolynomial1(b0: 4, b1: 6));
  });

  test("PolynomialQuadratic", () {
    final quadratic = QuadraticCurve(
      p0: Point(x: 1, y: 0),
      p1: Point(x: 2, y: -2),
      p2: Point(x: 3, y: -1),
    );
    expect(quadratic.xPolynomial, BernsteinPolynomial2(b0: 1, b1: 2, b2: 3));
    expect(quadratic.yPolynomial, BernsteinPolynomial2(b0: 0, b1: -2, b2: -1));
  });

  test("PolynomialCubic", () {
    final cubic = CubicCurve(
      p0: Point(x: 1, y: 0),
      p1: Point(x: 2, y: 2),
      p2: Point(x: 3, y: 1),
      p3: Point(x: 4, y: -1),
    );
    expect(cubic.xPolynomial, BernsteinPolynomial3(b0: 1, b1: 2, b2: 3, b3: 4));
    expect(
        cubic.yPolynomial, BernsteinPolynomial3(b0: 0, b1: 2, b2: 1, b3: -1));
  });

  test("ExtremaLine", () {
    final l1 =
        LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 4.0, y: 6.0));
    {
      final (:x, :y, :all) = l1.extrema();
      expect(x.isEmpty, isTrue);
      expect(y.isEmpty, isTrue);
      expect(all.isEmpty, isTrue);
    }

    final l2 =
        LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 4.0, y: 2.0));
    {
      final (:x, :y, :all) = l2.extrema();
      expect(x.isEmpty, isTrue);
      expect(y.isEmpty, isTrue);
      expect(all.isEmpty, isTrue);
    }
  });

  test("ExtremaQuadratic", () {
    // f(t) = 4t^2 - 2t + 1, which has a local minimum at t = 0.25;
    final f = <double>[4, -2, 1];
    // g(t) = t^2 -4t + 4, which has a local minimum at t = 2 (outside parameter range);
    final g = <double>[1, -4, 4];
    final q = BezierKitTestHelpers.quadraticCurveFromPolynomials(f, g);
    final (:x, :y, :all) = q.extrema();
    expect(all.length, 1);
    expect(all[0], 0.25);
    expect(x.length, 1);
    expect(x[0], 0.25);
    expect(y.isEmpty, isTrue);
  });

  test("ExtremaCubic", () {
    // f(t) = t^3 - t^2, which has two local minimum at t=0, t=2/3 and an inflection point t=1/3;
    final f = <double>[1, -1, 0, 0];
    // g(t) = 3t^2 - 2t, which has a local minimum at t=1/3;
    final g = <double>[0, 3, -2, 0];
    final c = BezierKitTestHelpers.cubicCurveFromPolynomials(f, g);
    final (:x, :y, :all) = c.extrema();
    expect(all.length, 3);
    expect(all[0], 0.0);
    expect(all[1], 1.0 / 3.0);
    expect(all[2], 2.0 / 3.0);
    expect(x[0], 0.0);
    expect(x[1], 1.0 / 3.0);
    expect(x[2], 2.0 / 3.0);
    expect(y.length, 1);
    expect(y[0], 1.0 / 3.0);
  });
}
