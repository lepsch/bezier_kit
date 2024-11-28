// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'dart:math';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:bezier_kit/src/bezier_curve_internals.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import 'bezier_kit_test_helpers.dart';

void main() {
  test("InitializerArray", () {
    final c = CubicCurve.fromList([
      Point(x: 1.0, y: 1.0),
      Point(x: 3.0, y: 2.0),
      Point(x: 5.0, y: 3.0),
      Point(x: 7.0, y: 4.0),
    ]);
    expect(c.p0, Point(x: 1.0, y: 1.0));
    expect(c.p1, Point(x: 3.0, y: 2.0));
    expect(c.p2, Point(x: 5.0, y: 3.0));
    expect(c.p3, Point(x: 7.0, y: 4.0));
    expect(c.startingPoint, Point(x: 1.0, y: 1.0));
    expect(c.endingPoint, Point(x: 7.0, y: 4.0));
  });

  test("InitializerIndividualPoints", () {
    final c = CubicCurve(
        p0: Point(x: 1.0, y: 1.0),
        p1: Point(x: 3.0, y: 2.0),
        p2: Point(x: 5.0, y: 3.0),
        p3: Point(x: 7.0, y: 4.0));
    expect(c.p0, Point(x: 1.0, y: 1.0));
    expect(c.p1, Point(x: 3.0, y: 2.0));
    expect(c.p2, Point(x: 5.0, y: 3.0));
    expect(c.p3, Point(x: 7.0, y: 4.0));
    expect(c.startingPoint, Point(x: 1.0, y: 1.0));
    expect(c.endingPoint, Point(x: 7.0, y: 4.0));
  });

  test("InitializerLineSegment", () {
    final l = LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 2.0, y: 3.0));
    final c = CubicCurve.fromLine(l);
    expect(c.p0, l.p0);
    const oneThird = 1.0 / 3.0;
    const twoThirds = 2.0 / 3.0;
    expect(c.p1, l.p0 * twoThirds + l.p1 * oneThird);
    expect(c.p2, l.p0 * oneThird + l.p1 * twoThirds);
    expect(c.p3, l.p1);
  });

  test("InitializerQuadratic", () {
    final q = QuadraticCurve(
        p0: Point(x: 1.0, y: 1.0),
        p1: Point(x: 2.0, y: 2.0),
        p2: Point(x: 3.0, y: 1.0));
    final c = CubicCurve.fromQuadratic(q);
    const epsilon = 1.0e-6;
    // check for equality via lookup table
    const steps = 10;
    for (final [p1, p2] in IterableZip(
        [q.lookupTable(steps: steps), c.lookupTable(steps: steps)])) {
      expect((p1 - p2).length, lessThan(epsilon));
    }
    // check for proper values in control points
    const fiveThirds = 5.0 / 3.0;
    const sevenThirds = 7.0 / 3.0;
    expect((c.p0 - Point(x: 1.0, y: 1.0)).length, lessThan(epsilon));
    expect(
        (c.p1 - Point(x: fiveThirds, y: fiveThirds)).length, lessThan(epsilon));
    expect((c.p2 - Point(x: sevenThirds, y: fiveThirds)).length,
        lessThan(epsilon));
    expect((c.p3 - Point(x: 3.0, y: 1.0)).length, lessThan(epsilon));
  });

  test("InitializerStartEndMidTStrutLength", () {
    const epsilon = 0.00001;

    final start = Point(x: 1.0, y: 1.0);
    final mid = Point(x: 2.0, y: 2.0);
    final end = Point(x: 4.0, y: 0.0);

    // first test passing without passing a t or d paramter
    var c = CubicCurve.fromPoints3(start: start, end: end, mid: mid);
    expect(c.point(at: 0.0), start);
    expect((c.point(at: 0.5) - mid).length, lessThan(epsilon));
    expect(c.point(at: 1.0), end);

    // now test passing in a manual t and length d
    const t = 7.0 / 9.0;
    const d = 1.5;
    c = CubicCurve.fromPoints3(start: start, end: end, mid: mid, t: t, d: d);
    expect(c.point(at: 0.0), start);
    expect((c.point(at: t) - mid).length, lessThan(epsilon));
    expect(c.point(at: 1.0), end);
    // make sure our solution has the proper strut length
    final e1 = c.hull(t)[7];
    final e2 = c.hull(t)[8];
    final l = (e2 - e1).length;
    expect(l, closeTo(d * 1.0 / t, epsilon));
  });

  test("BasicProperties", () {
    final c = CubicCurve(
        p0: Point(x: 1.0, y: 1.0),
        p1: Point(x: 3.0, y: 2.0),
        p2: Point(x: 4.0, y: 2.0),
        p3: Point(x: 6.0, y: 1.0));
    expect(c.simple, isTrue);
    expect(c.order, 3);
    expect(c.startingPoint, Point(x: 1.0, y: 1.0));
    expect(c.endingPoint, Point(x: 6.0, y: 1.0));
  });

  test("SetStartEndPoints", () {
    final c = CubicCurve(
        p0: Point(x: 5.0, y: 6.0),
        p1: Point(x: 6.0, y: 5.0),
        p2: Point(x: 7.0, y: 8.0),
        p3: Point(x: 8.0, y: 7.0));
    c.startingPoint = Point(x: 4.0, y: 5.0);
    expect(c.p0, c.startingPoint);
    expect(c.startingPoint, Point(x: 4.0, y: 5.0));
    c.endingPoint = Point(x: 9.0, y: 8.0);
    expect(c.p3, c.endingPoint);
    expect(c.endingPoint, Point(x: 9.0, y: 8.0));
  });

  test("Simple", () {
    // create a simple cubic curve (very simple, because it's equal to a line segment)
    final c1 = CubicCurve(
        p0: Point(x: 1.0, y: 1.0),
        p1: Point(x: 2.0, y: 2.0),
        p2: Point(x: 3.0, y: 3.0),
        p3: Point(x: 4.0, y: 4.0));
    expect(c1.simple, isTrue);
    // a non-trivial example of a simple curve -- almost a straight line
    final c2 = CubicCurve(
        p0: Point(x: 1.0, y: 1.0),
        p1: Point(x: 2.0, y: 1.05),
        p2: Point(x: 3.0, y: 1.05),
        p3: Point(x: 4.0, y: 1.0));
    expect(c2.simple, isTrue);
    // non-simple curve, control points fall on different sides of the baseline
    final c3 = CubicCurve(
        p0: Point(x: 1.0, y: 1.0),
        p1: Point(x: 2.0, y: 1.05),
        p2: Point(x: 3.0, y: 0.95),
        p3: Point(x: 4.0, y: 1.0));
    expect(c3.simple, isFalse);
    // non-simple curve, angle between end point normals > 60 degrees (pi/3) -- in this case the angle is 45 degrees (pi/2)
    final c4 = CubicCurve(
        p0: Point(x: 1.0, y: 1.0),
        p1: Point(x: 1.0, y: 2.0),
        p2: Point(x: 2.0, y: 3.0),
        p3: Point(x: 3.0, y: 3.0));
    expect(c4.simple, isFalse);
    // ensure that points-as-cubics pass (otherwise callers might try to subdivide them further)
    final p = Point(x: 1.234, y: 5.689);
    final c5 = CubicCurve(p0: p, p1: p, p2: p, p3: p);
    expect(c5.simple, isTrue);
  });

  test("Derivative", () {
    const epsilon = 0.00001;
    final p0 = Point(x: 1.0, y: 1.0);
    final p1 = Point(x: 3.0, y: 2.0);
    final p2 = Point(x: 5.0, y: 2.0);
    final p3 = Point(x: 7.0, y: 1.0);
    final c = CubicCurve(p0: p0, p1: p1, p2: p2, p3: p3);
    expect(distance(c.derivative(at: 0.0), (p1 - p0) * 3.0), lessThan(epsilon));
    expect(distance(c.derivative(at: 0.5), Point(x: 6.0, y: 0.0)),
        lessThan(epsilon));
    expect(distance(c.derivative(at: 1.0), (p3 - p2) * 3.0), lessThan(epsilon));
  });

  test("SplitFromTo", () {
    const epsilon = 0.00001;
    final c = CubicCurve(
        p0: Point(x: 1.0, y: 1.0),
        p1: Point(x: 3.0, y: 2.0),
        p2: Point(x: 4.0, y: 2.0),
        p3: Point(x: 6.0, y: 1.0));
    const t1 = 1.0 / 3.0;
    const t2 = 2.0 / 3.0;
    final s = c.split(from: t1, to: t2);
    expect(
        BezierKitTestHelpers.curve(s,
            matchesCurve: c,
            overInterval: Interval(start: t1, end: t2),
            tolerance: epsilon),
        isTrue);
  });

  test("SplitFromToSameLocation", () {
    // when splitting with same `from` and `to` parameter, we should get a point back.
    // but if we aren't careful round-off error will give us something slightly different.
    final cubic = CubicCurve(
        p0: Point(x: 0.041630344771878214, y: 0.45449244472862915),
        p1: Point(x: 0.8348172181669149, y: 0.33598603014520023),
        p2: Point(x: 0.5654894035661364, y: 0.001766912391744313),
        p3: Point(x: 0.18758951699996018, y: 0.9904340799376641));
    const t = 0.920134;
    final result = cubic.split(from: t, to: t);
    final expectedPoint = cubic.point(at: t);
    expect(result.p0, expectedPoint);
    expect(result.p1, expectedPoint);
    expect(result.p2, expectedPoint);
    expect(result.p3, expectedPoint);
  });

  test("SplitContinuous", () {
    // if I call split(from: a, to: b) and split(from: b, to: c)
    // then the two subcurves should be continuous. However, from lack of precision that might not happen unless we are careful!
    const a = 0.65472931005125345;
    const b = 0.73653845530600293;
    const c = 1.0;
    final curve = CubicCurve(
        p0: Point(x: 286.8966218087201, y: 69.11759651620365),
        p1: Point(x: 285.7845542083973, y: 69.84970485476842),
        p2: Point(x: 284.6698515652002, y: 70.60114443784359),
        p3: Point(x: 283.5560914830615, y: 71.34238971309229));
    final split1 = curve.split(from: a, to: b);
    final split2 = curve.split(from: b, to: c);
    expect(split1.endingPoint, split2.startingPoint);

    final (:left, :right) = curve.splitAt(b);
    expect(left.endingPoint, right.startingPoint);

    expect(curve.split(from: 1, to: 0), curve.reversed());
    expect(
        BezierKitTestHelpers.curveControlPointsEqual(
            curve1: curve.split(from: b, to: a),
            curve2: curve.split(from: a, to: b).reversed(),
            tolerance: 1.0e-5),
        isTrue);
  });

  test("SplitAt", () {
    const epsilon = 0.00001;
    final c = CubicCurve(
        p0: Point(x: 1.0, y: 1.0),
        p1: Point(x: 3.0, y: 2.0),
        p2: Point(x: 4.0, y: 2.0),
        p3: Point(x: 6.0, y: 1.0));
    const t = 0.25;
    final (:left, :right) = c.splitAt(t);
    expect(
        BezierKitTestHelpers.curve(left,
            matchesCurve: c,
            overInterval: Interval(start: 0, end: t),
            tolerance: epsilon),
        isTrue);
    expect(
        BezierKitTestHelpers.curve(right,
            matchesCurve: c,
            overInterval: Interval(start: t, end: 1),
            tolerance: epsilon),
        isTrue);
  });

  test("BoundingBox", () {
    // hits codepath where midpoint pushes up y coordinate of bounding box
    final c1 = CubicCurve(
        p0: Point(x: 1.0, y: 1.0),
        p1: Point(x: 3.0, y: 2.0),
        p2: Point(x: 5.0, y: 2.0),
        p3: Point(x: 7.0, y: 1.0));
    final expectedBoundingBox1 = BoundingBox(
      p1: Point(x: 1.0, y: 1.0),
      p2: Point(x: 7.0, y: 1.75),
    );
    expect(c1.boundingBox, expectedBoundingBox1);
    // hits codepath where midpoint pushes down x coordinate of bounding box
    final c2 = CubicCurve(
        p0: Point(x: 1.0, y: 1.0),
        p1: Point(x: -3.0, y: 2.0),
        p2: Point(x: -3.0, y: 3.0),
        p3: Point(x: 1.0, y: 4.0));
    final expectedBoundingBox2 = BoundingBox(
      p1: Point(x: -2.0, y: 1.0),
      p2: Point(x: 1.0, y: 4.0),
    );
    expect(c2.boundingBox, expectedBoundingBox2);
    // this one is designed to hit an unusual codepath: c3 has an extrema that would expand the bounding box,
    // but it falls outside of the range 0<=t<=1, and therefore must be excluded
    final c3 = c1.splitAt(0.25).left;
    final expectedBoundingBox3 = BoundingBox(
      p1: Point(x: 1.0, y: 1.0),
      p2: Point(x: 2.5, y: 1.5625),
    );
    expect(c3.boundingBox, expectedBoundingBox3);

    // bounding box of a degenerate curve made out of a single point
    final p = Point(x: 1.234, y: 2.394);
    final degenerate = CubicCurve(p0: p, p1: p, p2: p, p3: p);
    expect(degenerate.boundingBox, BoundingBox(p1: p, p2: p));
  });

  test("Compute", () {
    final c = CubicCurve(
      p0: Point(x: 3.0, y: 5.0),
      p1: Point(x: 4.0, y: 6.0),
      p2: Point(x: 6.0, y: 6.0),
      p3: Point(x: 7.0, y: 5.0),
    );
    expect(c.point(at: 0.0), Point(x: 3.0, y: 5.0));
    expect(c.point(at: 0.5), Point(x: 5.0, y: 5.75));
    expect(c.point(at: 1.0), Point(x: 7.0, y: 5.0));
  });

  // - methods for which default implementations provided by protocol

  test("Length", () {
    const epsilon = 0.00001;
    final c1 = CubicCurve(
        p0: Point(x: 1.0, y: 2.0),
        p1: Point(x: 7.0 / 3.0, y: 3.0),
        p2: Point(x: 11.0 / 3.0, y: 4.0),
        p3: Point(
            x: 5.0,
            y: 5.0)); // represents a straight line of length 5 -- most curves won't have an easy reference solution
    expect(c1.length(), closeTo(5.0, epsilon));
  });

  test("Project", () {
    const epsilon = 1.0e-5;
    // test a cubic
    final c = CubicCurve(
        p0: Point(x: 1.0, y: 1.0),
        p1: Point(x: 2.0, y: 2.0),
        p2: Point(x: 4.0, y: 2.0),
        p3: Point(x: 5.0, y: 1.0));
    final p4 = c.project(Point(x: 0.95, y: 1.05)); // should project to p0;
    expect(p4.point, Point(x: 1.0, y: 1.0));
    expect(p4.t, 0.0);
    final p5 = c.project(Point(x: 5.05, y: 1.05)); // should project to p3;
    expect(p5.point, Point(x: 5.0, y: 1.0));
    expect(p5.t, 1.0);
    final p6 =
        c.project(Point(x: 3.0, y: 2.0)); // should project to center of curve;
    expect(p6.point, Point(x: 3.0, y: 1.75));
    expect(p6.t, 0.5);

    const t = 0.831211;
    final pointToProject = c.point(at: t) + c.normal(at: t);
    final expectedAnswer = c.point(at: t);
    final p7 = c.project(
        pointToProject); // should project back to (roughly) c.compute(0.831211)
    expect(distance(p7.point, expectedAnswer), lessThan(epsilon));
    expect(p7.t, closeTo(t, epsilon));
  });

  test("ProjectRealWorldIssue", () {
    // this issue occurred when using the Bezier Clipping approach
    // to root solving due to some kind of issue with the limits of precision
    // one idea is to look at the .split() functions and make sure there are no cracks
    // another idea is to look at the start and end points and actually require the call to produce a solution
    const epsilon = 1.0e-5;
    final c = CubicCurve(
      p0: Point(x: 100, y: 25),
      p1: Point(x: 10, y: 90),
      p2: Point(x: 50, y: 185),
      p3: Point(x: 170, y: 175),
    );
    final t = c.project(Point(x: 8.3359375, y: -49.10546875)).t;
    expect(t, closeTo(0.0575491, epsilon));
  });

