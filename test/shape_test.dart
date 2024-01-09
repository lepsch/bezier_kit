//
//  ShapeTests.swift
//  BezierKit
//
//  Created by Holmes Futrell on 1/13/18.
//  Copyright © 2018 Holmes Futrell. All rights reserved.
//

import 'dart:math';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

void main() {
  final testQuadCurve = QuadraticCurve(
      p0: Point(x: 0.0, y: 0.0),
      p1: Point(x: 1.0, y: 1.0),
      p2: Point(x: 1.0, y: 2.0));

  test("ShapeIntersection", () {
    final c1 =
        LineSegment(p0: Point(x: 0.0, y: 1.0), p1: Point(x: 1.0, y: 0.0));
    final c2 =
        LineSegment(p0: Point(x: 0.0, y: 1.0), p1: Point(x: 1.0, y: 2.0));
    final c3 =
        LineSegment(p0: Point(x: 0.0, y: 10.0), p1: Point(x: 1.0, y: 5.0));
    final si1 = ShapeIntersection(
        curve1: c1,
        curve2: c2,
        intersections: [Intersection(t1: 0.5, t2: 0.5)]);
    final si2 = ShapeIntersection(
        curve1: c1,
        curve2: c2,
        intersections: [Intersection(t1: 0.5, t2: 0.5)]);
    expect(si1, si2);
    var si3 = ShapeIntersection(
        curve1: c3,
        curve2: c2,
        intersections: [Intersection(t1: 0.5, t2: 0.5)]);
    expect(si1, isNot(si3)); // curve 1 doesn't match
    si3 = ShapeIntersection(
        curve1: c1,
        curve2: c3,
        intersections: [Intersection(t1: 0.5, t2: 0.5)]);
    expect(si1, isNot(si3)); // curve 2 doesn't match
    si3 = ShapeIntersection(curve1: c1, curve2: c2, intersections: []);
    expect(si1, isNot(si3)); // intersections don't match
  });

  test("Initializer", () {
    final forward = testQuadCurve.offset(distance: 2)[0];
    final back = testQuadCurve.offset(distance: -2)[0];
    final s = Shape(forward, back, false, false);
    expect(s.forward, forward);
    expect(s.back, back);
    expect(s.startcap.virtual, false);
    expect(s.startcap.curve,
        LineSegment(p0: back.endingPoint, p1: forward.startingPoint));
    expect(s.endcap.virtual, false);
    expect(s.endcap.curve,
        LineSegment(p0: forward.endingPoint, p1: back.startingPoint));
  });

  test("BoundingBox", () {
    final forward = testQuadCurve.offset(distance: 2)[0];
    final back = testQuadCurve.offset(distance: -2)[0];
    final s = Shape(forward, back, false, false);
    expect(s.boundingBox,
        BoundingBox.fromBox(first: forward.boundingBox, second: back.boundingBox));
  });

  test("Intersects", () {
    const epsilon = 1.0e-4;
    final line1 = LineSegment(p0: Point(x: -1, y: -1), p1: Point(x: 1, y: 1));
    final forward1 = line1.offset(distance: sqrt(2))[0];
    final back1 = line1.offset(distance: -sqrt(2))[0].reversed();
    final s1 = Shape(forward1, back1, true, true);

    final line2 =
        LineSegment(p0: Point(x: 1.0, y: 10.0), p1: Point(x: 1.0, y: -10.0));
    final forward2 = line2.offset(distance: 0.5)[0];
    final back2 = line2.offset(distance: -0.5)[0].reversed();
    final s2 = Shape(forward2, back2, false, false);

    final shapeIntersections = s1.intersects(shape: s2, accuracy: 1.0e-4);
    expect(shapeIntersections.length, 2);

    // check the first shape intersection
    expect(shapeIntersections[0].curve1, s1.back);
    expect(shapeIntersections[0].curve2, s2.forward);
    expect(shapeIntersections[0].intersections.length, 1);
    var p1 = shapeIntersections[0]
        .curve1
        .point(at: shapeIntersections[0].intersections[0].t1);
    var p2 = shapeIntersections[0]
        .curve2
        .point(at: shapeIntersections[0].intersections[0].t2);
    expect(distance(p1, p2), lessThan(epsilon));

    // check the 2nd shape intersection
    expect(shapeIntersections[1].curve1, s1.back);
    expect(shapeIntersections[1].curve2, s2.back);
    expect(shapeIntersections[1].intersections.length, 1);
    p1 = shapeIntersections[1]
        .curve1
        .point(at: shapeIntersections[1].intersections[0].t1);
    p2 = shapeIntersections[1]
        .curve2
        .point(at: shapeIntersections[1].intersections[0].t2);
    expect(distance(p1, p2), lessThan(epsilon));

    // test a non-intersecting case where bounding boxes overlap
    final s3 = LineSegment(p0: Point(x: -3, y: -3), p1: Point(x: 3, y: 3))
        .outlineShapes(distance: 1);
    expect(s1.intersects(shape: s3[0]), []);
    // test a non-intersecting case where bounding boxes do not overlap
    final s4 = LineSegment(p0: Point(x: -6, y: -6), p1: Point(x: -4, y: -4))
        .outlineShapes(distance: sqrt(2));
    expect(s1.intersects(shape: s4[0]), []);
  });

  test("Equatable", () {
    final a = Point(x: -1, y: 1);
    final b = Point(x: 1, y: 1);
    final c = Point(x: -1, y: -1);
    final d = Point(x: 1, y: -1);
    final cap1 = ShapeCap(curve: LineSegment(p0: a, p1: b), virtual: true);
    final cap2 = ShapeCap(curve: LineSegment(p0: a, p1: b), virtual: false);
    final cap3 = ShapeCap(curve: LineSegment(p0: b, p1: a), virtual: true);
    expect(cap1, isNot(cap2));
    expect(cap1, isNot(cap3));
    expect(cap1, cap1);
    final shape1 =
        Shape(LineSegment(p0: a, p1: b), LineSegment(p0: d, p1: c), true, true);
    final shape2 = Shape(
        LineSegment(p0: a, p1: b), LineSegment(p0: d, p1: c), false, true);
    final shape3 = Shape(
        LineSegment(p0: a, p1: b), LineSegment(p0: d, p1: c), true, false);
    final shape4 =
        Shape(LineSegment(p0: d, p1: c), LineSegment(p0: a, p1: b), true, true);
    expect(shape1, shape1);
    expect(shape1, isNot(shape2));
    expect(shape1, isNot(shape3));
    expect(shape1, isNot(shape4));
  });
}
