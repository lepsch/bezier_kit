// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'dart:math';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

import 'bezier_kit_test_helpers.dart';

void main() {
  // TODO: we still have a LOT of missing unit tests for QuadraticCurve's API entry points

//    test("InitializerArray", () {
//    }
//
//    test("InitializerIndividualPoints", () {
//    }
//
//    test("InitializerLineSegment", () {
//    }
//
  test("InitializerStartEndMidT", () {
    final q1 = QuadraticCurve.from3Points(
        start: Point(x: 1.0, y: 1.0),
        end: Point(x: 5.0, y: 1.0),
        mid: Point(x: 3.0, y: 2.0),
        t: 0.5);
    expect(
        q1,
        QuadraticCurve(
            p0: Point(x: 1.0, y: 1.0),
            p1: Point(x: 3.0, y: 3.0),
            p2: Point(x: 5.0, y: 1.0)));
    // degenerate cases
    final q2 = QuadraticCurve.from3Points(
        start: Point(x: 1.0, y: 1.0),
        end: Point(x: 5.0, y: 1.0),
        mid: Point(x: 1.0, y: 1.0),
        t: 0.0);
    expect(
        q2,
        QuadraticCurve(
            p0: Point(x: 1.0, y: 1.0),
            p1: Point(x: 1.0, y: 1.0),
            p2: Point(x: 5.0, y: 1.0)));
    final q3 = QuadraticCurve.from3Points(
        start: Point(x: 1.0, y: 1.0),
        end: Point(x: 5.0, y: 1.0),
        mid: Point(x: 5.0, y: 1.0),
        t: 1.0);
    expect(
        q3,
        QuadraticCurve(
            p0: Point(x: 1.0, y: 1.0),
            p1: Point(x: 5.0, y: 1.0),
            p2: Point(x: 5.0, y: 1.0)));
  });

  test("BasicProperties", () {
    final q = QuadraticCurve(
        p0: Point(x: 1.0, y: 1.0),
        p1: Point(x: 3.5, y: 2.0),
        p2: Point(x: 6.0, y: 1.0));
    expect(q.simple, isTrue);
    expect(q.order, 2);
    expect(q.startingPoint, Point(x: 1.0, y: 1.0));
    expect(q.endingPoint, Point(x: 6.0, y: 1.0));
  });

  test("SetStartEndPoints", () {
    var q = QuadraticCurve(
        p0: Point(x: 5.0, y: 6.0),
        p1: Point(x: 6.0, y: 5.0),
        p2: Point(x: 8.0, y: 7.0));
    q.startingPoint = Point(x: 4.0, y: 5.0);
    expect(q.p0, q.startingPoint);
    expect(q.startingPoint, Point(x: 4.0, y: 5.0));
    q.endingPoint = Point(x: 9.0, y: 8.0);
    expect(q.p2, q.endingPoint);
    expect(q.endingPoint, Point(x: 9.0, y: 8.0));
  });

//    test("Simple", () {
//    }
//
//    test("Derivative", () {
//    }
//
//    test("SplitFromTo", () {
//    }
//
//    test("SplitAt", () {
//    }
//
  test("BoundingBox", () {
    // hits codepath where midpoint pushes up y coordinate of bounding box
    final q1 = QuadraticCurve(
        p0: Point(x: 1.0, y: 1.0),
        p1: Point(x: 3.0, y: 3.0),
        p2: Point(x: 5.0, y: 1.0));
    final expectedBoundingBox1 =
        BoundingBox(p1: Point(x: 1.0, y: 1.0), p2: Point(x: 5.0, y: 2.0));
    expect(q1.boundingBox, expectedBoundingBox1);

    // hits codepath where midpoint pushes down x coordinate of bounding box
    final q2 = QuadraticCurve(
        p0: Point(x: 1.0, y: 1.0),
        p1: Point(x: -1.0, y: 2.0),
        p2: Point(x: 1.0, y: 3.0));
    final expectedBoundingBox2 =
        BoundingBox(p1: Point(x: 0.0, y: 1.0), p2: Point(x: 1.0, y: 3.0));
    expect(q2.boundingBox, expectedBoundingBox2);
    // this one is designed to hit an unusual codepath: c3 has an extrema that would expand the bounding box,
    // but it falls outside of the range 0<=t<=1, and therefore must be excluded
    final q3 = q1.splitAt(0.25).left;
    final expectedBoundingBox3 =
        BoundingBox(p1: Point(x: 1.0, y: 1.0), p2: Point(x: 2.0, y: 1.75));
    expect(q3.boundingBox, expectedBoundingBox3);
  });
//
//    test("Compute", () {
//    });

  // - methods for which default implementations provided by protocol

//    test("Length", () {
//    }
//

  test("Project", () {
    const epsilon = 1.0e-5;
    final q = QuadraticCurve(
      p0: Point(x: 1, y: 1),
      p1: Point(x: 2, y: 0),
      p2: Point(x: 4, y: 1),
    );
    final result1 = q.project(Point(x: 2, y: 2));
    expect(result1.t, 0);
    expect(result1.point, Point(x: 1, y: 1));
    final result2 = q.project(Point(x: 5, y: 1));
    expect(result2.t, 1);
    expect(result2.point, Point(x: 4, y: 1));
    final result3 = q.project(Point(x: 2.25, y: 1));
    expect(result3.t, 0.5);
    expect(result3.point, Point(x: 2.25, y: 0.5));
    // test accuracy
    const t = 0.374858262;
    final expectedPoint = q.point(at: t);
    final pointToProject = expectedPoint + q.normal(at: t) * 0.234;
    final result4 = q.project(pointToProject);
    expect(result4.t, closeTo(t, epsilon));
    expect(distance(result4.point, expectedPoint), lessThan(epsilon));
  });

//
//    test("Hull", () {
//    }
//

  test("NormalDegenerate", () {
    const maxError = 0.01;
    final a = Point(x: 2, y: 3);
    final b = Point(x: 3, y: 3);
    final quadratic1 = QuadraticCurve(p0: a, p1: a, p2: b);
    expect(distance(quadratic1.normal(at: 0), Point(x: 0, y: 1)),
        lessThan(maxError));
    final quadratic2 = QuadraticCurve(p0: a, p1: b, p2: b);
    expect(distance(quadratic2.normal(at: 1), Point(x: 0, y: 1)),
        lessThan(maxError));
  });

  test("Reduce", () {
    // already simple curve
    final q1 = QuadraticCurve(
      p0: Point(x: 0, y: 0),
      p1: Point(x: 4, y: 3),
      p2: Point(x: 7, y: 7),
    );
    expect(
        BezierKitTestHelpers.isSatisfactoryReduceResult(q1.reduce(), curve: q1),
        isTrue);
    // must remove maxima at 0.5
    final q2 = QuadraticCurve(
      p0: Point(x: 0, y: 0),
      p1: Point(x: 2, y: 1),
      p2: Point(x: 4, y: 0),
    );
    expect(
        BezierKitTestHelpers.isSatisfactoryReduceResult(q2.reduce(), curve: q2),
        isTrue);
    // ensure handles degeneracies ok
    final p = Point(x: 2.17, y: 3.14);
    final q3 = QuadraticCurve(p0: p, p1: p, p2: p);
    expect(
        BezierKitTestHelpers.isSatisfactoryReduceResult(q3.reduce(), curve: q3),
        isTrue);
  });
//
//    test("ScaleDistanceFunc",  {
//    }
//
//
//
  test("IntersectionsQuadratic", () {
    const epsilon = 1.0e-5;
    final q1 = QuadraticCurve.from3Points(
      start: Point(x: 0.0, y: 0.0),
      end: Point(x: 2.0, y: 0.0),
      mid: Point(x: 1.0, y: 2.0),
      t: 0.5,
    );
    final q2 = QuadraticCurve.from3Points(
      start: Point(x: 0.0, y: 2.0),
      end: Point(x: 2.0, y: 2.0),
      mid: Point(x: 1.0, y: 0.0),
      t: 0.5,
    );
    final i = q1.intersectionsWithCurve(q2, accuracy: epsilon);
    expect(i.length, 2);
    final root1 = 1.0 - sqrt(2) / 2.0;
    final root2 = 1.0 + sqrt(2) / 2.0;
    final expectedResult1 = Point(x: root1, y: 1);
    final expectedResult2 = Point(x: root2, y: 1);
    expect(distance(q1.point(at: i[0].t1), expectedResult1), lessThan(epsilon));
    expect(distance(q1.point(at: i[1].t1), expectedResult2), lessThan(epsilon));
    expect(distance(q2.point(at: i[0].t2), expectedResult1), lessThan(epsilon));
    expect(distance(q2.point(at: i[1].t2), expectedResult2), lessThan(epsilon));
  });

  test("IntersectionsQuadraticMaxIntersections", () {
    const epsilon = 1.0e-5;
    final q1 = QuadraticCurve.from3Points(
      start: Point(x: 0.0, y: 0.0),
      end: Point(x: 2.0, y: 0.0),
      mid: Point(x: 1.0, y: 2.0),
      t: 0.5,
    );
    final q2 = QuadraticCurve.from3Points(
      start: Point(x: 0.0, y: 0.0),
      end: Point(x: 0.0, y: 2.0),
      mid: Point(x: 2.0, y: 1.0),
      t: 0.5,
    );
    final intersections = q1.intersectionsWithCurve(q2, accuracy: epsilon);
    final expectedResults = [
      Point(x: 0.0, y: 0.0),
      Point(x: 0.69098300, y: 1.8090170),
      Point(x: 1.5, y: 1.5),
      Point(x: 1.8090170, y: 0.69098300),
    ];
    expect(intersections.length, 4);
    for (var i = 0; i < intersections.length; i++) {
      expect(distance(q1.point(at: intersections[i].t1), expectedResults[i]),
          lessThan(epsilon));
      expect(distance(q2.point(at: intersections[i].t2), expectedResults[i]),
          lessThan(epsilon));
    }
  });

  test("IntersectionQuadraticColinearControlPoints", () {
    // this test presents two challenges
    // 1. if we use implicitization there is a double-root at t=0.75
    // which can be missed by root finding algorithms.
    // 2. the numerator and denominator of the inverse equation is zero for any point
    // that falls on `quadraticWithColinearControlPoints`, which yields NaN
    const epsilon = 1.0e-5;
    final quadraticWithColinearControlPoints = QuadraticCurve(
      p0: Point(x: 1, y: 1),
      p1: Point(x: 3, y: 3),
      p2: Point(x: 2, y: 2),
    );
    final quadratic = QuadraticCurve(
      p0: Point(x: 0, y: 0),
      p1: Point(x: 1, y: 4),
      p2: Point(x: 2, y: 0),
    );
    final intersections = quadratic.intersectionsWithCurve(
        quadraticWithColinearControlPoints,
        accuracy: epsilon);
    expect(intersections.length, 1);
    expect(intersections[0].t1, 0.75);
    expect(intersections[0].t2, closeTo(0.13962, 1.0e-5));
  });

  test("IntersectionQuadraticButActuallyLinear", () {
    // this test presents a challenge for an implicitization based approach
    // if the linearity of the so-called "quadratic" is not detected
    // the implicit equation will be f(x, y) = 0 and no intersections will be found
    const epsilon = 1.0e-5;
    final quadraticButActuallyLinear = QuadraticCurve(
      p0: Point(x: 2, y: 1),
      p1: Point(x: 3, y: 2),
      p2: Point(x: 4, y: 3),
    );
    final quadratic = QuadraticCurve(
      p0: Point(x: 0, y: 0),
      p1: Point(x: 3.5, y: 5),
      p2: Point(x: 7, y: 0),
    );
    final intersections = quadratic
        .intersectionsWithCurve(quadraticButActuallyLinear, accuracy: epsilon);
    expect(intersections.length, 1);
    expect(intersections[0].t1, 0.5);
    expect(intersections[0].t2, 0.75);
  });

  test("Equatable", () {
    final p0 = Point(x: 1.0, y: 2.0);
    final p1 = Point(x: 2.0, y: 3.0);
    final p2 = Point(x: 3.0, y: 2.0);

    final c1 = QuadraticCurve(p0: p0, p1: p1, p2: p2);
    final c2 = QuadraticCurve(p0: p0, p1: p1, p2: p2);
    final c3 = QuadraticCurve(p0: Point(x: 5.0, y: 6.0), p1: p1, p2: p2);
    final c4 = QuadraticCurve(p0: p0, p1: Point(x: 1.0, y: 3.0), p2: p2);
    final c5 = QuadraticCurve(p0: p0, p1: p1, p2: Point(x: 3.0, y: 6.0));

    expect(c1, c1);
    expect(c1, c2);
    expect(c1, isNot(c3));
    expect(c1, isNot(c4));
    expect(c1, isNot(c5));
  });
}
