// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'dart:math';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  // length = 5
  final line1 =
      LineSegment(p0: Point(x: 1.0, y: 2.0), p1: Point(x: 5.0, y: 5.0));
  // length = 10
  final line2 =
      LineSegment(p0: Point(x: 5.0, y: 5.0), p1: Point(x: 13.0, y: -1.0));

  test("Length", () {
    final p = PathComponent(curves: [line1, line2]);
    expect(p.length, 15.0); // sum of two lengths
  });

  test("BoundingBox", () {
    final p = PathComponent(curves: [line1, line2]);
    // just the union of the two bounding boxes
    expect(
        p.boundingBox,
        BoundingBox.minMax(
            min: Point(x: 1.0, y: -1.0), max: Point(x: 13.0, y: 5.0)));
  });

  test("BoundingBoxOfPath", () {
    final point1 = Point(x: 3, y: -2);
    final pointComponent = PathComponent.raw(points: [point1], orders: [0]);
    expect(pointComponent.boundingBoxOfPath,
        BoundingBox(p1: Point(x: 3, y: -2), p2: Point(x: 3, y: -2)));

    final line = LineSegment(
      p0: Point(x: 1, y: 2),
      p1: Point(x: 5, y: 3),
    );

    final quadratic = QuadraticCurve(
      p0: Point(x: 5, y: 3),
      p1: Point(x: 4, y: 4),
      p2: Point(x: 3, y: 6),
    );

    final cubic = CubicCurve(
      p0: Point(x: 3, y: 6),
      p1: Point(x: 2, y: 5),
      p2: Point(x: -1, y: 4),
      p3: Point(x: 1, y: 2),
    );

    expect(PathComponent(curve: line).boundingBoxOfPath,
        BoundingBox(p1: Point(x: 1, y: 2), p2: Point(x: 5, y: 3)));
    expect(PathComponent(curve: quadratic).boundingBoxOfPath,
        BoundingBox(p1: Point(x: 3, y: 3), p2: Point(x: 5, y: 6)));
    expect(PathComponent(curve: cubic).boundingBoxOfPath,
        BoundingBox(p1: Point(x: -1, y: 2), p2: Point(x: 3, y: 6)));
    expect(PathComponent(curves: [line, quadratic, cubic]).boundingBoxOfPath,
        BoundingBox(p1: Point(x: -1, y: 2), p2: Point(x: 5, y: 6)));
  });

  test("Offset", () {
    // construct a PathComponent from a split cubic
    final q = QuadraticCurve(
        p0: Point(x: 0.0, y: 0.0),
        p1: Point(x: 2.0, y: 1.0),
        p2: Point(x: 4.0, y: 0.0));
    final (left: ql, right: qr) = q.splitAt(0.5);
    final p = PathComponent(curves: [ql, qr]);
    // test that offset gives us the same result as offsetting the split segments
    final pOffset = p.offset(distance: 1);
    expect(pOffset, isNotNull);

    for (final [c1, c2] in IterableZip(
        [pOffset!.curves, ql.offset(distance: 1) + qr.offset(distance: 1)])) {
      expect(c1, c2);
    }
  });

  final p1 = Point(x: 0.0, y: 1.0);
  final p2 = Point(x: 2.0, y: 1.0);
  final p3 = Point(x: 2.5, y: 0.5);
  final p4 = Point(x: 2.0, y: 0.0);
  final p5 = Point(x: 0.0, y: 0.0);
  final p6 = Point(x: -0.5, y: 0.25);
  final p7 = Point(x: -0.5, y: 0.75);
  final p8 = Point(x: 0.0, y: 1.0);

  test("Equatable", () {
    final l1 = LineSegment(p0: p1, p1: p2);
    final q1 = QuadraticCurve(p0: p2, p1: p3, p2: p4);
    final l2 = LineSegment(p0: p4, p1: p5);
    final c1 = CubicCurve(p0: p5, p1: p6, p2: p7, p3: p8);

    final pathComponent1 = PathComponent(curves: [l1, q1, l2, c1]);
    final pathComponent2 = PathComponent(curves: [l1, q1, l2]);
    final pathComponent3 = PathComponent(curves: [l1, q1, l2, c1]);

    var altC1 =
        c1.copyWith(points: c1.points..[2] = c1.points[2].copyWith(x: -0.25));
    final pathComponent4 = PathComponent(curves: [l1, q1, l2, altC1]);

    // pathComponent2 is missing 4th path element, so not equal
    expect(pathComponent1, isNot(pathComponent2));
    // same path elements means equal
    expect(pathComponent1, pathComponent3);
    // pathComponent4 has an element with a modified path
    expect(pathComponent1, isNot(pathComponent4));
  });

  test("IsEqual", () {
    final l1 = LineSegment(p0: p1, p1: p2);
    final q1 = QuadraticCurve(p0: p2, p1: p3, p2: p4);
    final l2 = LineSegment(p0: p4, p1: p5);
    final c1 = CubicCurve(p0: p5, p1: p6, p2: p7, p3: p8);

    final pathComponent1 = PathComponent(curves: [l1, q1, l2, c1]);
    final pathComponent2 = PathComponent(curves: [l1, q1, l2, c1]);
    var altC1 =
        c1.copyWith(points: c1.points..[2] = c1.points[2].copyWith(x: -0.25));
    final pathComponent3 = PathComponent(curves: [l1, q1, l2, altC1]);

    final string = "hello!";

    expect(pathComponent1, isNot(string));
    expect(pathComponent1, isNot(null));
    expect(pathComponent1, pathComponent1);
    expect(pathComponent1, pathComponent2);
    expect(pathComponent1, isNot(pathComponent3));
  });

  test("Hashing", () {
    // two PathComponents that are equal
    final l1 = LineSegment(p0: p1, p1: p2);
    final q1 = QuadraticCurve(p0: p2, p1: p3, p2: p4);
    final l2 = LineSegment(p0: p4, p1: p5);
    final c1 = CubicCurve(p0: p5, p1: p6, p2: p7, p3: p8);
    final pathComponent1 = PathComponent(curves: [l1, q1, l2, c1]);
    final pathComponent2 = PathComponent(curves: [l1, q1, l2, c1]);

    expect(pathComponent1.hashCode, pathComponent2.hashCode);

    // PathComponent that is equal should be located in a set
    final set = {pathComponent1};
    expect(set, contains(pathComponent2));
  });

  test("IndexedPathComponentLocation", () {
    final location1 = IndexedPathComponentLocation(elementIndex: 0, t: 0.5);
    final location2 = IndexedPathComponentLocation(elementIndex: 0, t: 1.0);
    final location3 = IndexedPathComponentLocation(elementIndex: 1, t: 0.0);
    expect(location1, lessThan(location2));
    expect(location1, lessThan(location3));
    expect(location3, isNot(lessThan(location1)));
    expect(location2, isNot(lessThan(location1)));
  });

  // just a single point
  final pointPathComponent =
      PathComponent.raw(points: [Point(x: 3.145, y: -8.34)], orders: [0]);
  final circlePathComponent =
      Path(ellipseIn: Rectangle(-1, -1, 2, 2)).components[0];

  test("StartingEndingPointAt", () {
    expect(circlePathComponent.startingPointForElement(at: 0),
        circlePathComponent.curves[0].startingPoint);
    expect(circlePathComponent.startingPointForElement(at: 2),
        circlePathComponent.curves[2].startingPoint);
    expect(circlePathComponent.endingPointForElement(at: 0),
        circlePathComponent.curves[0].endingPoint);
    expect(circlePathComponent.endingPointForElement(at: 2),
        circlePathComponent.curves[2].endingPoint);
  });

  test("SplitFromTo", () {
    // corner case, check that splitting a point always yields the same thin
    expect(
        pointPathComponent,
        pointPathComponent.split(
            from: IndexedPathComponentLocation(elementIndex: 0, t: 0.2),
            to: IndexedPathComponentLocation(elementIndex: 0, t: 0.8)));

    expect(circlePathComponent.startingIndexedLocation,
        IndexedPathComponentLocation(elementIndex: 0, t: 0));
    expect(circlePathComponent.endingIndexedLocation,
        IndexedPathComponentLocation(elementIndex: 3, t: 1.0));

    // check case of splitting a single path element
    final split1 = circlePathComponent.split(
        from: IndexedPathComponentLocation(elementIndex: 1, t: 0.3),
        to: IndexedPathComponentLocation(elementIndex: 1, t: 0.6));
    final expectedValue1 = PathComponent(
        curves: [circlePathComponent.element(at: 1).split(from: 0.3, to: 0.6)]);
    expect(split1, expectedValue1);

    // check case of splitting two path elements where neither is the complete element
    final split2 = circlePathComponent.split(
        from: IndexedPathComponentLocation(elementIndex: 1, t: 0.3),
        to: IndexedPathComponentLocation(elementIndex: 2, t: 0.6));
    final expectedValue2 = PathComponent(curves: [
      circlePathComponent.element(at: 1).split(from: 0.3, to: 1.0),
      circlePathComponent.element(at: 2).split(from: 0.0, to: 0.6)
    ]);
    expect(split2, expectedValue2);

    // check case of splitting where there is a full element in the middle
    final split3StartIndexedLocation =
        IndexedPathComponentLocation(elementIndex: 1, t: 0.3);
    final split3EndIndexedLocation =
        IndexedPathComponentLocation(elementIndex: 3, t: 0.6);
    final split3 = circlePathComponent.split(
        from: IndexedPathComponentLocation(elementIndex: 1, t: 0.3),
        to: IndexedPathComponentLocation(elementIndex: 3, t: 0.6));
    final expectedValue3 = PathComponent(curves: [
      circlePathComponent.element(at: 1).split(from: 0.3, to: 1.0),
      circlePathComponent.element(at: 2),
      circlePathComponent.element(at: 3).split(from: 0.0, to: 0.6)
    ]);
    expect(split3, expectedValue3);

    // misc cases for all code paths
    final split4 = circlePathComponent.split(
        from: IndexedPathComponentLocation(elementIndex: 3, t: 0),
        to: IndexedPathComponentLocation(elementIndex: 3, t: 1));
    final expectedValue4 =
        PathComponent(curves: [circlePathComponent.element(at: 3)]);
    expect(split4, expectedValue4);

    final split5 = circlePathComponent.split(
        from: IndexedPathComponentLocation(elementIndex: 1, t: 0),
        to: IndexedPathComponentLocation(elementIndex: 2, t: 0.5));
    final expectedValue5 = PathComponent(curves: [
      circlePathComponent.element(at: 1),
      circlePathComponent.element(at: 2).split(from: 0, to: 0.5)
    ]);
    expect(split5, expectedValue5);

    final split6 = circlePathComponent.split(
        from: IndexedPathComponentLocation(elementIndex: 1, t: 0.5),
        to: IndexedPathComponentLocation(elementIndex: 2, t: 1));
    final expectedValue6 = PathComponent(curves: [
      circlePathComponent.element(at: 1).split(from: 0.5, to: 1),
      circlePathComponent.element(at: 2)
    ]);
    expect(split6, expectedValue6);

    // check that reversing the order of start and end reverses the split curve
    final split3alt = circlePathComponent.split(
        from: split3EndIndexedLocation, to: split3StartIndexedLocation);
    expect(split3alt, expectedValue3.reversed());

    // check that splitting over the entire curve gives the same curve back
    final split7 = circlePathComponent.split(
        from: circlePathComponent.startingIndexedLocation,
        to: circlePathComponent.endingIndexedLocation);
    expect(split7, circlePathComponent);

    // check that if the starting location is at t=1 we do not create degenerate curves of length zero
    final split5alt = circlePathComponent.split(
        from: IndexedPathComponentLocation(elementIndex: 0, t: 1.0),
        to: IndexedPathComponentLocation(elementIndex: 2, t: 0.5));
    expect(split5alt, expectedValue5);

    // check that if the ending location is at t=0 we do not create degenerate curves of length zero
    final split6alt = circlePathComponent.split(
        from: IndexedPathComponentLocation(elementIndex: 1, t: 0.5),
        to: IndexedPathComponentLocation(elementIndex: 3, t: 0));
    expect(split6alt, expectedValue6);
  });

  test("EnumeratePoints", () {
    List<Point> arrayByEnumerating(
        {required PathComponent component,
        required bool includeControlPoints}) {
      final points = <Point>[];
      component.enumeratePoints(
          includeControlPoints: includeControlPoints,
          using: ($0) => points.add($0));
      return points;
    }

    expect(
        arrayByEnumerating(
            component: pointPathComponent, includeControlPoints: true),
        [pointPathComponent.startingPoint]);
    expect(
        arrayByEnumerating(
            component: pointPathComponent, includeControlPoints: false),
        [pointPathComponent.startingPoint]);

    final expectedCirclePoints = [
      Point(x: 1, y: 0),
      Point(x: 0, y: 1),
      Point(x: -1, y: 0),
      Point(x: 0, y: -1),
      Point(x: 1, y: 0)
    ];

    expect(
        arrayByEnumerating(
            component: circlePathComponent, includeControlPoints: false),
        expectedCirclePoints);
    expect(
        arrayByEnumerating(
            component: circlePathComponent, includeControlPoints: true),
        circlePathComponent.points);
  });
}
