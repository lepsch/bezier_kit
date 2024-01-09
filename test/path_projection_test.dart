//
//  Path+ProjectionTests.swift
//  BezierKit
//
//  Created by Holmes Futrell on 11/23/20.
//  Copyright © 2020 Holmes Futrell. All rights reserved.
//

import 'dart:math';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

void main() {
  test("Projection", () {
    expect(Path().project(Point.zero), isNull,
        reason: "projection requires non-empty path.");
    final triangle1 = Path(components: [
      PathComponent.raw(points: [
        Point(x: 0, y: 2),
        Point(x: 2, y: 4),
        Point(x: 0, y: 4),
        Point(x: 0, y: 2)
      ], orders: List.filled(3, 1))
    ]);
    final triangle2 = Path(components: [
      PathComponent.raw(points: [
        Point(x: 2, y: 1),
        Point(x: 3, y: 1),
        Point(x: 3, y: 2),
        Point(x: 2, y: 1)
      ], orders: List.filled(3, 1))
    ]);
    final square = Path.fromRect(Rectangle(3, 3, 1, 1));
    final path = Path(
        components:
            triangle1.components + triangle2.components + square.components);
    final projection = path.project(Point(x: 2, y: 2));
    expect(projection, isNotNull);
    expect(projection!.location,
        IndexedPathLocation(componentIndex: 1, elementIndex: 2, t: 0.5));
    expect(projection.point, Point(x: 2.5, y: 1.5));
  }, skip: "Fix Path.project(Point) implementation.");

  test("projects onto the correct on-curve point", () {
    final b = QuadraticCurve(
      p0: Point(x: 0, y: 0),
      p1: Point(x: 100, y: 0),
      p2: Point(x: 100, y: 100),
    );
    final (:point, :t) = b.project(Point(x: 80, y: 20));
    expect(point, Point(x: 75, y: 25));
    expect(t, 0.5);
  });

  test("PointIsWithinDistanceOfBoundary", () {
    // a circle centered at origin with radius 1;
    final circlePath = Path(ellipseIn: Rectangle(-1.0, -1.0, 2.0, 2.0));

    final d = 0.1;
    final p1 = Point(x: -3.0, y: 0.0);
    final p2 = Point(x: -0.9, y: 0.9);
    final p3 = Point(x: 0.75, y: 0.75);
    final p4 = Point(x: 0.5, y: 0.5);

    // no, path bounding box isn't even within that distance
    expect(
        circlePath.pointIsWithinDistanceOfBoundary(p1, distance: d), isFalse);
    // no, within bounding box, but no individual curves are within that distance
    expect(
        circlePath.pointIsWithinDistanceOfBoundary(p2, distance: d), isFalse);
    // yes, one of the curves that makes up the circle is within that distance
    expect(circlePath.pointIsWithinDistanceOfBoundary(p3, distance: d), isTrue);
    // yes, so obviously within that distance implementation should early return yes
    expect(
        circlePath.pointIsWithinDistanceOfBoundary(p3, distance: 10.0), isTrue);
    // no, we are inside the path but too far from the boundary
    expect(
        circlePath.pointIsWithinDistanceOfBoundary(p4, distance: d), isFalse);
  });
}
