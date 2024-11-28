//
//  BezierKitTests.swift
//  BezierKitTests
//
//  Created by Holmes Futrell on 10/28/16.
//  Copyright © 2016 Holmes Futrell. All rights reserved.
//

import 'package:bezier_kit/bezier_kit.dart';
import 'package:bezier_kit/src/bezier_curve_internals.dart';
import 'package:bezier_kit/src/utils.dart';
import 'package:collection/collection.dart';

class BezierKitTestHelpers {
  BezierKitTestHelpers._();

  static bool intersections(
    List<Intersection> intersections, {
    required BezierCurve betweenCurve,
    required BezierCurve andOtherCurve,
    required double areWithinTolerance,
  }) {
    for (final i in intersections) {
      final p1 = betweenCurve.point(at: i.t1);
      final p2 = andOtherCurve.point(at: i.t2);
      if ((p1 - p2).length > areWithinTolerance) {
        return false;
      }
    }
    return true;
  }

  static bool curveControlPointsEqual({
    required BezierCurve curve1,
    required BezierCurve curve2,
    required double tolerance,
  }) {
    if (curve1.order != curve2.order) return false;

    if (!IterableZip([curve1.points, curve2.points])
        .every((p) => distance(p[0], p[1]) <= tolerance)) {
      return false;
    }
    return true;
  }

  static bool shape(
    Shape s, {
    required Shape matchesShape,
    double tolerance = 1.0e-6,
  }) {
    if ((!BezierKitTestHelpers.curve(s.forward,
        matchesCurve: matchesShape.forward, tolerance: tolerance))) {
      return false;
    }
    if (!BezierKitTestHelpers.curve(s.back,
        matchesCurve: matchesShape.back, tolerance: tolerance)) {
      return false;
    }
    if (!BezierKitTestHelpers.curve(s.startcap.curve,
        matchesCurve: matchesShape.startcap.curve, tolerance: tolerance)) {
      return false;
    }
    if (!BezierKitTestHelpers.curve(s.endcap.curve,
        matchesCurve: matchesShape.endcap.curve, tolerance: tolerance)) {
      return false;
    }
    if (s.startcap.virtual != matchesShape.startcap.virtual) {
      return false;
    }
    if (s.endcap.virtual != matchesShape.endcap.virtual) {
      return false;
    }
    return true;
  }

  static bool curve(
    BezierCurve c1, {
    required BezierCurve matchesCurve,
    Interval overInterval = const Interval(start: 0.0, end: 1.0),
    double tolerance = 1.0e-5,
  }) {
    // checks if c1 over [0, 1] matches matchesCurve over [overInterval.start, overInterval.end]
    // useful for checking if splitting a curve over a given overInterval worked correctly
    const numPointsToCheck = 10;
    for (var i = 0; i < numPointsToCheck; i++) {
      final t1 = i / (numPointsToCheck - 1);
      final t2 = overInterval.start * (1.0 - t1) + overInterval.end * t1;
      if (distance(c1.point(at: t1), matchesCurve.point(at: t2)) > tolerance) {
        return false;
      }
    }
    return true;
  }

  static QuadraticCurve quadraticCurveFromPolynomials(
      List<double> f, List<double> g) {
    assert(f.length == 3 && g.length == 3);
    final curve = QuadraticCurve(
        p0: Point(x: f[2], y: g[2]),
        p1: Point(x: 0.5 * f[1] + f[2], y: 0.5 * g[1] + g[2]),
        p2: Point(x: f[0] + f[1] + f[2], y: g[0] + g[1] + g[2]));
    return curve;
  }

  static CubicCurve cubicCurveFromPolynomials(List<double> f, List<double> g) {
    assert(f.length == 4 && g.length == 4);
    // create a cubic bezier curve from two polynomials
    // the first polynomial f[0] t^3 + f[1] t^2 + f[2] t + f[3] defines x(t) for the Bezier curve
    // the second polynomial g[0] t^3 + g[1] t^2 + g[2] t + g[3] defines y(t) for the Bezier curve
    final p = Point(x: f[0], y: g[0]);
    final q = Point(x: f[1], y: g[1]);
    final r = Point(x: f[2], y: g[2]);
    final s = Point(x: f[3], y: g[3]);
    final a = s;
    final b = r / 3.0 + a;
    final c = q / 3.0 + b * 2.0 - a;
    final d = p + a - b * 3.0 + c * 3.0;
    return CubicCurve(p0: a, p1: b, p2: c, p3: d);
  }

  static bool isSatisfactoryReduceResult<A extends BezierCurve>(
      List<Subcurve<A>> result,
      {required A curve}) {
    // ensure full curve represented
    if (result.isEmpty) return false;
    if (result.first.t1 != 0) return false;
    if (result.last.t2 != 1) return false;
    // ensure contiguous ranges
    for (var i = 0; i < result.length - 1; i++) {
      if (result[i].t2 != result[i + 1].t1) return false;
    }
    // ensure that it conains the extrema
    final extrema = curve.extrema().all;
    for (final e in extrema) {
      final extremaExistsInSolution = result.any((subcurve) =>
          (subcurve.t1 - e).abs() <= reduceStepSize ||
          (subcurve.t2 - e).abs() <= reduceStepSize);
      if (!extremaExistsInSolution) return false;
    }
    // ensure that each subcurve is simple
    if (result.any(($0) => !$0.curve.simple)) return false;
    // ensure that we haven't divided things into too many curves
    for (final subcurve in result) {
      final t = subcurve.t2;
      final isNearExtrema =
          extrema.any(($0) => ($0 - t).abs() <= reduceStepSize);
      if (!isNearExtrema && t != 1.0) {
        if (curve
            .split(from: subcurve.t1, to: Utils.clamp(t + reduceStepSize, 0, 1))
            .simple) {
          return false; // we could have expanded subcurve and still had a simple result
        }
      }
    }
    return true;
  }
}