// TODO: we still have some missing unit tests for CubicCurve's API entry points

//    test("Hull", () {
//        final l = LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 3.0, y: 4.0));
//        final h = l.hull(0.5);
//        XCTAssert(h.length == 3)
//        expect(h[0], Point(x: 1.0, y: 2.0));
//        expect(h[1], Point(x: 3.0, y: 4.0));
//        expect(h[2], Point(x: 2.0, y: 3.0));
//    }
//
//    test("Normal", () {
//        final l = LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 5.0, y: 6.0));
//        final n1 = l.normal(0.0);
//        final n2 = l.normal(0.5);
//        final n3 = l.normal(1.0);
//        expect(n1, Point(x: -1.0 / sqrt(2.0), y: 1.0 / sqrt(2.0)));
//        expect(n1, n2);
//        expect(n2, n3);
//    });

  test("NormalDegenerate", () {
    const maxError = 0.01;
    final a = Point(x: 2, y: 3);
    final b = Point(x: 3, y: 3);
    final c = Point(x: 4, y: 4);
    final cubic1 = CubicCurve(p0: a, p1: a, p2: b, p3: c);
    expect(
        distance(cubic1.normal(at: 0), Point(x: 0, y: 1)), lessThan(maxError));
    final cubic2 = CubicCurve(p0: a, p1: b, p2: c, p3: c);
    expect(
        distance(cubic2.normal(at: 1), Point(x: -sqrt(2) / 2, y: sqrt(2) / 2)),
        lessThan(maxError));
    final cubic3 = CubicCurve(p0: a, p1: a, p2: a, p3: b);
    expect(
        distance(cubic3.normal(at: 0), Point(x: 0, y: 1)), lessThan(maxError));
    final cubic4 = CubicCurve(p0: a, p1: b, p2: b, p3: b);
    expect(
        distance(cubic4.normal(at: 1), Point(x: 0, y: 1)), lessThan(maxError));
  });

  test("NormalCusp", () {
    // c has a cusp at t = 0.5, the normal vector *cannot* be defined
    final c = CubicCurve(
      p0: Point(x: 1, y: 1),
      p1: Point(x: 2, y: 2),
      p2: Point(x: 1, y: 2),
      p3: Point(x: 2, y: 1),
    );
    expect(c.derivative(at: 0.5), Point.zero);
    expect(c.normal(at: 0.5).x, isNaN);
    expect(c.normal(at: 0.5).y, isNaN);
  });

  test("Reduce", () {
    // curve with both tangents above the baseline, difference in angles just under pi / 3
    final c1 = CubicCurve(
      p0: Point(x: 0.0, y: 0.0),
      p1: Point(x: 1.0, y: 2.0),
      p2: Point(x: 2.0, y: 3.0),
      p3: Point(x: 4.0, y: 4.0),
    );
    final result1 = c1.reduce();
    expect([Subcurve(t1: 0, t2: 1, curve: c1)], result1);

    // angle between vectors is nearly pi / 2, so it must be split
    final c2 = CubicCurve(
      p0: Point(x: 0.0, y: 0.0),
      p1: Point(x: 0.0, y: 2.0),
      p2: Point(x: 2.0, y: 4.0),
      p3: Point(x: 4.0, y: 4.0),
    );
    final result2 = c2.reduce();
    expect(BezierKitTestHelpers.isSatisfactoryReduceResult(result2, curve: c2),
        isTrue);

    // ensure it works for degenerate case
    final p = Point(x: 5.3451, y: -1.2345);
    final c3 = CubicCurve(p0: p, p1: p, p2: p, p3: p);
    final result3 = c3.reduce();
    expect(BezierKitTestHelpers.isSatisfactoryReduceResult(result3, curve: c3),
        isTrue);
  });

  test("ReduceExtremaCloseby", () {
    // the x coordinates are f(t) = (t-0.5)^2 = t^2 - t + 0.25, which has a minima at t=0.5
    // the y coordinates are f(t) = 1/3t^3 - 1/2t^2 + 3/16t, which has an inflection at t=0.5
    // adding `smallValue` to one of the y coordinates gives us two extrema very close to t=0.5
    const smallValue = 1.0e-3;
    final c = BezierKitTestHelpers.cubicCurveFromPolynomials([0, 1, -1, 0.25],
        [1.0 / 3.0, (-1.0 / 2.0) + smallValue, 3.0 / 16.0, 0]);
    final result1 = c.reduce();
    expect(BezierKitTestHelpers.isSatisfactoryReduceResult(result1, curve: c),
        isTrue);
  });
