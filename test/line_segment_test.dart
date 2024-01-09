//
//  LineSegmentTests.swift
//  BezierKit
//
//  Created by Holmes Futrell on 5/14/17.
//  Copyright © 2017 Holmes Futrell. All rights reserved.
//

import 'dart:math';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

import 'bezier_kit_test_helpers.dart';

void main() {
  test("InitializerArray", () {
    final l = LineSegment.fromList(
        points: [Point(x: 1.0, y: 1.0), Point(x: 3.0, y: 2.0)]);
    expect(l.p0, Point(x: 1.0, y: 1.0));
    expect(l.p1, Point(x: 3.0, y: 2.0));
    expect(l.startingPoint, Point(x: 1.0, y: 1.0));
    expect(l.endingPoint, Point(x: 3.0, y: 2.0));
  });

  test("InitializerIndividualPoints", () {
    final l = LineSegment(p0: Point(x: 1.0, y: 1.0), p1: Point(x: 3.0, y: 2.0));
    expect(l.p0, Point(x: 1.0, y: 1.0));
    expect(l.p1, Point(x: 3.0, y: 2.0));
    expect(l.startingPoint, Point(x: 1.0, y: 1.0));
    expect(l.endingPoint, Point(x: 3.0, y: 2.0));
  });

  test("BasicProperties", () {
    final l = LineSegment(p0: Point(x: 1.0, y: 1.0), p1: Point(x: 2.0, y: 5.0));
    expect(l.simple, isTrue);
    expect(l.order, 1);
    expect(l.startingPoint, Point(x: 1.0, y: 1.0));
    expect(l.endingPoint, Point(x: 2.0, y: 5.0));
  });

  test("SetStartEndPoints", () {
    final l = LineSegment(p0: Point(x: 5.0, y: 6.0), p1: Point(x: 8.0, y: 7.0));
    l.startingPoint = Point(x: 4.0, y: 5.0);
    expect(l.p0, l.startingPoint);
    expect(l.startingPoint, Point(x: 4.0, y: 5.0));
    l.endingPoint = Point(x: 9.0, y: 8.0);
    expect(l.p1, l.endingPoint);
    expect(l.endingPoint, Point(x: 9.0, y: 8.0));
  });

  test("Derivative", () {
    final l = LineSegment(p0: Point(x: 1.0, y: 1.0), p1: Point(x: 3.0, y: 2.0));
    expect(l.derivative(at: 0.23), Point(x: 2.0, y: 1.0));
  });

  test("SplitFromTo", () {
    final l = LineSegment(p0: Point(x: 1.0, y: 1.0), p1: Point(x: 4.0, y: 7.0));
    final t1 = 1.0 / 3.0;
    final t2 = 2.0 / 3.0;
    final s = l.split(from: t1, to: t2);
    expect(
        s, LineSegment(p0: Point(x: 2.0, y: 3.0), p1: Point(x: 3.0, y: 5.0)));
  });

  test("SplitAt", () {
    final l = LineSegment(p0: Point(x: 1.0, y: 1.0), p1: Point(x: 3.0, y: 5.0));
    final (:left, :right) = l.splitAt(0.5);
    expect(left,
        LineSegment(p0: Point(x: 1.0, y: 1.0), p1: Point(x: 2.0, y: 3.0)));
    expect(right,
        LineSegment(p0: Point(x: 2.0, y: 3.0), p1: Point(x: 3.0, y: 5.0)));
  });

  test("BoundingBox", () {
    final l = LineSegment(p0: Point(x: 3.0, y: 5.0), p1: Point(x: 1.0, y: 3.0));
    expect(l.boundingBox,
        BoundingBox(p1: Point(x: 1.0, y: 3.0), p2: Point(x: 3.0, y: 5.0)));
  });

  test("Compute", () {
    final l = LineSegment(p0: Point(x: 3.0, y: 5.0), p1: Point(x: 1.0, y: 3.0));
    expect(l.point(at: 0.0), Point(x: 3.0, y: 5.0));
    expect(l.point(at: 0.5), Point(x: 2.0, y: 4.0));
    expect(l.point(at: 1.0), Point(x: 1.0, y: 3.0));
  });

  test("ComputeRealWordIssue", () {
    final s = Point(x: 0.30901699437494745, y: 0.9510565162951535);
    final e = Point(x: 0.30901699437494723, y: -0.9510565162951536);
    final l = LineSegment(p0: s, p1: e);
    expect(l.point(at: 0), s);
    expect(l.point(at: 1), e); // this failed in practice
  });

  test("Length", () {
    final l = LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 4.0, y: 6.0));
    expect(l.length(), 5.0);
  });

  test("Project", () {
    final l = LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 5.0, y: 6.0));
    final p1 = l.project(Point(x: 0.0, y: 0.0)); // should project to p0
    expect(p1.point, Point(x: 1.0, y: 2.0));
    expect(p1.t, 0.0);
    final p2 =
        l.project(Point(x: 1.0, y: 4.0)); // should project to l.compute(0.25)
    expect(p2.point, Point(x: 2.0, y: 3.0));
    expect(p2.t, 0.25);
    final p3 = l.project(Point(x: 6.0, y: 7.0));
    expect(p3.point, Point(x: 5.0, y: 6.0)); // should project to p1
    expect(p3.t, 1.0);
  });

  test("Hull", () {
    final l = LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 3.0, y: 4.0));
    final h = l.hull(0.5);
    expect(h.length, 3);
    expect(h[0], Point(x: 1.0, y: 2.0));
    expect(h[1], Point(x: 3.0, y: 4.0));
    expect(h[2], Point(x: 2.0, y: 3.0));
  });

  test("Normal", () {
    final l = LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 5.0, y: 6.0));
    final n1 = l.normal(at: 0.0);
    final n2 = l.normal(at: 0.5);
    final n3 = l.normal(at: 1.0);
    expect(n1, Point(x: -1.0 / sqrt(2.0), y: 1.0 / sqrt(2.0)));
    expect(n1, n2);
    expect(n2, n3);
  });

  test("Reduce", () {
    final l = LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 5.0, y: 6.0));
    final r = l.reduce(); // reduce should just return the original line back
    expect(
        BezierKitTestHelpers.isSatisfactoryReduceResult(r, curve: l), isTrue);
  });

  test("SelfIntersects", () {
    final l = LineSegment(p0: Point(x: 3.0, y: 4.0), p1: Point(x: 5.0, y: 6.0));
    expect(l.selfIntersects, isFalse); // lines never self-intersect
  });

  test("SelfIntersections", () {
    final l = LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 5.0, y: 6.0));
    expect(l.selfIntersections.isEmpty, isTrue); // lines never self-intersect
  });

  // - line-line intersection tests

  test("IntersectionsLineYesInsideInterval", () {
    // a normal line-line intersection that happens in the middle of a line
    final l1 =
        LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 7.0, y: 8.0));
    final l2 =
        LineSegment(p0: Point(x: 1.0, y: 4.0), p1: Point(x: 5.0, y: 0.0));
    final i = l1.intersectionsWithLine(l2);
    expect(i.length, 1);
    expect(i[0].t1, 1.0 / 6.0);
    expect(i[0].t2, 1.0 / 4.0);
  });

  test("IntersectionsLineNoOutsideInterval1", () {
    // two lines that do not intersect because the intersection happens outside the line-segment
    final l1 =
        LineSegment(p0: Point(x: 1.0, y: 0.0), p1: Point(x: 1.0, y: 2.0));
    final l2 =
        LineSegment(p0: Point(x: 0.0, y: 2.001), p1: Point(x: 2.0, y: 2.001));
    final i = l1.intersectionsWithLine(l2);
    expect(i.isEmpty, isTrue);
  });

  test("IntersectionsLineNoOutsideInterval2", () {
    // two lines that do not intersect because the intersection happens outside the *other* line segment
    final l1 =
        LineSegment(p0: Point(x: 1.0, y: 0.0), p1: Point(x: 1.0, y: 2.0));
    final l2 =
        LineSegment(p0: Point(x: 2.0, y: 1.0), p1: Point(x: 1.001, y: 1.0));
    final i = l1.intersectionsWithLine(l2);
    expect(i.isEmpty, isTrue);
  });

  test("IntersectionsLineYesEdge1", () {
    // two lines that intersect on the 1st line's edge
    final l1 =
        LineSegment(p0: Point(x: 1.0, y: 0.0), p1: Point(x: 1.0, y: 2.0));
    final l2 =
        LineSegment(p0: Point(x: 2.0, y: 1.0), p1: Point(x: 1.0, y: 1.0));
    final i = l1.intersectionsWithLine(l2);
    expect(i.length, 1);
    expect(i[0].t1, 0.5);
    expect(i[0].t2, 1.0);
  });

  test("IntersectionsLineYesEdge2", () {
    // two lines that intersect on the 2nd line's edge
    final l1 =
        LineSegment(p0: Point(x: 1.0, y: 0.0), p1: Point(x: 1.0, y: 2.0));
    final l2 =
        LineSegment(p0: Point(x: 0.0, y: 2.0), p1: Point(x: 2.0, y: 2.0));
    final i = l1.intersectionsWithLine(l2);
    expect(i.length, 1);
    expect(i[0].t1, 1.0);
    expect(i[0].t2, 0.5);
  });

  test("IntersectionsLineYesLineStart", () {
    // two lines that intersect at the start of the first line
    final l1 =
        LineSegment(p0: Point(x: 1.0, y: 0.0), p1: Point(x: 2.0, y: 1.0));
    final l2 =
        LineSegment(p0: Point(x: -2.0, y: 2.0), p1: Point(x: 1.0, y: 0.0));
    final i = l1.intersectionsWithLine(l2);
    expect(i.length, 1);
    expect(i[0].t1, 0.0);
    expect(i[0].t2, 1.0);
  });

  test("IntersectionsLineYesLineEnd", () {
    // two lines that intersect at the end of the first line
    final l1 =
        LineSegment(p0: Point(x: 1.0, y: 0.0), p1: Point(x: 2.0, y: 1.0));
    final l2 =
        LineSegment(p0: Point(x: 2.0, y: 1.0), p1: Point(x: -2.0, y: 2.0));
    final i = l1.intersectionsWithLine(l2);
    expect(i.length, 1);
    expect(i[0].t1, 1.0);
    expect(i[0].t2, 0.0);
  });

  test("IntersectionsLineAsCurve", () {
    // ensure that intersects(curve:) calls into the proper implementation
    final LineSegment l1 =
        LineSegment(p0: Point(x: 0.0, y: 0.0), p1: Point(x: 1.0, y: 1.0));
    final BezierCurve l2 =
        LineSegment(p0: Point(x: 0.0, y: 1.0), p1: Point(x: 1.0, y: 0.0));
    final i1 = l1.intersectionsWithCurve(l2);
    expect(i1.length, 1);
    expect(i1[0].t1, 0.5);
    expect(i1[0].t2, 0.5);

    final i2 = l2.intersectionsWithLine(l1);
    expect(i2.length, 1);
    expect(i2[0].t1, 0.5);
    expect(i2[0].t2, 0.5);
  });

  test("IntersectionsLineNoParallel", () {
    // this is a special case where determinant is zero
    final l1 =
        LineSegment(p0: Point(x: -2.0, y: -1.0), p1: Point(x: 2.0, y: 1.0));
    final l2 =
        LineSegment(p0: Point(x: -4.0, y: -1.0), p1: Point(x: 4.0, y: 3.0));
    final i1 = l1.intersectionsWithLine(l2);
    expect(i1.isEmpty, isTrue);

    // very, very nearly parallel lines
    final l5 =
        LineSegment(p0: Point(x: 0.0, y: 0.0), p1: Point(x: 1.0, y: 1.0));
    final l6 = LineSegment(
        p0: Point(x: 0.0, y: 1.0), p1: Point(x: 1.0, y: 2.0 + 1.0e-15));
    final i3 = l5.intersectionsWithLine(l6);
    expect(i3.isEmpty, isTrue);
  });

  test("IntersectionsLineYesCoincidentBasic", () {
    // coincident in the middle
    final l1 =
        LineSegment(p0: Point(x: -5.0, y: -5.0), p1: Point(x: 5.0, y: 5.0));
    final l2 =
        LineSegment(p0: Point(x: -1.0, y: -1.0), p1: Point(x: 1.0, y: 1.0));
    final i1 = l1.intersectionsWithLine(l2);
    expect(i1, [Intersection(t1: 0.4, t2: 0), Intersection(t1: 0.6, t2: 1)]);

    // coincident at the start
    final l3 = LineSegment(p0: Point(x: 1, y: 1), p1: Point(x: 3, y: 3));
    final l4 = LineSegment(p0: Point(x: 1, y: 1), p1: Point(x: 2, y: 2));
    final i2 = l3.intersectionsWithLine(l4);
    expect(i2, [Intersection(t1: 0, t2: 0), Intersection(t1: 0.5, t2: 1)]);

    // coincident but in opposing directions
    final l5 = LineSegment(p0: Point(x: 1, y: 1), p1: Point(x: 3, y: -1));
    final l6 = LineSegment(p0: Point(x: 3, y: -1), p1: Point(x: 2, y: 0));
    final i3 = l5.intersectionsWithLine(l6);
    expect(i3, [Intersection(t1: 0.5, t2: 1), Intersection(t1: 1, t2: 0)]);

    // lines should be fully coincident with themselves
    final l7 = LineSegment(
        p0: Point(x: 1.863, y: 23.812), p1: Point(x: -4.876, y: 3.652));
    final i4 = l7.intersectionsWithLine(l7);
    expect(i4, [Intersection(t1: 0, t2: 0), Intersection(t1: 1, t2: 1)]);
  });

  test("IntersectionsLineYesCoincidentRealWorldData", () {
    final l1 = LineSegment(
        p0: Point(x: 134.76833383678579, y: 95.05360294098101),
        p1: Point(x: 171.33627533401454, y: 102.89462632327792));
    final l2 = LineSegment(
        p0: Point(x: 111.2, y: 90.0),
        p1: Point(x: 171.33627533401454, y: 102.89462632327792));
    final i = l1.intersectionsWithLine(l2);
    expect(i.length, 2, reason: "expected two intersections, got: $i");
    expect(i[0].t1, 0);
    expect(i[0].t2, closeTo(0.3919154238582343, 1.0e-4));
    expect(i[1].t1, 1);
    expect(i[1].t2, 1);
  });

  test("IntersectionsLineNotCoincidentRealWorldData", () {
    // in practice due to limitations of precision we can come to the wrong conclusion and think we're coincident over a tiny range (eg t=0.9999999999998739 to t=1)
    final line1 = LineSegment(
        p0: Point(x: 207.15663697593666, y: 105.38213850350812),
        p1: Point(x: 203.27567019330237, y: 95.49245438213565));
    final line2 = LineSegment(
        p0: Point(x: 199.5505907010711, y: 85.41166231873908),
        p1: Point(x: 203.27567019330286, y: 95.4924543821369));
    expect(line1.intersectionsWithLine(line2), [Intersection(t1: 1, t2: 1)],
        reason: "lines intersect only at their endpoint");
  });

  // - line-curve intersection tests

  test("IntersectionsQuadratic", () {
    // we mostly just care that we call into the proper implementation and that the results are ordered correctly
    // q is a quadratic where y(x) = 2 - 2(x-1)^2
    const epsilon = 0.00001;
    final q = QuadraticCurve.from3Points(
      start: Point(x: 0.0, y: 0.0),
      end: Point(x: 2.0, y: 0.0),
      mid: Point(x: 1.0, y: 2.0),
      t: 0.5,
    );
    final l1 = LineSegment(
      p0: Point(x: -1.0, y: 1.0),
      p1: Point(x: 3.0, y: 1.0),
    );
    final l2 = LineSegment(
      p0: Point(x: 3.0, y: 1.0),
      p1: Point(x: -1.0, y: 1.0),
    ); // same line as l1, but reversed;
    // the intersections for both lines occur at x = 1±sqrt(1/2)
    final i1 = l1.intersectionsWithCurve(q);
    final r1 = 1.0 - sqrt(1.0 / 2.0);
    final r2 = 1.0 + sqrt(1.0 / 2.0);
    expect(i1.length, 2);
    expect(i1[0].t1, closeTo((r1 + 1.0) / 4.0, epsilon));
    expect(i1[0].t2, closeTo(r1 / 2.0, epsilon));
    expect((l1.point(at: i1[0].t1) - q.point(at: i1[0].t2)).length,
        lessThan(epsilon));
    expect(i1[1].t1, closeTo((r2 + 1.0) / 4.0, epsilon));
    expect(i1[1].t2, closeTo(r2 / 2.0, epsilon));
    expect((l1.point(at: i1[1].t1) - q.point(at: i1[1].t2)).length,
        lessThan(epsilon));
    // do the same thing as above but using l2
    final i2 = l2.intersectionsWithCurve(q);
    expect(i2.length, 2);
    expect(i2[0].t1, closeTo((r1 + 1.0) / 4.0, epsilon));
    expect(i2[0].t2, closeTo(r2 / 2.0, epsilon));
    expect((l2.point(at: i2[0].t1) - q.point(at: i2[0].t2)).length,
        lessThan(epsilon));
    expect(i2[1].t1, closeTo((r2 + 1.0) / 4.0, epsilon));
    expect(i2[1].t2, closeTo(r1 / 2.0, epsilon));
    expect((l2.point(at: i2[1].t1) - q.point(at: i2[1].t2)).length,
        lessThan(epsilon));
  });

  test("IntersectionsQuadraticSpecialCase", () {
    // this is case that failed in the real-world
    final l = LineSegment(p0: Point(x: -1, y: 0), p1: Point(x: 1, y: 0));
    final q = QuadraticCurve(
        p0: Point(x: 0, y: 0), p1: Point(x: -1, y: 0), p2: Point(x: -1, y: 1));
    final i = l.intersectionsWithCurve(q);
    expect(i.length, 1);
    expect(i.first.t1, 0.5);
    expect(i.first.t2, 0);
  });

  test("IntersectionsCubic", () {
    // we mostly just care that we call into the proper implementation and that the results are ordered correctly
    const epsilon = 0.00001;
    final c = CubicCurve(
      p0: Point(x: -1, y: 0),
      p1: Point(x: -1, y: 1),
      p2: Point(x: 1, y: -1),
      p3: Point(x: 1, y: 0),
    );
    final l1 =
        LineSegment(p0: Point(x: -2.0, y: 0.0), p1: Point(x: 2.0, y: 0.0));
    final i1 = l1.intersectionsWithCurve(c);

    expect(i1.length, 3);
    expect(i1[0].t1, closeTo(0.25, epsilon));
    expect(i1[0].t2, closeTo(0.0, epsilon));
    expect(i1[1].t1, closeTo(0.5, epsilon));
    expect(i1[1].t2, closeTo(0.5, epsilon));
    expect(i1[2].t1, closeTo(0.75, epsilon));
    expect(i1[2].t2, closeTo(1.0, epsilon));
    // l2 is the same line going in the opposite direction
    // by checking this we ensure the intersections are ordered by the line and not the cubic
    final l2 =
        LineSegment(p0: Point(x: 2.0, y: 0.0), p1: Point(x: -2.0, y: 0.0));
    final i2 = l2.intersectionsWithCurve(c);
    expect(i2.length, 3);
    expect(i2[0].t1, closeTo(0.25, epsilon));
    expect(i2[0].t2, closeTo(1.0, epsilon));
    expect(i2[1].t1, closeTo(0.5, epsilon));
    expect(i2[1].t2, closeTo(0.5, epsilon));
    expect(i2[2].t1, closeTo(0.75, epsilon));
    expect(i2[2].t2, closeTo(0.0, epsilon));
  });

  test("IntersectionsCubicRealWorldIssue", () {
    // this was an issue because if you round t-values that are near zero you will get
    // cubicCurve.compute(intersections[0].t1).x = 309.5496606404184, which corresponds to t = -3.5242468640577755e-06 on the line (negative! outside the line!)
    final cubicCurve = CubicCurve(
      p0: Point(x: 301.42017404234923, y: 182.42157189005232),
      p1: Point(x: 305.9310607601042, y: 182.30247821176928),
      p2: Point(x: 309.72232986751203, y: 185.6785144367646),
      p3: Point(x: 310.198127403852, y: 190.08736919846973),
    );
    final line = LineSegment(
        p0: Point(x: 309.54962994198274, y: 187.61824016482512),
        p1: Point(x: 275.83899279843945, y: 187.61824016482512));
    expect(cubicCurve.intersectsLine(line), isFalse);
  });

  test("IntersectionsDegenerateCubic1", () {
    // a special case where the cubic is degenerate (it can actually be described as a quadratic)
    final epsilon = 0.00001;
    final fiveThirds = 5.0 / 3.0;
    final sevenThirds = 7.0 / 3.0;
    final c = CubicCurve(
      p0: Point(x: 1.0, y: 1.0),
      p1: Point(x: fiveThirds, y: fiveThirds),
      p2: Point(x: sevenThirds, y: fiveThirds),
      p3: Point(x: 3.0, y: 1.0),
    );
    final l = LineSegment(p0: Point(x: 1.0, y: 1.1), p1: Point(x: 3.0, y: 1.1));
    final i = l.intersectionsWithCurve(c);
    expect(i.length, 2);
    expect(
        BezierKitTestHelpers.intersections(i,
            betweenCurve: l, andOtherCurve: c, areWithinTolerance: epsilon),
        isTrue);
  });

  test("IntersectionsDegenerateCubic2", () {
    // a special case where the cubic is degenerate (it can actually be described as a line)
    const epsilon = 0.00001;
    final c = CubicCurve(
      p0: Point(x: 1.0, y: 1.0),
      p1: Point(x: 2.0, y: 2.0),
      p2: Point(x: 3.0, y: 3.0),
      p3: Point(x: 4.0, y: 4.0),
    );
    final l = LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 4.0, y: 2.0));
    final i = l.intersectionsWithCurve(c);
    expect(i.length, 1);
    expect(
        BezierKitTestHelpers.intersections(i,
            betweenCurve: l, andOtherCurve: c, areWithinTolerance: epsilon),
        isTrue);
  });

  test("IntersectionsCubicSpecialCase", () {
    // this is case that failed in the real-world
    final l = LineSegment(p0: Point(x: -1, y: 0), p1: Point(x: 1, y: 0));
    final q = CubicCurve.fromQuadratic(
      QuadraticCurve(
          p0: Point(x: 0, y: 0),
          p1: Point(x: -1, y: 0),
          p2: Point(x: -1, y: 1)),
    );
    final i = l.intersectionsWithCurve(q);
    expect(i.length, 1);
    expect(i.first.t1, 0.5);
    expect(i.first.t2, 0);
  });

  test("IntersectionsCubicRootsEdgeCase1", () {
    // this data caused issues in practice because because 'd' in the roots calculation is very near, but not exactly, zero.
    final c = CubicCurve(
      p0: Point(x: 201.48419096574196, y: 570.7720830272123),
      p1: Point(x: 202.27135851996428, y: 570.7720830272123),
      p2: Point(x: 202.90948390468964, y: 571.4102084119377),
      p3: Point(x: 202.90948390468964, y: 572.1973759661599),
    );
    final l = LineSegment(
        p0: Point(x: 200.05889802679428, y: 572.1973759661599),
        p1: Point(x: 201.48419096574196, y: 573.6226689051076));
    final i = l.intersectionsWithCurve(c);
    expect(i, []);
  });

  test("IntersectionsCubicRootsEdgeCase2", () {
    // this data caused issues in practice because because the discriminant in the roots calculation is very near zero
    final line = LineSegment(
      p0: Point(x: 503.31162501468725, y: 766.9016671863201),
      p1: Point(x: 504.2124710211739, y: 767.3358059574488),
    );
    final curve = CubicCurve(
      p0: Point(x: 505.16132944417086, y: 779.6305912206088),
      p1: Point(x: 503.19076843492786, y: 767.0872665416827),
      p2: Point(x: 503.3761460381431, y: 766.7563954079359),
      p3: Point(x: 503.3060153966664, y: 766.9140612367046),
    );
    final i = line.intersectionsWithCurve(curve);
    expect(i.length, 2);
    for (var $0 in i) {
      final d = distance(line.point(at: $0.t1), curve.point(at: $0.t2));
      expect(d < 1.0e-4, isTrue,
          reason:
              "distance line.compute(${$0.t1}) to curve.compute(${$0.t2}) = $d");
    }
  });

  test("IntersectionsCubicDegenerate", () {
    // this data caused issues in practice because because Utils.align would give an angle of zero for degenerate lines
    final c = CubicCurve(
      p0: Point(x: -1, y: 1),
      p1: Point(x: 0, y: -1),
      p2: Point(x: 1, y: -1),
      p3: Point(x: 2, y: 1),
    );
    final l = LineSegment(p0: Point(x: -1, y: 0), p1: Point(x: -1, y: 0));
    final i = l.intersectionsWithCurve(c);
    expect(i, []);
  });

  test("Equatable", () {
    final l1 =
        LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 3.0, y: 4.0));
    final l2 =
        LineSegment(p0: Point(x: 1.0, y: 3.0), p1: Point(x: 3.0, y: 4.0));
    final l3 =
        LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 3.0, y: 5.0));
    expect(l1, l1);
    expect(l1, isNot(l2));
    expect(l1, isNot(l3));
  });
}
