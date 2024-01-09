//
//  PolynomialTests.swift
//  BezierKit
//
//  Created by Holmes Futrell on 5/15/20.
//  Copyright © 2020 Holmes Futrell. All rights reserved.
//

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

void main() {
  const accuracy = 1.0e-5;

  test("Evaluation", () {
    final point = BernsteinPolynomial0(b0: 3.0);
    expect(point.reduce(a1: 1, a2: 2), 0);
    expect(point.value(at: 0), 3);
    expect(point.value(at: 0.5), 3);
    expect(point.value(at: 1), 3);
    expect(point.derivative, BernsteinPolynomial0(b0: 0.0));
    expect(point.distinctAnalyticalRoots(between: 0, and: 1), []);
    expect(point.coefficients, [3.0]);

    final line = BernsteinPolynomial1(b0: 2.0, b1: 4.0);
    expect(line.value(at: 0), 2);
    expect(line.value(at: 0.5), 3);
    expect(line.value(at: 1), 4);
    expect(line.derivative, BernsteinPolynomial0(b0: 2));
    expect(line.distinctAnalyticalRoots(between: -2, and: 1), [-1]);
    expect(line.distinctAnalyticalRoots(between: 0, and: 1), []);
    expect(line.coefficients, [2, 4]);

    final quad = BernsteinPolynomial2(b0: -1, b1: 1.0, b2: 0.0);
    expect(quad.value(at: 0), -1);
    expect(quad.value(at: 0.5), 0.25);
    expect(quad.value(at: 1), 0);
    expect(quad.derivative, BernsteinPolynomial1(b0: 4, b1: -2));
    expect(quad.coefficients, [-1, 1, 0]);
  });

  test("Degree1", () {
    final polynomial = BernsteinPolynomial1(b0: -3, b1: 2);
    final roots = findDistinctRoots(of: polynomial, between: -1, and: 1);
    expect(roots.length, 1);
    expect(roots[0], closeTo(0.6, accuracy));
  });

  test("Degree2", () {
    final polynomial = BernsteinPolynomial2(b0: -5, b1: -6, b2: -4);
    final roots = findDistinctRoots(of: polynomial, between: -10, and: 10);
    expect(roots[0], closeTo(-1, accuracy));
    expect(roots[1], closeTo(1.0 + 2.0 / 3.0, accuracy));
  });

  test("Degree3", () {
    // x^3 - 6x^2 + 11x - 6
    final polynomial =
        BernsteinPolynomial3(b0: -6, b1: -7.0 / 3.0, b2: -2.0 / 3.0, b3: 0);
    expect(polynomial.coefficients, [-6, -7.0 / 3.0, -2.0 / 3.0, 0.0]);
    final roots = findDistinctRoots(of: polynomial, between: 0, and: 4);
    expect(roots[0], closeTo(1, accuracy));
    expect(roots[1], closeTo(2, accuracy));
    expect(roots[2], closeTo(3, accuracy));
  });

  test("Degree3RepeatedRoot1", () {
    // x^3 - 4x^2 + 5x - 2
    // repeated root at x = 1
    final polynomial =
        BernsteinPolynomial3(b0: -2, b1: -1.0 / 3.0, b2: 0, b3: 0);
    final roots = findDistinctRoots(of: polynomial, between: -1, and: 3);
    expect(roots[0], closeTo(1, accuracy));
    expect(roots[1], closeTo(2, accuracy));
  });

//    test("Degree3RootExactlyZero", () {
//        // root is exactly t = 0 (at the start of unit interval),
//        // so may be accidentally discarded due to numerical precision
//        final polynomial = BernsteinPolynomial3(b0: 0, b1: 96, b2: -24, b3: -36);
//        final roots = findRoots(of: polynomial, between: 0, and: 1);
//        expect(roots.length, 2);
//        expect(roots[0], 0.0);
//        expect(roots[1], 2.0 / 3.0, accuracy: accuracy);
//    });

  test("Degree4", () {
    // x^4 - 2.44x^2 + 1.44
    final polynomial = BernsteinPolynomial4(
        b0: 1.44, b1: 1.44, b2: 1.44 - 1.22 / 3, b3: 0.22, b4: 0);
    expect(polynomial.coefficients, [1.44, 1.44, 1.44 - 1.22 / 3, 0.22, 0]);
    final roots = findDistinctRoots(of: polynomial, between: -2, and: 2);
    expect(roots[0], closeTo(-1.2, accuracy));
    expect(roots[1], closeTo(-1, accuracy));
    expect(roots[2], closeTo(1, accuracy));
    expect(roots[3], closeTo(1.2, accuracy));
  });

  test("Degree4RepeatedRoots", () {
    // x^4 - 2x^2 + 1
    final polynomial =
        BernsteinPolynomial4(b0: 1, b1: 1, b2: 2.0 / 3.0, b3: 0, b4: 0);
    final roots = findDistinctRoots(of: polynomial, between: -2, and: 2);
    expect(roots.length, 2);
    expect(roots[0], closeTo(-1, accuracy));
    expect(roots[1], closeTo(1, accuracy));
  });

  test("Degree5", () {
    // 0.2x^5 - 0.813333x^3 - 8.56x
    final polynomial = BernsteinPolynomial5(
        b0: 0,
        b1: -1.712,
        b2: -3.424,
        b3: -5.2173333,
        b4: -7.1733332,
        b5: -9.173333);
    expect(polynomial.coefficients,
        [0, -1.712, -3.424, -5.2173333, -7.1733332, -9.173333]);
    final roots = findDistinctRoots(of: polynomial, between: -4, and: 4);
    expect(roots[0], closeTo(-2.9806382, accuracy));
    expect(roots[1], closeTo(0, accuracy));
    expect(roots[2], closeTo(2.9806382, accuracy));
  });

  test("Degree4RealWorldIssue", () {
    final polynomial = BernsteinPolynomial4(
        b0: 1819945.4373168945,
        b1: -3353335.8194732666,
        b2: 3712712.6330566406,
        b3: -2836657.1703338623,
        b4: 2483314.5947265625);
    final roots = findDistinctRootsInUnitInterval(of: polynomial);
    expect(roots.length, 2);
    expect(roots[0], closeTo(0.15977874432923783, 1.0e-5));
    expect(roots[1], closeTo(0.407811682610126, 1.0e-5));
  });

  test("DegreeN", () {
    // 2x^2 + 2x + 1
    final polynomial = BernsteinPolynomialN(coefficients: [1, 2, 5]);
    expect(polynomial.derivative, BernsteinPolynomialN(coefficients: [2, 6]));
    expect(
        polynomial.reversed(), BernsteinPolynomialN(coefficients: [5, 2, 1]));
    // some edge cases
    expect(BernsteinPolynomialN(coefficients: [42]).split(from: 0.1, to: 0.9),
        BernsteinPolynomialN(coefficients: [42]));
    expect(polynomial.split(from: 1, to: 0), polynomial.reversed());
  });

  test("DegreeNRealWorldIssue", () {
    // this input would cause a stack overflow if the division step of the interval
    // occurred before checking the interval's size
    // the equation has 1st, 2nd, 3rd, and 4th derivative equal to zero
    // which means that only a small portion of the interval can be clipped
    // off. This means the code always takes the divide and conquer path.
    const accuracy = 1.0e-5;
    final polynomial = BernsteinPolynomialN(coefficients: [0, 0, 0, 0, 0, -1]);
    final configuration = RootFindingConfiguration(errorThreshold: accuracy);
    final roots = polynomial.distinctRealRootsInUnitInterval(
        configuration: configuration);
    expect(roots.length, 1);
    expect(roots[0], closeTo(0, accuracy));
  });
}