//
//    //    test("ScaleDistanceFunc",  {
//    //
//    //    }
//
//    test("Intersects", () {
//        final l = LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 5.0, y: 6.0));
//        final i = l.intersects();
//        XCTAssert(i.length == 0) // lines never self-intersect
//    }
//
//    // -- MARK: - line-curve intersection tests
//
//    test("IntersectsQuadratic", () {
//        // we mostly just care that we call into the proper implementation and that the results are ordered correctly
//        // q is a quadratic where y(x) = 2 - 2(x-1)^2
//        const epsilon = 0.00001;
//        final q: QuadraticCurve = QuadraticCurve.init(p0: Point(x: 0.0, y: 0.0),
//                                                                p1: Point(x: 1.0, y: 2.0),
//                                                                p2: Point(x: 2.0, y: 0.0),
//                                                                t: 0.5)
//        final l1: LineSegment = LineSegment(p0: Point(x: -1.0, y: 1.0), p1: Point(x: 3.0, y: 1.0));
//        final l2: LineSegment = LineSegment(p0: Point(x: 3.0, y: 1.0), p1: Point(x: -1.0, y: 1.0)) // same line as l1, but reversed;
//        // the intersections for both lines occur at x = 1±sqrt(1/2)
//        final i1 = l1.intersects(curve: q);
//        final r1: double = 1.0 - sqrt(1.0 / 2.0);
//        final r2: double = 1.0 + sqrt(1.0 / 2.0);
//        expect(i1.length, 2);
//        XCTAssertEqualWithAccuracy(i1[0].t1, (r1 + 1.0) / 4.0, accuracy: epsilon)
//        XCTAssertEqualWithAccuracy(i1[0].t2, r1 / 2.0, accuracy: epsilon)
//        XCTAssert((l1.compute(i1[0].t1) - q.compute(i1[0].t2)).length ,lessThan(epsilon));
//        XCTAssertEqualWithAccuracy(i1[1].t1, (r2 + 1.0) / 4.0, accuracy: epsilon)
//        XCTAssertEqualWithAccuracy(i1[1].t2, r2 / 2.0, accuracy: epsilon)
//        XCTAssert((l1.compute(i1[1].t1) - q.compute(i1[1].t2)).length ,lessThan(epsilon));
//        // do the same thing as above but using l2
//        final i2 = l2.intersects(curve: q);
//        expect(i2.length, 2);
//        XCTAssertEqualWithAccuracy(i2[0].t1, (r1 + 1.0) / 4.0, accuracy: epsilon)
//        XCTAssertEqualWithAccuracy(i2[0].t2, r2 / 2.0, accuracy: epsilon)
//        XCTAssert((l2.compute(i2[0].t1) - q.compute(i2[0].t2)).length ,lessThan(epsilon));
//        XCTAssertEqualWithAccuracy(i2[1].t1, (r2 + 1.0) / 4.0, accuracy: epsilon)
//        XCTAssertEqualWithAccuracy(i2[1].t2, r1 / 2.0, accuracy: epsilon)
//        XCTAssert((l2.compute(i2[1].t1) - q.compute(i2[1].t2)).length ,lessThan(epsilon));
//    }
//
//    test("IntersectsCubic", () {
//        // we mostly just care that we call into the proper implementation and that the results are ordered correctly
//        const epsilon = 0.00001;
//        final c: CubicCurve = CubicCurve(p0: Point(x: -1, y: 0),
//                                                   p1: Point(x: -1, y: 1),
//                                                   p2: Point(x:  1, y: -1),
//                                                   p3: Point(x:  1, y: 0))
//        final l1: LineSegment = LineSegment(p0: Point(x: -2.0, y: 0.0), p1: Point(x: 2.0, y: 0.0));
//        final i1 = l1.intersects(curve: c);
//
//        expect(i1.length, 3);
//        XCTAssertEqualWithAccuracy(i1[0].t1, 0.25, accuracy: epsilon)
//        XCTAssertEqualWithAccuracy(i1[0].t2, 0.0, accuracy: epsilon)
//        XCTAssertEqualWithAccuracy(i1[1].t1, 0.5, accuracy: epsilon)
//        XCTAssertEqualWithAccuracy(i1[1].t2, 0.5, accuracy: epsilon)
//        XCTAssertEqualWithAccuracy(i1[2].t1, 0.75, accuracy: epsilon)
//        XCTAssertEqualWithAccuracy(i1[2].t2, 1.0, accuracy: epsilon)
//        // l2 is the same line going in the opposite direction
//        // by checking this we ensure the intersections are ordered by the line and not the cubic
//        final l2: LineSegment = LineSegment(p0: Point(x: 2.0, y: 0.0), p1: Point(x: -2.0, y: 0.0));
//        final i2 = l2.intersects(curve: c);
//        expect(i2.length, 3);
//        XCTAssertEqualWithAccuracy(i2[0].t1, 0.25, accuracy: epsilon)
//        XCTAssertEqualWithAccuracy(i2[0].t2, 1.0, accuracy: epsilon)
//        XCTAssertEqualWithAccuracy(i2[1].t1, 0.5, accuracy: epsilon)
//        XCTAssertEqualWithAccuracy(i2[1].t2, 0.5, accuracy: epsilon)
//        XCTAssertEqualWithAccuracy(i2[2].t1, 0.75, accuracy: epsilon)
//        XCTAssertEqualWithAccuracy(i2[2].t2, 0.0, accuracy: epsilon)
//    }
//

  test("IntersectionsCubicMaxIntersections", () {
    const epsilon = 1.0e-5;
    const a = 4.0;
    final c1 = CubicCurve(
      p0: Point(x: 0, y: 0),
      p1: Point(x: 0.33, y: a),
      p2: Point(x: 0.66, y: 1 - a),
      p3: Point(x: 1, y: 1),
    );
    final c2 = CubicCurve(
      p0: Point(x: 0, y: 1),
      p1: Point(x: a, y: 0.66),
      p2: Point(x: 1 - a, y: 0.33),
      p3: Point(x: 1, y: 0),
    );
    final intersections = c1.intersectionsWithCurve(c2, accuracy: epsilon);
    final expectedResults = [
      Point(x: 0.009867618966216286, y: 0.11635072599233257),
      Point(x: 0.03530531425481719, y: 0.3869680057368261),
      Point(x: 0.11629483697722519, y: 0.9898413631716166),
      Point(x: 0.38725276058371816, y: 0.9636332023660762),
      Point(x: 0.49721796591086287, y: 0.495633320355362),
      Point(x: 0.6056909589337255, y: 0.036054034343778435),
      Point(x: 0.880590710796587, y: 0.010134637339461294),
      Point(x: 0.9628624913661753, y: 0.6053986189382927),
      Point(x: 0.9895666738958517, y: 0.8806493722540778),
    ];
    expect(intersections.length, 9);
    for (var i = 0; i < intersections.length; i++) {
      expect(distance(c1.point(at: intersections[i].t1), expectedResults[i]),
          lessThan(epsilon));
      expect(distance(c2.point(at: intersections[i].t2), expectedResults[i]),
          lessThan(epsilon));
    }
  });

  test("IntersectionsCoincident", () {
    final c = CubicCurve(
      p0: Point(x: -1, y: -1),
      p1: Point(x: 0, y: 0),
      p2: Point(x: 2, y: 0),
      p3: Point(x: 3, y: -1),
    );
    expect(c.intersectionsWithCurve(c.reversed()),
        [Intersection(t1: 0, t2: 1), Intersection(t1: 1, t2: 0)],
        reason: "curves should be fully coincident with themselves.");
    // now, a tricky case, overlap from t = 1/3, to t=3/5 on the original curve
    final c1 = c.split(from: 1.0 / 3.0, to: 2.0 / 3.0);
    final c2 = c.split(from: 1.0 / 5.0, to: 3.0 / 5.0);
    const accuracy = 1.0e-4;
    // (t1: 0, t2: 1/3), (t1: 4/5, t2: 1)
    final intersections = c1.intersectionsWithCurve(c2, accuracy: accuracy);
    expect(intersections.length, 2);
    final i1 = intersections[0];
    expect(
        distance(c1.point(at: i1.t1), c2.point(at: i1.t2)), lessThan(accuracy));
    final i2 = intersections[1];
    expect(
        distance(c1.point(at: i2.t1), c2.point(at: i2.t2)), lessThan(accuracy));
  });

  test("BasicTangentIntersection", () {
    final c1 = CubicCurve(
      p0: Point(x: 0, y: 0),
      p1: Point(x: 0, y: 3),
      p2: Point(x: 6, y: 9),
      p3: Point(x: 9, y: 9),
    );
    final c2 = CubicCurve(
      p0: Point(x: 9, y: 9),
      p1: Point(x: 8, y: 9),
      p2: Point(x: 6, y: 7),
      p3: Point(x: 6, y: 6),
    );
    final expectedIntersections = [Intersection(t1: 1, t2: 0)];
    expect(
        c1.intersectionsWithCurve(c2, accuracy: 1.0e-5), expectedIntersections);
    expect(
        c1.intersectionsWithCurve(c2, accuracy: 1.0e-8), expectedIntersections);
  });

  test("RealWorldNearlyCoincidentCurvesIntersection", () {
    // these curves are nearly coincident over from c1's t = 0.278 to 1.0
    // staying roughly 0.0002 distance of eachother
    // but they do actually appear to have real interesctions also
    final c1 = CubicCurve(
      p0: Point(x: 0.9435597332840757, y: 0.16732142729460975),
      p1: Point(x: 0.6459474292317964, y: 0.22174990722896837),
      p2: Point(x: 0.3434479689753971, y: 0.2624874219291087),
      p3: Point(x: 0.036560070230819974, y: 0.28765861655756453),
    );
    final c2 = CubicCurve(
      p0: Point(x: 0.036560070230819974, y: 0.28765861655756453),
      p1: Point(x: 0.25665707912767743, y: 0.26960608118315577),
      p2: Point(x: 0.4760155370276209, y: 0.24346330678827144),
      p3: Point(x: 0.6941905032971079, y: 0.20928332065477662),
    );
    final intersections = c1.intersectionsWithCurve(c2, accuracy: 1.0e-5);
    expect(intersections.length, 2);
    expect(intersections[0].t1, closeTo(0.73204, 1.0e-5));
    expect(intersections[0].t2, closeTo(0.37268, 1.0e-5));
    expect(intersections[1].t1, 1);
    expect(intersections[1].t2, 0);
  });

  test("IntersectionsCubicButActuallyLinear", () {
    // this test presents a challenge for an implicitization based approach
    // if the linearity of the so-called "cubic" is not detected
    // the implicit equation will be f(x, y) = 0 and no intersections will be found
    const epsilon = 1.0e-5;
    final cubicButActuallyLinear = CubicCurve(
      p0: Point(x: 3, y: 2),
      p1: Point(x: 4, y: 3),
      p2: Point(x: 5, y: 4),
      p3: Point(x: 6, y: 5),
    );
    final cubic = CubicCurve(
      p0: Point(x: 1, y: 0),
      p1: Point(x: 3, y: 6),
      p2: Point(x: 5, y: 2),
      p3: Point(x: 7, y: 0),
    );
    final intersections =
        cubic.intersectionsWithCurve(cubicButActuallyLinear, accuracy: epsilon);
    expect(intersections.length, 1);
    expect(intersections[0].t1, closeTo(0.5, epsilon));
    expect(intersections[0].t2, closeTo(1.0 / 3.0, epsilon));
  });

  test("IntersectionsCubicButActuallyQuadratic", () {
    // this test presents a challenge for an implicitization based approach
    // if the quadratic nature of the so-called "cubic" is not detected
    // the implicit equation will be f(x, y) = 0 and no intersections will be found
    const epsilon = 1.0e-5;
    final cubicButActuallyQuadratic = CubicCurve(
      p0: Point(x: 1, y: 1),
      p1: Point(x: 2, y: 4),
      p2: Point(x: 3, y: 4),
      p3: Point(x: 4, y: 1),
    );
    final cubic = CubicCurve(
      p0: Point(x: 0, y: 0),
      p1: Point(x: 2, y: 4),
      p2: Point(x: 4, y: 3),
      p3: Point(x: 6, y: 3),
    );
    final intersections = cubic
        .intersectionsWithCurve(cubicButActuallyQuadratic, accuracy: epsilon);
    expect(intersections.length, 2);
    expect(intersections[0].t1, closeTo(0.23607, epsilon));
    expect(intersections[0].t2, closeTo(0.13880, epsilon));
    expect(intersections[1].t1, closeTo(0.5, epsilon));
    expect(intersections[1].t2, closeTo(2.0 / 3.0, epsilon));
  });

  test("RealWorldPrecisionIssue", () {
    // this issue seems to happen because the implicit equation of c2
    // says f(x, y) = -8.177[...]e-10 for c1's starting point (instead of zero)
    // for a t1 = 0.000012060505980311977
    // the inverse expression says t2 = 1.0000005567957639 which gets rounded back to 1
    final c1 = CubicCurve(
      p0: Point(x: 94.9790542640437, y: 96.49280906706511),
      p1: Point(x: 94.53950656843848, y: 97.22786538484215),
      p2: Point(x: 93.58730187717677, y: 97.46742245525438),
      p3: Point(x: 92.85224555939973, y: 97.02787475964917),
    );
    final c2 = CubicCurve(
      p0: Point(x: 123.54200084128175, y: 48.71908399606449),
      p1: Point(x: 114.021065782688, y: 64.64877149606448),
      p2: Point(x: 104.49998932263745, y: 80.57093406706511),
      p3: Point(x: 94.9790542640437, y: 96.49280906706511),
    );
    final intersections = c1.intersectionsWithCurve(c2, accuracy: 1.0e-5);
    expect(intersections, [Intersection(t1: 0, t2: 1)]);
  });

  test("RealWorldInversionIssue", () {
    // this issue appears / appeared to occur because the inverse method
    // was unstable when c2 was downgraded to a cubic with nearly parallel control points
    final c1 = CubicCurve(
      p0: Point(x: 314.9306297035616, y: 2211.1494686514056),
      p1: Point(x: 315.4305682688995, y: 2211.87791339535),
      p2: Point(x: 315.24532741089774, y: 2212.8737148198643),
      p3: Point(x: 314.5168826669535, y: 2213.373653385202),
    );
    final c2 = CubicCurve(
      p0: Point(x: 314.8254662024578, y: 2210.9959498495646),
      p1: Point(x: 314.8606224524578, y: 2211.0472193808146),
      p2: Point(x: 314.89544293598345, y: 2211.0981991201556),
      p3: Point(x: 314.9306297035616, y: 2211.1494686514056),
    );
    final intersections = c1.intersectionsWithCurve(c2, accuracy: 1.0e-4);
    expect(intersections, [Intersection(t1: 0, t2: 1)]);
  });

  test("CubicIntersectsLine", () {
    const epsilon = 0.00001;
    final c = CubicCurve(
      p0: Point(x: -1, y: 0),
      p1: Point(x: -1, y: 1),
      p2: Point(x: 1, y: -1),
      p3: Point(x: 1, y: 0),
    );
    final BezierCurve l = LineSegment(
      p0: Point(x: -2.0, y: 0.0),
      p1: Point(x: 2.0, y: 0.0),
    );
    final i = c.intersectionsWithCurve(l);

    expect(i.length, 3);
    expect(i[0].t2, closeTo(0.25, epsilon));
    expect(i[0].t1, closeTo(0.0, epsilon));
    expect(i[1].t2, closeTo(0.5, epsilon));
    expect(i[1].t1, closeTo(0.5, epsilon));
    expect(i[2].t2, closeTo(0.75, epsilon));
    expect(i[2].t1, closeTo(1.0, epsilon));
  });

  test("CubicIntersectsLineEdgeCase", () {
    // this example caused issues in practice because it has a discriminant that is nearly equal to zero (but not exactly)
    final c = CubicCurve(
      p0: Point(x: 3, y: 1),
      p1: Point(x: 3, y: 1.5522847498307932),
      p2: Point(x: 2.5522847498307932, y: 2),
      p3: Point(x: 2, y: 2),
    );
    final l = LineSegment(p0: Point(x: 2, y: 2), p1: Point(x: 0, y: 2));
    final i = c.intersectionsWithLine(l);
    expect(i.length, 1);
    expect(i[0].t1, 1);
    expect(i[0].t2, 0);
  });

  test("CubicIntersectsLineCoincident", () {
    final line = LineSegment(p0: Point(x: -4, y: 7), p1: Point(x: 10, y: 3));
    final curve = CubicCurve.fromLine(line);
    expect(line.intersectionsWithCurve(curve),
        [Intersection(t1: 0, t2: 0), Intersection(t1: 1, t2: 1)],
        reason: "curve and line should be fully coincident");
  });

  // MARK: -

  test("Equatable", () {
    final p0 = Point(x: 1.0, y: 2.0);
    final p1 = Point(x: 2.0, y: 3.0);
    final p2 = Point(x: 3.0, y: 3.0);
    final p3 = Point(x: 4.0, y: 2.0);

    final c1 = CubicCurve(p0: p0, p1: p1, p2: p2, p3: p3);
    final c2 = CubicCurve(p0: Point(x: 5.0, y: 6.0), p1: p1, p2: p2, p3: p3);
    final c3 = CubicCurve(p0: p0, p1: Point(x: 1.0, y: 3.0), p2: p2, p3: p3);
    final c4 = CubicCurve(p0: p0, p1: p1, p2: Point(x: 3.0, y: 6.0), p3: p3);
    final c5 = CubicCurve(p0: p0, p1: p1, p2: p2, p3: Point(x: -4.0, y: 2.0));

    expect(c1, c1);
    expect(c1, isNot(c2));
    expect(c1, isNot(c3));
    expect(c1, isNot(c4));
    expect(c1, isNot(c5));
  });
}
