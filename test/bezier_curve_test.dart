// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'dart:math';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

import 'bezier_kit_test_helpers.dart';

void main() {
  test("Equality", () {
    // two lines that are equal
    final l1 = LineSegment(p0: Point(x: 0, y: 1), p1: Point(x: 2, y: 1));
    final l2 = LineSegment(p0: Point(x: 0, y: 1), p1: Point(x: 2, y: 1));
    expect(l1, l2);

    // a line that isn't equal
    final l3 = LineSegment(p0: Point(x: 0, y: 1), p1: Point(x: 2, y: 2));
    expect(l1, isNot(l3));

    // a quadratic made from l1, different order, not equal!
    final q1 = QuadraticCurve.fromLine(l1);
    expect(l1, isNot(q1));
  });

  test("ScaleDistance", () {
    // line segment
    const epsilon = 1.0e-5;
    final l = LineSegment(
      p0: Point(x: 1.0, y: 2.0),
      p1: Point(x: 5.0, y: 6.0),
    );
    final ls = l.scale(distance: sqrt(2))!; // (moves line up and left by 1,1)
    final expectedLine = LineSegment(
      p0: Point(x: 0.0, y: 3.0),
      p1: Point(x: 4.0, y: 7.0),
    );
    expect(
        BezierKitTestHelpers.curveControlPointsEqual(
            curve1: ls, curve2: expectedLine, tolerance: epsilon),
        isTrue);
    // quadratic
    final q = QuadraticCurve(
      p0: Point(x: 1.0, y: 1.0),
      p1: Point(x: 2.0, y: 2.0),
      p2: Point(x: 3.0, y: 1.0),
    );
    final qs = q.scale(distance: sqrt(2))!;
    final expectedQuadratic = QuadraticCurve(
      p0: Point(x: 0.0, y: 2.0),
      p1: Point(x: 2.0, y: 4.0),
      p2: Point(x: 4.0, y: 2.0),
    );
    expect(
        BezierKitTestHelpers.curveControlPointsEqual(
            curve1: qs, curve2: expectedQuadratic, tolerance: epsilon),
        isTrue);
    // cubic
    final c = CubicCurve(
      p0: Point(x: -4.0, y: 0.0),
      p1: Point(x: -2.0, y: 2.0),
      p2: Point(x: 2.0, y: 2.0),
      p3: Point(x: 4.0, y: 0.0),
    );
    final cs = c.scale(distance: 2.0 * sqrt(2))!;
    final expectedCubic = CubicCurve(
      p0: Point(x: -6.0, y: 2.0),
      p1: Point(x: -3.0, y: 5.0),
      p2: Point(x: 3.0, y: 5.0),
      p3: Point(x: 6.0, y: 2.0),
    );
    expect(
        BezierKitTestHelpers.curveControlPointsEqual(
            curve1: cs, curve2: expectedCubic, tolerance: epsilon),
        isTrue);

    // ensure that scaling a cubic initialized from a line yields the same thing as the line
    final cFromLine = CubicCurve.fromLine(l);
    expect(
        BezierKitTestHelpers.curveControlPointsEqual(
            curve1: cFromLine.scale(distance: sqrt(2))!,
            curve2: CubicCurve.fromLine(expectedLine),
            tolerance: epsilon),
        isTrue);

    // ensure scaling a quadratic from a line yields the same thing as the line
    final qFromLine = QuadraticCurve.fromLine(l);
    expect(
        BezierKitTestHelpers.curveControlPointsEqual(
            curve1: qFromLine.scale(distance: sqrt(2))!,
            curve2: QuadraticCurve.fromLine(expectedLine),
            tolerance: epsilon),
        isTrue);
  });

  test("ScaleDistanceDegenerate", () {
    final p = Point(x: 3.14159, y: 2.71828);
    final curve = CubicCurve(p0: p, p1: p, p2: p, p3: p);
    expect(curve.scale(distance: 2), isNull);
  });

  test("ScaleDistanceEdgeCase", () {
    final a = Point(x: 0, y: 0);
    final b = Point(x: 1, y: 0);
    final cubic = CubicCurve(p0: a, p1: a, p2: b, p3: b);
    final result = cubic.scale(distance: 1);
    final offset = Point(x: 0, y: 1);
    final aOffset = a + offset;
    final bOffset = b + offset;
    final expectedResult =
        CubicCurve(p0: aOffset, p1: aOffset, p2: bOffset, p3: bOffset);
    expect(result, expectedResult);
  });

  test("OffsetDistance", () {
    // line segments (or isLinear) have a separate codepath, so be sure to test those
    const epsilon = 1.0e-6;
    final c1 = CubicCurve.fromLine(
        LineSegment(p0: Point(x: 0.0, y: 0.0), p1: Point(x: 1.0, y: 1.0)));
    final c1Offset = c1.offset(distance: sqrt(2));
    final expectedOffset1 = CubicCurve.fromLine(
        LineSegment(p0: Point(x: -1.0, y: 1.0), p1: Point(x: 0.0, y: 2.0)));
    expect(c1Offset.length, 1);
    expect(
        BezierKitTestHelpers.curveControlPointsEqual(
            curve1: c1Offset[0] as CubicCurve,
            curve2: expectedOffset1,
            tolerance: epsilon),
        isTrue);
    // next test a non-simple curve
    final c2 = CubicCurve(
      p0: Point(x: 1.0, y: 1.0),
      p1: Point(x: 2.0, y: 2.0),
      p2: Point(x: 3.0, y: 2.0),
      p3: Point(x: 4.0, y: 1.0),
    );
    final c2Offset = c2.offset(distance: sqrt(2));
    for (var i = 0; i < c2Offset.length; i++) {
      final c = c2Offset[i];
      expect(c.simple, isTrue);
      if (i == 0) {
        // segment starts where un-reduced segment started (after ofsetting)
        expect(distance(c.startingPoint, Point(x: 0.0, y: 2.0)),
            lessThan(epsilon));
      } else {
        // segment starts where last ended
        expect(c.startingPoint, c2Offset[i - 1].endingPoint);
      }
      if (i == c2Offset.length - 1) {
        // segment ends where un-reduced segment ended (after ofsetting)
        expect(
            distance(c.endingPoint, Point(x: 5.0, y: 2.0)), lessThan(epsilon));
      }
    }
  });

  test("OffsetTimeDistance", () {
    const epsilon = 1.0e-6;
    final q = QuadraticCurve(
      p0: Point(x: 1.0, y: 1.0),
      p1: Point(x: 2.0, y: 2.0),
      p2: Point(x: 3.0, y: 1.0),
    );
    final p0 = q.offsetAt(0.0, distance: sqrt(2));
    final p1 = q.offsetAt(0.5, distance: 1.5);
    final p2 = q.offsetAt(1.0, distance: sqrt(2));
    expect(distance(p0, Point(x: 0.0, y: 2.0)), lessThan(epsilon));
    expect(distance(p1, Point(x: 2.0, y: 3.0)), lessThan(epsilon));
    expect(distance(p2, Point(x: 4.0, y: 2.0)), lessThan(epsilon));
  });

  final lineSegmentForOutlining =
      LineSegment(p0: Point(x: -10, y: -5), p1: Point(x: 20, y: 10));

  (Point, Point, Point, Point) lineOffsets(
      LineSegment lineSegment, double d1, double d2, double d3, double d4) {
    final o0 = lineSegment.startingPoint + lineSegment.normal(at: 0) * d1;
    final o1 = lineSegment.endingPoint + lineSegment.normal(at: 1) * d3;
    final o2 = lineSegment.endingPoint - lineSegment.normal(at: 1) * d4;
    final o3 = lineSegment.startingPoint - lineSegment.normal(at: 0) * d2;
    return (o0, o1, o2, o3);
  }

  test("OutlineDistance", () {
    // When only one distance value is given, the outline is generated at distance d on both the normal and anti-normal
    final lineSegment = lineSegmentForOutlining;
    final outline = lineSegment.outline(distance: 1);
    expect(outline.numberOfElements, 4);

    final (o0, o1, o2, o3) = lineOffsets(lineSegment, 1, 1, 1, 1);

    expect(
        BezierKitTestHelpers.curve(outline.element(at: 0),
            matchesCurve: LineSegment(p0: o3, p1: o0)),
        isTrue);
    expect(
        BezierKitTestHelpers.curve(outline.element(at: 1),
            matchesCurve: LineSegment(p0: o0, p1: o1)),
        isTrue);
    expect(
        BezierKitTestHelpers.curve(outline.element(at: 2),
            matchesCurve: LineSegment(p0: o1, p1: o2)),
        isTrue);
    expect(
        BezierKitTestHelpers.curve(outline.element(at: 3),
            matchesCurve: LineSegment(p0: o2, p1: o3)),
        isTrue);
  });

  test("OutlineDistanceAlongNormalDistanceOppositeNormal", () {
    //  If two distance values are given, the outline is generated at distance d1 on along the normal, and d2 along the anti-normal.
    final lineSegment = lineSegmentForOutlining;
    final distanceAlongNormal = 1.0;
    final distanceOppositeNormal = 2.0;
    final outline = lineSegment.outlineNormal(
        distanceAlongNormal: distanceAlongNormal,
        distanceOppositeNormal: distanceOppositeNormal);
    expect(outline.numberOfElements, 4);

    final o0 = lineSegment.startingPoint +
        lineSegment.normal(at: 0) * distanceAlongNormal;
    final o1 = lineSegment.endingPoint +
        lineSegment.normal(at: 1) * distanceAlongNormal;
    final o2 = lineSegment.endingPoint -
        lineSegment.normal(at: 1) * distanceOppositeNormal;
    final o3 = lineSegment.startingPoint -
        lineSegment.normal(at: 0) * distanceOppositeNormal;

    expect(
        BezierKitTestHelpers.curve(outline.element(at: 0),
            matchesCurve: LineSegment(p0: o3, p1: o0)),
        isTrue);
    expect(
        BezierKitTestHelpers.curve(outline.element(at: 1),
            matchesCurve: LineSegment(p0: o0, p1: o1)),
        isTrue);
    expect(
        BezierKitTestHelpers.curve(outline.element(at: 2),
            matchesCurve: LineSegment(p0: o1, p1: o2)),
        isTrue);
    expect(
        BezierKitTestHelpers.curve(outline.element(at: 3),
            matchesCurve: LineSegment(p0: o2, p1: o3)),
        isTrue);
  });

  test("OutlineQuadraticNormalsParallel", () {
    // this tests a special corner case of outlines where endpoint normals are parallel

    final q = QuadraticCurve(
      p0: Point(x: 0.0, y: 0.0),
      p1: Point(x: 5.0, y: 0.0),
      p2: Point(x: 10.0, y: 0.0),
    );
    final outline = q.outline(distance: 1);

    final expectedSegment1 =
        LineSegment(p0: Point(x: 0, y: -1), p1: Point(x: 0, y: 1));
    final expectedSegment2 =
        LineSegment(p0: Point(x: 0, y: 1), p1: Point(x: 10, y: 1));
    final expectedSegment3 =
        LineSegment(p0: Point(x: 10, y: 1), p1: Point(x: 10, y: -1));
    final expectedSegment4 =
        LineSegment(p0: Point(x: 10, y: -1), p1: Point(x: 0, y: -1));

    expect(outline.numberOfElements, 4);
    expect(
        BezierKitTestHelpers.curve(outline.element(at: 0),
            matchesCurve: expectedSegment1),
        isTrue);
    expect(
        BezierKitTestHelpers.curve(outline.element(at: 1),
            matchesCurve: expectedSegment2),
        isTrue);
    expect(
        BezierKitTestHelpers.curve(outline.element(at: 2),
            matchesCurve: expectedSegment3),
        isTrue);
    expect(
        BezierKitTestHelpers.curve(outline.element(at: 3),
            matchesCurve: expectedSegment4),
        isTrue);
  });

  test("OutlineShapesDistance", () {
    final lineSegment = lineSegmentForOutlining;
    final distanceAlongNormal = 1.0;
    final shapes = lineSegment.outlineShapes(distance: distanceAlongNormal);
    expect(shapes.length, 1);
    final (o0, o1, o2, o3) = lineOffsets(lineSegment, distanceAlongNormal,
        distanceAlongNormal, distanceAlongNormal, distanceAlongNormal);
    final expectedShape = Shape(
        LineSegment(p0: o0, p1: o1),
        LineSegment(p0: o2, p1: o3),
        false,
        false); // shape made from lines with real (non-virtual) caps
    expect(BezierKitTestHelpers.shape(shapes[0], matchesShape: expectedShape),
        isTrue);
  });

  test("OutlineShapesDistanceAlongNormalDistanceOppositeNormal", () {
    final lineSegment = lineSegmentForOutlining;
    final distanceAlongNormal = 1.0;
    final distanceOppositeNormal = 2.0;
    final shapes = lineSegment.outlineShapesNormal(
        distanceAlongNormal: distanceAlongNormal,
        distanceOppositeNormal: distanceOppositeNormal);
    expect(shapes.length, 1);
    final (o0, o1, o2, o3) = lineOffsets(lineSegment, distanceAlongNormal,
        distanceOppositeNormal, distanceAlongNormal, distanceOppositeNormal);
    final expectedShape = Shape(
        LineSegment(p0: o0, p1: o1),
        LineSegment(p0: o2, p1: o3),
        false,
        false); // shape made from lines with real (non-virtual) caps
    expect(BezierKitTestHelpers.shape(shapes[0], matchesShape: expectedShape),
        isTrue);
  });

  test("CubicCubicIntersectionEndpoints", () {
    // these two cubics intersect only at the endpoints
    const epsilon = 1.0e-3;
    final cubic1 = CubicCurve(
      p0: Point(x: 0.0, y: 0.0),
      p1: Point(x: 1.0, y: 1.0),
      p2: Point(x: 2.0, y: 1.0),
      p3: Point(x: 3.0, y: 0.0),
    );
    final cubic2 = CubicCurve(
      p0: Point(x: 3.0, y: 0.0),
      p1: Point(x: 2.0, y: -1.0),
      p2: Point(x: 1.0, y: -1.0),
      p3: Point(x: 0.0, y: 0.0),
    );
    final i = cubic1.intersectionsWithCurve(cubic2, accuracy: epsilon);
    expect(i.length, 2, reason: "start and end points should intersect!");
    expect(i[0].t1, 0.0);
    expect(i[0].t2, 1.0);
    expect(i[1].t1, 1.0);
    expect(i[1].t2, 0.0);
  });

  bool curveSelfIntersects(CubicCurve curve) {
    const epsilon = 1.0e-5;
    final result = curve.selfIntersects;
    if (result) {
      // check consistency
      final intersections = curve.selfIntersections;
      expect(intersections.length, 1);
      expect(
          distance(curve.point(at: intersections[0].t1),
              curve.point(at: intersections[0].t2)),
          lessThan(epsilon));
    }
    return result;
  }

  test("CubicSelfIntersection", () {
    final curve = CubicCurve(
      p0: Point(x: 0, y: 0),
      p1: Point(x: 0, y: 1),
      p2: Point(x: 1, y: 1),
      p3: Point(x: 1, y: 1),
    );

    bool selfIntersectsWithEndpointMoved({required Point to}) {
      final copy = curve.copyWith();
      copy.p3 = to;
      return curveSelfIntersects(copy);
    }

    // check basic cases with no self-intersections
    expect(selfIntersectsWithEndpointMoved(to: Point(x: 0.5, y: 2)), isFalse);
    expect(selfIntersectsWithEndpointMoved(to: Point(x: 0.5, y: 0.5)), isFalse);
    expect(selfIntersectsWithEndpointMoved(to: Point(x: 0.5, y: -1)), isFalse);
    expect(selfIntersectsWithEndpointMoved(to: Point(x: -0.5, y: -1)), isFalse);
    expect(selfIntersectsWithEndpointMoved(to: Point(x: -1, y: 0.5)), isFalse);
    expect(selfIntersectsWithEndpointMoved(to: Point(x: -1, y: 2)), isFalse);

    // check basic cases with self-intersections
    expect(
        selfIntersectsWithEndpointMoved(to: Point(x: 0.25, y: 0.75)), isTrue);
    expect(selfIntersectsWithEndpointMoved(to: Point(x: -1, y: -0.5)), isTrue);
    expect(
        selfIntersectsWithEndpointMoved(to: Point(x: -0.5, y: 0.25)), isTrue);

    // check edge cases around (0, 0.75)
    expect(selfIntersectsWithEndpointMoved(to: Point(x: 0, y: 0.76)), isFalse);
    expect(selfIntersectsWithEndpointMoved(to: Point(x: 0, y: 0.75)), isFalse);
    expect(selfIntersectsWithEndpointMoved(to: Point(x: 0, y: 0.74)), isTrue);

    // check for edge cases around (-1, 0)
    expect(selfIntersectsWithEndpointMoved(to: Point(x: -1.01, y: 0)), isFalse);
    expect(selfIntersectsWithEndpointMoved(to: Point(x: -1, y: 0)), isFalse);
    expect(selfIntersectsWithEndpointMoved(to: Point(x: -0.99, y: 0)), isTrue);

    // check for edge cases around (-0.5, 0.58)
    expect(
        selfIntersectsWithEndpointMoved(to: Point(x: -0.5, y: -0.59)), isFalse);
    expect(
        selfIntersectsWithEndpointMoved(to: Point(x: -0.5, y: -0.58)), isTrue);

    // check for edge cases around (0,0)
    expect(selfIntersectsWithEndpointMoved(to: Point(x: 0, y: 0)), isTrue);
    expect(selfIntersectsWithEndpointMoved(to: Point(x: 0.01, y: 0)), isFalse);
    expect(selfIntersectsWithEndpointMoved(to: Point(x: 0, y: 0.01)), isTrue);
    expect(selfIntersectsWithEndpointMoved(to: Point(x: -0.01, y: 0)), isTrue);
    expect(selfIntersectsWithEndpointMoved(to: Point(x: 0, y: -0.01)), isFalse);

    // check for edge cases around (1,1)
    expect(selfIntersectsWithEndpointMoved(to: Point(x: 1, y: 1)), isFalse);
    expect(selfIntersectsWithEndpointMoved(to: Point(x: 0.95, y: 0.9991)),
        isFalse);
    expect(
        selfIntersectsWithEndpointMoved(to: Point(x: 0.95, y: 0.9993)), isTrue);
    expect(selfIntersectsWithEndpointMoved(to: Point(x: 0.95, y: 0.9995)),
        isFalse);

    // check degenerate case where all points equal
    final point = Point(x: 3, y: 4);
    final degenerateCurve =
        CubicCurve(p0: point, p1: point, p2: point, p3: point);
    expect(curveSelfIntersects(degenerateCurve), isFalse);

    // check line segment case
    final lineSegment = CubicCurve.fromLine(
        LineSegment(p0: Point(x: 1, y: 2), p1: Point(x: 3, y: 4)));
    expect(curveSelfIntersects(lineSegment), isFalse);
  });

  test("CubicSelfIntersectionEdgeCase", () {
    // this curve nearly has a "cusp" which causes `reduce()` to fail
    // this failure could prevent detection of the self-intersection in practice
    final curve = CubicCurve(
      p0: Point(x: 0.6699848912467168, y: 0.6276580745456783),
      p1: Point(x: 0.3985029248079961, y: 0.6770972104768092),
      p2: Point(x: 0.6414685401578772, y: 0.8591306876578386),
      p3: Point(x: 0.4385385980761747, y: 0.3866255870526274),
    );
    expect(curveSelfIntersects(curve), isTrue);
  });
}
