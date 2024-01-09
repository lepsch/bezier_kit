//
//  TransformableTests.swift
//  BezierKit
//
//  Created by Holmes Futrell on 12/10/18.
//  Copyright © 2018 Holmes Futrell. All rights reserved.
//

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

void main() {
  // rotates by 90 degrees ccw and then shifts (-1, 1)
  final transform = AffineTransform(a: 0, b: 1, c: -1, d: 0, tx: -1, ty: 1);

  test("Transform", () {
    // test that the `transform` itself does what we think it does
    expect(Point(x: 1, y: 0).applying(transform), Point(x: -1, y: 2));
  });

  test("TransformLineSegment", () {
    final l = LineSegment(p0: Point(x: -1, y: -1), p1: Point(x: 3, y: 1));
    expect(l.copy(using: transform),
        LineSegment(p0: Point(x: 0, y: 0), p1: Point(x: -2, y: 4)));
  });

  test("TransformQuadraticCurve", () {
    final q = QuadraticCurve(
        p0: Point(x: -1, y: -1), p1: Point(x: 3, y: 1), p2: Point(x: 7, y: -1));
    expect(
        q.copy(using: transform),
        QuadraticCurve(
            p0: Point(x: 0, y: 0),
            p1: Point(x: -2, y: 4),
            p2: Point(x: 0, y: 8)));
  });

  test("TransformCubicCurve", () {
    final c = CubicCurve(
        p0: Point(x: -1, y: -1),
        p1: Point(x: 3, y: 1),
        p2: Point(x: 7, y: -1),
        p3: Point(x: 8, y: 0));
    expect(
        c.copy(using: transform),
        CubicCurve(
            p0: Point(x: 0, y: 0),
            p1: Point(x: -2, y: 4),
            p2: Point(x: 0, y: 8),
            p3: Point(x: -1, y: 9)));
  });

  test("TransformPathComponent", () {
    final line = LineSegment(p0: Point(x: -1, y: -1), p1: Point(x: 3, y: 1));
    final component = PathComponent(curves: [line]);
    final transformedComponent = component.copy(using: transform);
    expect(transformedComponent.curves.length, 1);
    expect(transformedComponent.curves.first as LineSegment,
        LineSegment(p0: Point(x: 0, y: 0), p1: Point(x: -2, y: 4)));
  });

  test("TransformPath", () {
    // just a simple path with two path components made up of line segments
    final l1 = LineSegment(p0: Point(x: -1, y: -1), p1: Point(x: 3, y: 1));
    final l2 = LineSegment(p0: Point(x: 1, y: 1), p1: Point(x: 2, y: 3));

    final path = Path(components: [
      PathComponent(curves: [l1]),
      PathComponent(curves: [l2])
    ]);

    final transformedPath = path.copy(using: transform);

    final expectedl1 =
        LineSegment(p0: Point(x: 0, y: 0), p1: Point(x: -2, y: 4));
    final expectedl2 =
        LineSegment(p0: Point(x: -2, y: 2), p1: Point(x: -4, y: 3));

    expect(transformedPath.components.length, 2);
    expect(transformedPath.components[0].numberOfElements, 1);
    expect(transformedPath.components[0].numberOfElements, 1);
    expect(transformedPath.components[0].element(at: 0) as LineSegment,
        expectedl1);
    expect(transformedPath.components[1].element(at: 0) as LineSegment,
        expectedl2);
  });
}
