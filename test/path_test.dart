//
//  PathTest.swift
//  BezierKit
//
//  Created by Holmes Futrell on 8/1/18.
//  Copyright © 2018 Holmes Futrell. All rights reserved.
//

import 'dart:math';
import 'dart:typed_data';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:bezier_kit/src/mutable_path.dart';
import 'package:test/test.dart';

extension on double {
  double get nextUp {
    final raw = (Float64List(1)..first = this).buffer.asUint64List().first;
    final sign = raw & 0x8000000000000000 == 0 ? 1 : -1;
    var exponent = (raw & 0x7ff0000000000000) >> 52;
    var mantissa = raw & 0x000fffffffffffff;

    mantissa += 1;
    // overflow
    if (mantissa & 0xFFF0000000000000 != 0) {
      mantissa = 0;
      exponent += 1;
    }

    return Uint64List.fromList([sign * (exponent << 52 | mantissa)])
        .buffer
        .asFloat64List()
        .first;
  }
}

void main() {
  test("InitPathEmpty", () {
    // trivial test of an empty path
    final path = Path();
    expect(path.components, isEmpty);
  });

  test("InitPathRect", () {
    // simple test of a rectangle (note that this Path uses a moveTo())
    final rect = Rectangle(0, 0, 1, 2);
    final path1 = Path.fromRect(rect);

    final p1 = Point(x: 0.0, y: 0.0);
    final p2 = Point(x: 1.0, y: 0.0);
    final p3 = Point(x: 1.0, y: 2.0);
    final p4 = Point(x: 0.0, y: 2.0);

    expect(path1.components.length, 1);
    expect(path1.components[0].element(at: 0), LineSegment(p0: p1, p1: p2));
    expect(path1.components[0].element(at: 1), LineSegment(p0: p2, p1: p3));
    expect(path1.components[0].element(at: 2), LineSegment(p0: p3, p1: p4));
    expect(path1.components[0].element(at: 3), LineSegment(p0: p4, p1: p1));
  });

  test("InitPathEllipse", () {
    // test of a ellipse (4 cubic curves)
    final rect = Rectangle(0, 0, 1, 2);
    final path2 = Path(ellipseIn: rect);

    final p1 = Point(x: 1.0, y: 1.0);
    final p2 = Point(x: 0.5, y: 2.0);
    final p3 = Point(x: 0.0, y: 1.0);
    final p4 = Point(x: 0.5, y: 0.0);

    expect(path2.components.length, 1);
    expect(path2.components[0].numberOfElements, 4);
    expect(path2.components[0].element(at: 0).startingPoint, p1);
    expect(path2.components[0].element(at: 1).startingPoint, p2);
    expect(path2.components[0].element(at: 2).startingPoint, p3);
    expect(path2.components[0].element(at: 3).startingPoint, p4);
    expect(path2.components[0].element(at: 0).endingPoint, p2);
    expect(path2.components[0].element(at: 1).endingPoint, p3);
    expect(path2.components[0].element(at: 2).endingPoint, p4);
    expect(path2.components[0].element(at: 3).endingPoint, p1);
  });

  test("InitPathQuads", () {
    // test of a rect with some quad curves
    final p1 = Point(x: 0.0, y: 1.0);
    final p2 = Point(x: 2.0, y: 1.0);
    final p3 = Point(x: 3.0, y: 0.5);
    final p4 = Point(x: 2.0, y: 0.0);
    final p5 = Point(x: 0.0, y: 0.0);
    final p6 = Point(x: -1.0, y: 0.5);

    final mPath = MutablePath();
    mPath.move(to: p1);
    mPath.addLine(to: p2);
    mPath.addQuadCurve(to: p4, control: p3);
    mPath.addLine(to: p5);
    mPath.addQuadCurve(to: p1, control: p6);
    mPath.closeSubpath();

    final path3 = mPath.toPath();
    expect(path3.components.length, 1);
    expect(path3.components[0].numberOfElements, 4);
    expect(path3.components[0].element(at: 1),
        QuadraticCurve(p0: p2, p1: p3, p2: p4));
  });

  test("InitPathMultiplecomponents", () {
    // test of 2 line segments where each segment is started with a moveTo
    // this tests multiple components and starting new paths with moveTo instead of closePath
    final p1 = Point(x: 1.0, y: 2.0);
    final p2 = Point(x: 3.0, y: 5.0);
    final p3 = Point(x: -4.0, y: -1.0);
    final p4 = Point(x: 5.0, y: 3.0);

    final mPath = MutablePath();
    mPath.move(to: p1);
    mPath.addLine(to: p2);
    mPath.move(to: p3);
    mPath.addLine(to: p4);

    final path4 = mPath.toPath();
    expect(path4.components.length, 2);
    expect(path4.components[0].numberOfElements, 1);
    expect(path4.components[1].numberOfElements, 1);
    expect(path4.components[0].element(at: 0), LineSegment(p0: p1, p1: p2));
    expect(path4.components[1].element(at: 0), LineSegment(p0: p3, p1: p4));
  });

  test("GeometricProperties", () {
    // create a path with two components
    final path = () {
      final mutablePath = MutablePath();
      mutablePath.move(to: Point(x: 2, y: 1));
      mutablePath.addLine(to: Point(x: 3, y: 1));
      mutablePath.addQuadCurve(
          to: Point(x: 4, y: 2), control: Point(x: 4, y: 1));
      mutablePath.addCurve(
          to: Point(x: 2, y: 1),
          control1: Point(x: 4, y: 3),
          control2: Point(x: 2, y: 3));
      mutablePath.move(to: Point(x: 1, y: 1));
      return mutablePath.toPath();
    }();

    expect(path.components.length, 2);

    // test the first element of the first component, which is a line
    final lineLocation =
        IndexedPathLocation(componentIndex: 0, elementIndex: 0, t: 0);
    final expectedLinePosition = Point(x: 2, y: 1);
    final expectedLineDerivative = Point(x: 1, y: 0);
    final expectedLineNormal = Point(x: 0, y: 1);
    expect(path.point(at: lineLocation), expectedLinePosition);
    expect(path.components[0].point(at: lineLocation.locationInComponent),
        expectedLinePosition);
    expect(path.derivative(at: lineLocation), expectedLineDerivative);
    expect(path.components[0].derivative(at: lineLocation.locationInComponent),
        expectedLineDerivative);
    expect(path.normal(at: lineLocation), expectedLineNormal);
    expect(path.components[0].normal(at: lineLocation.locationInComponent),
        expectedLineNormal);

    // test the second element of the first component, which is a quad
    final quadraticLocation =
        IndexedPathLocation(componentIndex: 0, elementIndex: 1, t: 0.25);
    final expectedQuadraticPosition = Point(x: 3.4375, y: 1.0625);
    final expectedQuadraticDerivative = Point(x: 1.5, y: 0.5);
    final expectedQuadraticNormal = Point(x: -0.316, y: 0.949);
    expect(path.point(at: quadraticLocation), expectedQuadraticPosition);
    expect(path.components[0].point(at: quadraticLocation.locationInComponent),
        expectedQuadraticPosition);
    expect(path.derivative(at: quadraticLocation), expectedQuadraticDerivative);
    expect(
        path.components[0]
            .derivative(at: quadraticLocation.locationInComponent),
        expectedQuadraticDerivative);
    expect(
        distance(path.normal(at: quadraticLocation), expectedQuadraticNormal),
        lessThan(1.0e-2));
    expect(
        distance(
            path.components[0]
                .normal(at: quadraticLocation.locationInComponent),
            expectedQuadraticNormal),
        lessThan(1.0e-2));

    // test the third element of the first component, which is a cubic
    final cubicLocation =
        IndexedPathLocation(componentIndex: 0, elementIndex: 2, t: 1);
    final expectedCubicPosition = Point(x: 2, y: 1);
    final expectedCubicDerivative = Point(x: 0, y: -6);
    final expectedCubicNormal = Point(x: 1, y: 0);
    expect(path.point(at: cubicLocation), expectedCubicPosition);
    expect(path.components[0].point(at: cubicLocation.locationInComponent),
        expectedCubicPosition);
    expect(path.derivative(at: cubicLocation), expectedCubicDerivative);
    expect(path.components[0].derivative(at: cubicLocation.locationInComponent),
        expectedCubicDerivative);
    expect(path.normal(at: cubicLocation), expectedCubicNormal);
    expect(path.components[0].normal(at: cubicLocation.locationInComponent),
        expectedCubicNormal);

    // test the second component, which is just a point
    final firstComponentLocation =
        IndexedPathLocation(componentIndex: 1, elementIndex: 0, t: 0);
    final expectedPointPosition = Point(x: 1, y: 1);
    final expectedPointDerivative = Point.zero;
    expect(path.point(at: firstComponentLocation), expectedPointPosition);
    expect(
        path.components[1]
            .point(at: firstComponentLocation.locationInComponent),
        expectedPointPosition);
    expect(
        path.derivative(at: firstComponentLocation), expectedPointDerivative);
    expect(
        path.components[1]
            .derivative(at: firstComponentLocation.locationInComponent),
        expectedPointDerivative);
    expect(path.normal(at: firstComponentLocation).x, isNaN);
    expect(path.normal(at: firstComponentLocation).y, isNaN);
    expect(
        path.components[1]
            .normal(at: firstComponentLocation.locationInComponent)
            .x,
        isNaN);
    expect(
        path.components[1]
            .normal(at: firstComponentLocation.locationInComponent)
            .y,
        isNaN);
  });

  test("Intersections", () {
    // a circle centered at (3, 4) with radius 2;
    final circlePath = Path(ellipseIn: Rectangle(2.0, 3.0, 2.0, 2.0));
    final rectanglePath = Path.fromRect(Rectangle(3.0, 4.0, 2.0, 2.0));

    final intersections = rectanglePath
        .intersections(other: circlePath)
        .map(($0) => rectanglePath.point(at: $0.indexedPathLocation1));

    expect(intersections.length, 2);
    expect(intersections.contains(Point(x: 4.0, y: 4.0)), isTrue);
    expect(intersections.contains(Point(x: 3.0, y: 5.0)), isTrue);
  });

  test("SelfIntersectsEmptyPath", () {
    final emptyPath = Path();
    expect(emptyPath.selfIntersections(), []);
    expect(emptyPath.selfIntersects(), isFalse);
  });

  test("SelfIntersectionsSingleComponentPath", () {
    final singleComponentPath = () {
      final points = [
        Point(x: -1, y: 0),
        Point(x: 1, y: 0),
        Point(x: 1, y: 1),
        Point(x: 0, y: 1),
        Point(x: 0, y: -1),
        Point(x: -1, y: -1),
      ];
      final mPath = MutablePath();
      mPath.addLines(between: points);
      mPath.closeSubpath();
      return mPath.toPath();
    }();
    final expectedIntersection = PathIntersection(
      indexedPathLocation1:
          IndexedPathLocation(componentIndex: 0, elementIndex: 0, t: 0.5),
      indexedPathLocation2:
          IndexedPathLocation(componentIndex: 0, elementIndex: 3, t: 0.5),
    );
    expect(singleComponentPath.selfIntersections(), [expectedIntersection]);
  });

  test("SelfIntersectsMultiComponentPath", () {
    final multiComponentPath = () {
      final mPath = MutablePath();
      mPath.addRect(Rectangle(0, 0, 2, 4));
      mPath.addRect(Rectangle(1, 2, 2, 1));
      return mPath.toPath();
    }();
    final expectedIntersection1 = PathIntersection(
      indexedPathLocation1:
          IndexedPathLocation(componentIndex: 0, elementIndex: 1, t: 0.5),
      indexedPathLocation2:
          IndexedPathLocation(componentIndex: 1, elementIndex: 0, t: 0.5),
    );
    final expectedIntersection2 = PathIntersection(
      indexedPathLocation1:
          IndexedPathLocation(componentIndex: 0, elementIndex: 1, t: 0.75),
      indexedPathLocation2:
          IndexedPathLocation(componentIndex: 1, elementIndex: 2, t: 0.5),
    );
    expect(multiComponentPath.selfIntersections(),
        [expectedIntersection1, expectedIntersection2]);
  });

  test("IntersectsOpenPathEdgeCase", () {
    final openPath1 = Path(components: [
      PathComponent(
          curves: [LineSegment(p0: Point(x: 1, y: 3), p1: Point(x: 2, y: 5))])
    ]);
    final openPath2 = Path(components: [
      PathComponent(
          curves: [LineSegment(p0: Point(x: 2, y: 5), p1: Point(x: 9, y: 7))])
    ]);

    expect(openPath1.intersections(other: openPath2), [
      PathIntersection(
          indexedPathLocation1:
              IndexedPathLocation(componentIndex: 0, elementIndex: 0, t: 1),
          indexedPathLocation2:
              IndexedPathLocation(componentIndex: 0, elementIndex: 0, t: 0))
    ]);
    expect(openPath2.intersections(other: openPath1), [
      PathIntersection(
          indexedPathLocation1:
              IndexedPathLocation(componentIndex: 0, elementIndex: 0, t: 0),
          indexedPathLocation2:
              IndexedPathLocation(componentIndex: 0, elementIndex: 0, t: 1))
    ]);

    final closedPath1 = Path.fromRect(Rectangle(2, 5, 1, 1));
    expect(
      openPath1.intersections(other: closedPath1),
      [
        PathIntersection(
            indexedPathLocation1:
                IndexedPathLocation(componentIndex: 0, elementIndex: 0, t: 1),
            indexedPathLocation2:
                IndexedPathLocation(componentIndex: 0, elementIndex: 3, t: 1))
      ],
    );
  });

  test("SelfIntersectsOpenPathEdgeCase", () {
    final mPath = MutablePath();
    mPath.addLines(between: [
      Point(x: 0, y: 0),
      Point(x: 1, y: 0),
      Point(x: 0, y: 1),
      Point(x: 0, y: -1),
    ]);
    final openPath = mPath.toPath();
    expect(openPath.components.first.isClosed, isFalse);
    expect(
      openPath.selfIntersections(),
      [
        PathIntersection(
            indexedPathLocation1:
                IndexedPathLocation(componentIndex: 0, elementIndex: 0, t: 0),
            indexedPathLocation2:
                IndexedPathLocation(componentIndex: 0, elementIndex: 2, t: 0.5))
      ],
    );
  });

  test("Equatable", () {
    final rect = Rectangle(-1, -1, 2, 2);
    final path1 = Path.fromRect(rect);
    final path2 = Path(ellipseIn: rect);
    final path3 = Path.fromRect(rect);
    expect(path1, isNot(path2));
    expect(path1, path3);
  });

  test("IsEqual", () {
    final rect = Rectangle(-1, -1, 2, 2);
    final path1 = Path.fromRect(rect);
    final path2 = Path(ellipseIn: rect);
    final path3 = Path.fromRect(rect);

    final string = "hello";

    expect(path1, isNotNull);
    expect(path1, isNot(string));
    expect(path1, isNot(path2));
    expect(path1, path3);
  });

  test("Hashing", () {
    // two paths that are equal
    final rect = Rectangle(-1, -1, 2, 2);
    final path1 = Path.fromRect(rect);
    final path2 = Path.fromRect(rect);

    expect(path1.hashCode, path2.hashCode);

    // path that is equal should be located in a set
    final path3 = path1.copy(using: AffineTransform.identity);
    final set = {path1};
    expect(set, contains(path3));
  });

  test("EncodeDecode", () {
    final rect = Rectangle(-1, -1, 2, 2);
    final path = Path.fromRect(rect);
    final data = path.data;
    final decodedPath = Path.fromData(data);
    expect(decodedPath, path);
  });

  // - contains

  test("WindingCountBasic", () {
    final rect1 = Path.fromRect(Rectangle(-1, -1, 2, 2));
    final rect2 = Path.fromRect(Rectangle(-2, -2, 4, 4));
    final path = Path(components: rect1.components + rect2.components);
    // outside of both rects
    expect(path.windingCount(Point(x: -3, y: 0)), 0);
    // inside rect1 but outside rect2
    expect(path.windingCount(Point(x: -1.5, y: 0)), 1);
    // inside both rects
    expect(path.windingCount(Point(x: 0, y: 0)), 2);
  });

  test("WindingCountCornersNoAdjust", () {
    // test cases where winding count involves corners which should neither increment nor decrement the count
    final path1 = () {
      final temp = MutablePath();
      temp.addLines(between: [
        Point(x: 0, y: 0),
        Point(x: 2, y: 0),
        Point(x: 2, y: 2),
        Point(x: 1, y: 1),
        Point(x: 0, y: 2),
      ]);
      temp.closeSubpath();
      return temp.toPath();
    }();
    expect(path1.windingCount(Point(x: 1.5, y: 1)), 1);
    expect(path1.reversed().windingCount(Point(x: 1.5, y: 1)), -1);
    final path2 = () {
      final temp = MutablePath();
      temp.addLines(between: [
        Point(x: 0, y: 0),
        Point(x: 2, y: 0),
        Point(x: 2, y: 3),
        Point(x: 1, y: 1),
        Point(x: 0, y: 2),
      ]);
      temp.closeSubpath();
      return temp.toPath();
    }();
    expect(path2.windingCount(Point(x: 1, y: 2)), 0);
    expect(path2.reversed().windingCount(Point(x: 1, y: 2)), 0);
    // getting trickier ...
    final path3 = () {
      final temp = MutablePath();
      temp.addLines(between: [
        Point(x: 0, y: 0),
        Point(x: 4, y: 0),
        Point(x: 4, y: 2),
        Point(x: 1, y: 1),
        Point(x: 2, y: 4),
        Point(x: 0, y: 4),
      ]);
      temp.closeSubpath();
      return temp.toPath();
    }();
    expect(path3.windingCount(Point(x: 3, y: 1)), 1);
    expect(path3.reversed().windingCount(Point(x: 3, y: 1)), -1);
    final path4 = () {
      final temp = MutablePath();
      temp.addLines(between: [
        Point(x: 2, y: 0),
        Point(x: 4, y: 0),
        Point(x: 4, y: 4),
        Point(x: 2, y: 2),
        Point(x: 0, y: 3),
      ]);
      temp.closeSubpath();
      return temp.toPath();
    }();
    expect(path4.windingCount(Point(x: 2, y: 3)), 0);
    expect(path4.reversed().windingCount(Point(x: 2, y: 3)), 0);
  });

  test("WindingCountCornersYesAdjust", () {
    // test case(s) where winding count involves corners which should increment or decrement the count
    final path1 = () {
      final temp = MutablePath();
      temp.addLines(between: [
        Point(x: 0, y: 0),
        Point(x: 4, y: 0),
        Point(x: 2, y: 2),
        Point(x: 4, y: 4),
        Point(x: 0, y: 4),
      ]);
      temp.closeSubpath();
      return temp.toPath();
    }();
    expect(path1.windingCount(Point(x: 1, y: 2)), 1);
    expect(path1.windingCount(Point(x: 3, y: 2)), 0);
    expect(path1.reversed().windingCount(Point(x: 3, y: 2)), 0);
  });

  test("WindingCountExactlyParallel", () {
    final path1 = () {
      final temp = MutablePath();
      temp.addLines(between: [
        Point(x: 1, y: 0),
        Point(x: 2, y: 0),
        Point(x: 2, y: 2),
        Point(x: 0, y: 2),
        Point(x: 0, y: 1),
        Point(x: 1, y: 1),
      ]);
      temp.closeSubpath();
      return temp.toPath();
    }();
    expect(path1.windingCount(Point(x: 0.5, y: 0)), 0);
    expect(path1.windingCount(Point(x: 3, y: 0)), 0);
    expect(path1.windingCount(Point(x: 1.5, y: 1)), 1);
    expect(path1.windingCount(Point(x: 3, y: 1)), 0);
    expect(path1.windingCount(Point(x: 3, y: 2)), 0);
    final path2 =
        path1.copy(using: AffineTransform.scale(scaleX: 1, y: -1)).reversed();
    expect(path2.windingCount(Point(x: 0.5, y: 0)), 0);
    expect(path2.windingCount(Point(x: 3, y: 0)), 0);
    expect(path2.windingCount(Point(x: 1.5, y: -1)), 1);
    expect(path2.windingCount(Point(x: 3, y: -1)), 0);
    expect(path2.windingCount(Point(x: 3, y: -2)), 0);
  });

  test("WindingCountCusp", () {
    final path1 = () {
      final temp = MutablePath();
      temp.move(to: Point(x: 0, y: 0));
      temp.addCurve(
          to: Point(x: 1, y: -1),
          control1: Point(x: 2, y: 2),
          control2: Point(x: -1, y: 1));
      temp.closeSubpath();
      return temp.toPath();
    }();
    // at the bottom
    expect(path1.windingCount(Point(x: 0.5, y: -1)), 0);
    expect(path1.windingCount(Point(x: 1.5, y: -1)), 0);
    expect(path1.windingCount(Point(x: 4, y: -1)), 0);
    // between the y-coordinates of start and end
    expect(path1.windingCount(Point(x: 0.49, y: -0.5)), 0);
    expect(path1.windingCount(Point(x: 0.57, y: -0.5)), -1);
    expect(path1.windingCount(Point(x: 1, y: -0.5)), 0);
    expect(path1.windingCount(Point(x: 5, y: -0.5)), 0);
    // near the starting point
    expect(path1.windingCount(Point(x: 0.01, y: -0.02)), 0);
    expect(path1.windingCount(Point(x: 0.01, y: 0)), -1);
    expect(path1.windingCount(Point(x: 0.01, y: 0.02)), 0);
    // around the self-intersection (0.280, 0.296) t = 0.053589836, 0.74641013
    expect(path1.windingCount(Point(x: 0.279, y: 0.295)), 0);
    expect(path1.windingCount(Point(x: 0.280, y: 0.295)), -1);
    expect(path1.windingCount(Point(x: 0.281, y: 0.295)), 0);
    expect(path1.windingCount(Point(x: 0.279, y: 0.296)), 0);
    expect(path1.windingCount(Point(x: 0.280, y: 0.2961)), 1);
    expect(path1.windingCount(Point(x: 0.280, y: 0.2959)), -1);
    expect(path1.windingCount(Point(x: 0.281, y: 0.296)), 0);
    expect(path1.windingCount(Point(x: 0.279, y: 0.297)), 0);
    expect(path1.windingCount(Point(x: 0.280, y: 0.297)), 1);
    expect(path1.windingCount(Point(x: 0.281, y: 0.297)), 0);
    // intersecting the middle of the loop
    expect(path1.windingCount(Point(x: 0.9, y: 0.856)), 0);
    expect(path1.windingCount(Point(x: 0.6, y: 0.856)), 1);
    expect(path1.windingCount(Point(x: 0.1, y: 0.856)), 0);
    // around the y extrema (x : 0.6606065, y : 1.09017)
    final yExtrema = Point(x: 0.6606065, y: 1.09017);
    final smallValue = 1.0e-5;
    expect(path1.windingCount(yExtrema - Point(x: 0, y: smallValue)), 1);
    expect(path1.windingCount(yExtrema - Point(x: smallValue, y: 0)), 0);
    expect(path1.windingCount(yExtrema), 0);
    expect(path1.windingCount(yExtrema + Point(x: smallValue, y: 0)), 0);
    expect(path1.windingCount(yExtrema + Point(x: 4, y: 0)), 0);
    expect(path1.windingCount(yExtrema + Point(x: 0, y: smallValue)), 0);
  });

  test("WindingCountQuadratic", () {
    final path = () {
      final temp = MutablePath();
      temp.move(to: Point(x: 2, y: 1));
      temp.addQuadCurve(to: Point(x: 0, y: 0), control: Point(x: 3, y: 4));
      temp.closeSubpath();
      return temp.toPath();
    }();
    // curve has an x-extrema at t=0.75 (2.25, 2.0625)
    // curve has a y-extrema at t=0.5714286 (2.1224489, 2.285714285)
    // near the ending point
    expect(path.windingCount(Point(x: 0.1, y: 0)), 0);
    expect(path.windingCount(Point(x: 3, y: 0)), 0);
    expect(path.windingCount(Point(x: 0.99, y: 0.5)), 1);
    expect(path.windingCount(Point(x: 1.01, y: 0.5)), 0);
    // near the starting point
    expect(path.windingCount(Point(x: 1.99, y: 1)), 1);
    expect(path.windingCount(Point(x: 2.01, y: 1)), 0);
    // near the X extrema
    expect(path.windingCount(Point(x: 2.26, y: 2.0625)), 0);
    expect(path.windingCount(Point(x: 2.24, y: 2.0625)), 1);
    // near the Y extrema
    expect(path.windingCount(Point(x: 2.122449, y: 2.285713)), 1);
    expect(path.windingCount(Point(x: 2.121, y: 2.285714)), 0);
    expect(path.windingCount(Point(x: 2.123, y: 2.285714)), 0);
    expect(path.windingCount(Point(x: 2.122449, y: 2.285715)), 0);
  });

  test("WindingCountCornerCase", () {
    // tests a case where Utils.roots returns a root just slightly out of the range [0, 1]
    final path = () {
      final temp = MutablePath();
      temp.move(to: Point(x: 268.44162129797564, y: 24.268753616441533));
      temp.addCurve(
          to: Point(x: 259.9693035427533, y: 32.74107137166386),
          control1: Point(x: 268.44162129797564, y: 28.94788550837148),
          control2: Point(x: 264.6484354346833, y: 32.74107137166386));
      temp.addLine(to: Point(x: 259.9693035427533, y: 24.268753616441533));
      temp.closeSubpath();
      return temp.toPath();
    }();
    // next higher floating point from bottom of path;
    final y = 24.268753616441533.nextUp;
    expect(path.windingCount(Point(x: 268.5, y: y)), 0);
    expect(path.windingCount(Point(x: 268.3, y: y)), 1);
  });

  test("WindingCountRealWorldIssue", () {
    // real world data from a failure where droots was returning the roots in the wrong order
    // one of the curves has multiple y extrema so the ordering was important
    final path = () {
      final temp = MutablePath();
      temp.move(to: Point(x: 605.6715730157109, y: 281.5666590956511));
      temp.addCurve(
          to: Point(x: 599.1474827500521, y: 284.46530470516404),
          control1: Point(x: 604.6704341182384, y: 284.16867575842156),
          control2: Point(x: 601.7494994128225, y: 285.4664436026365));
      temp.addCurve(
          to: Point(x: 596.2488371405391, y: 277.9412144395052),
          control1: Point(x: 596.5454660872816, y: 283.4641658076916),
          control2: Point(x: 595.2476982430667, y: 280.5432311022756));
      temp.addCurve(
          to: Point(x: 606.4428758077357, y: 278.5450072177784),
          control1: Point(x: 596.0062816538538, y: 278.3028101006893),
          control2: Point(x: 598.025956346426, y: 275.00488126164095));
      temp.addCurve(
          to: Point(x: 602.1001649013623, y: 284.89151472375136),
          control1: Point(x: 606.9962089595965, y: 281.49675337615315),
          control2: Point(x: 605.051911059737, y: 284.3381815718906));
      temp.addCurve(
          to: Point(x: 595.7536573953893, y: 280.5488038173779),
          control1: Point(x: 599.1484187429876, y: 285.44484787561214),
          control2: Point(x: 596.30699054725, y: 283.5005499757526));
      temp.addCurve(
          to: Point(x: 605.6715730157109, y: 281.5666590956511),
          control1: Point(x: 604.099776075449, y: 283.7112442266403),
          control2: Point(x: 606.0305835805212, y: 280.9023900946232));
      return temp.toPath();
    }();
    final y = 281.4941677630135;
    expect(path.windingCount(Point(x: 595.8, y: y)), 0);
    expect(path.windingCount(Point(x: 596.1, y: y)), 1);
    expect(path.windingCount(Point(x: 597, y: y)), 2);
    // the point that was failing (reported 2 instead of 1)
    expect(path.windingCount(Point(x: 603.9411804326238, y: y)), 1);
    expect(path.windingCount(Point(x: 606, y: y)), 1);
    expect(path.windingCount(Point(x: 607, y: y)), 0);
  });

  test("ContainsSimple1", () {
    final rect = Rectangle(-1, -1, 2, 2);
    final path = Path.fromRect(rect);
    // the first point is outside the rectangle on the left
    expect(path.contains(Point(x: -2, y: 0)), isFalse);
    // the second point falls inside the rectangle
    expect(path.contains(Point(x: 0, y: 0)), isTrue);
    // the third point falls outside the rectangle on the right
    expect(path.contains(Point(x: 3, y: 0)), isFalse);
    // just *barely* in the rectangle
    expect(path.contains(Point(x: -0.99999, y: 0)), isTrue);
  });

  test("ContainsSimple2", () {
    final rect = Rectangle(-1, -1, 2, 2);
    final path = Path(ellipseIn: rect);
    // the first point is way outside the circle
    expect(path.contains(Point(x: 5, y: 5)), isFalse);
    // the second point is outside the circle, but within the bounding rect
    expect(path.contains(Point(x: -0.8, y: -0.8)), isFalse);
    // the third point falls inside the circle
    expect(path.contains(Point(x: 0.3, y: 0.3)), isTrue);

    // the 4th point falls inside the and is a tricky case when using the evenOdd fill mode because it aligns with two path elements exactly at y = 0
    expect(path.contains(Point(x: 0.5, y: 0.0), using: PathFillRule.evenOdd),
        isTrue);
    expect(path.contains(Point(x: 0.5, y: 0.0), using: PathFillRule.winding),
        isTrue);

    // the 5th point falls outside the circle, but drawing a horizontal line has a glancing blow with it
    expect(path.contains(Point(x: 0.1, y: 1.0), using: PathFillRule.evenOdd),
        isFalse);
    expect(path.contains(Point(x: 0.1, y: -1.0), using: PathFillRule.winding),
        isFalse);
  });

  test("ContainsStar", () {
    final starPoints = [
      for (var v = 0.0; v < 2.0 * pi; v += 0.4 * pi) Point(x: cos(v), y: sin(v))
    ];
    final mPath = MutablePath();

    mPath.move(to: starPoints[0]);
    mPath.addLine(to: starPoints[3]);
    mPath.addLine(to: starPoints[1]);
    mPath.addLine(to: starPoints[4]);
    mPath.addLine(to: starPoints[2]);
    mPath.closeSubpath();

    final path = mPath.toPath();

    // check a point outside of the star
    final outsidePoint = Point(x: 0.5, y: -0.5);
    expect(path.contains(outsidePoint, using: PathFillRule.evenOdd), isFalse);
    expect(path.contains(outsidePoint, using: PathFillRule.winding), isFalse);

    // using the winding rule, the center of the star is in the path, but with even-odd it's not
    expect(path.contains(Point.zero, using: PathFillRule.winding), isTrue);
    expect(path.contains(Point.zero, using: PathFillRule.evenOdd), isFalse);

    // check a point inside one of the star's arms
    final armPoint = Point(x: 0.9, y: 0.0);
    expect(path.contains(armPoint, using: PathFillRule.winding), isTrue);
    expect(path.contains(armPoint, using: PathFillRule.evenOdd), isTrue);

    // check the edge case of the star's corners
    for (var i = 0; i < 5; i++) {
      final point = starPoints[i] + Point(x: 0.1, y: 0.0);
      expect(path.contains(point, using: PathFillRule.evenOdd), isFalse,
          reason: "point $i");
      expect(path.contains(point, using: PathFillRule.winding), isFalse,
          reason: "point $i");
    }
  });

  test("ContainsCircleWithHole", () {
    final rect1 = Rectangle(-3, -3, 6, 6);
    final circlePath = Path(ellipseIn: rect1);
    final rect2 = Rectangle(-1, -1, 2, 2);
    final reversedCirclePath = Path(ellipseIn: rect2).reversed();
    final circleWithHole =
        Path(components: circlePath.components + reversedCirclePath.components);
    expect(
        circleWithHole.contains(Point(x: 0.0, y: 0.0),
            using: PathFillRule.evenOdd),
        isFalse);
    expect(
        circleWithHole.contains(Point(x: 0.0, y: 0.0),
            using: PathFillRule.winding),
        isFalse);
    expect(
        circleWithHole.contains(Point(x: 2.0, y: 0.0),
            using: PathFillRule.evenOdd),
        isTrue);
    expect(
        circleWithHole.contains(Point(x: 2.0, y: 0.0),
            using: PathFillRule.winding),
        isTrue);
    expect(
        circleWithHole.contains(Point(x: 4.0, y: 0.0),
            using: PathFillRule.evenOdd),
        isFalse);
    expect(
        circleWithHole.contains(Point(x: 4.0, y: 0.0),
            using: PathFillRule.winding),
        isFalse);
  });

  test("ContainsCornerCase", () {
    final mPath = MutablePath();
    final points = [
      Point(x: 0, y: 0),
      Point(x: 2, y: 1),
      Point(x: 1, y: 3),
      Point(x: -1, y: 2),
    ];
    mPath.addLines(between: points);
    mPath.closeSubpath();
    final rotatedSquare = mPath.toPath();
    // the square is rotated such that a horizontal line extended from `point1` or `point2` intersects the square
    // at an edge on one side but a corner on the other. If corners aren't handled correctly things can go wrong
    final squareCenter = Point(x: 0.5, y: 0.5);
    final point1 = Point(x: -0.75, y: 1);
    final point2 = Point(x: 1.75, y: 2);
    expect(rotatedSquare.contains(squareCenter), isTrue);
    expect(rotatedSquare.contains(point1), isFalse);
    expect(rotatedSquare.contains(point2), isFalse);
  });

  test("ContainsRealWorldEdgeCase", () {
    // an edge case which caused errors in practice because (rare!) line-curve intersections are found when bounding boxes do not even overlap
    final point = Point(x: 281.2936999253952, y: 221.7262912473492);
    final mPath = MutablePath();
    mPath.move(to: Point(x: 210.32116840649363, y: 106.4029658046467));
    mPath.addLine(to: Point(x: 195.80672765188274, y: 106.4029658046467));
    mPath.addLine(to: Point(x: 195.80672765188274, y: 221.7262912473492));
    mPath.addLine(
        to: Point(
            x: 273.5510327577471,
            y: 221.72629124734914)); // !!! precision issues comes from fact line is almost, but not perfectly horizontal
    mPath.addCurve(
        to: Point(x: 271.9933072984535, y: 214.38053683325302),
        control1: Point(x: 273.05768924540223, y: 219.26088569867528),
        control2: Point(x: 272.5391291486813, y: 216.81119916319818));
    mPath.addCurve(
        to: Point(x: 252.80681257385964, y: 162.18313232371986),
        control1: Point(x: 267.39734333475377, y: 195.3589483577662),
        control2: Point(x: 260.947626989152, y: 177.936810624913));
    mPath.addCurve(
        to: Point(x: 215.4444979991486, y: 111.76311400605556),
        control1: Point(x: 242.1552743057946, y: 142.6678463672315),
        control2: Point(x: 229.03183407884012, y: 126.09450622380493));
    mPath.addCurve(
        to: Point(x: 210.32116840649363, y: 106.4029658046467),
        control1: Point(x: 213.72825408056033, y: 109.93389850557801),
        control2: Point(x: 212.02163105179878, y: 108.14905966376985));
    final path = mPath.toPath();

    expect(path.boundingBox.contains(point),
        isFalse); // the point is not even in the bounding box of the path!
    expect(path.contains(point, using: PathFillRule.evenOdd), isFalse);
    expect(path.contains(point, using: PathFillRule.winding), isFalse);
  });

  test("ContainsRealWorldEdgeCase2", () {
    // this tests a real-world issue with contains. The y-coordinate of the point we are testing
    // is very close to one of our control points, which causes an intersection at t=1 *however*
    // there would be corresponding intersection with the next element at t=0
    final circlePath = () {
      final path = MutablePath();
      path.move(to: Point(x: 388.21266053072026, y: 461.1978951725547));
      path.addCurve(
          to: Point(x: 368.8204391162164, y: 479.3753548709112),
          control1: Point(x: 387.87721334546706, y: 471.5724761398741),
          control2: Point(x: 379.1950200835358, y: 479.7108020561644));

      path.addCurve(
          to: Point(x: 350.64297941785986, y: 459.98313345640736),
          control1: Point(x: 358.445858148897, y: 479.039907685658),
          control2: Point(x: 350.30753223260666, y: 470.35771442372675));
      path.addCurve(
          to: Point(x: 370.0352008323637, y: 441.80567375805083),
          control1: Point(x: 350.97842660311306, y: 449.60855248908797),
          control2: Point(x: 359.66061986504434, y: 441.4702265727976));
      path.addCurve(
          to: Point(x: 388.21266053072026, y: 461.1978951725547),
          control1: Point(x: 380.4097817996831, y: 442.14112094330403),
          control2: Point(x: 388.54810771597346, y: 450.8233142052353));
      return path.toPath();
    }();

    expect(
        circlePath.contains(Point(x: 369, y: 459), using: PathFillRule.evenOdd),
        isTrue);
    // this is one that would fail in practice
    expect(
        circlePath.contains(Point(x: 369, y: 459.9832416054124),
            using: PathFillRule.evenOdd),
        isTrue);
    expect(
        circlePath.contains(Point(x: 369, y: 458.9832416054124),
            using: PathFillRule.evenOdd),
        isTrue);
  });

  test("ContainsRealWorldEdgeCase3", () {
    // point has to be chosen carefully to fall inside path bounding box or else it's excluded trivially;
    final point = Point(x: 207, y: 60.09055464612847);
    final mPath = MutablePath();
    mPath.move(to: Point(x: 156.96601717963904, y: 61.6108671143393));
    mPath.addCurve(
        to: Point(x: 158.48632964784989, y: 60.090554646128446),
        control1: Point(x: 156.96601717963904, y: 60.77122172316883),
        control2: Point(x: 157.6466842566794, y: 60.090554646128446));
    mPath.addLine(to: Point(x: 206.74971723237456, y: 60.09055464612845));
    mPath.addCurve(
        to: Point(x: 207.35854749702355, y: 63.13117958255016),
        control1: Point(x: 206.9591702677613, y: 61.099707571074404),
        control2: Point(x: 207.16199497250045, y: 62.11301125588949));
    mPath.closeSubpath();
    final path = mPath.toPath();
    expect(path.contains(point, using: PathFillRule.evenOdd), isFalse);
  });

  test("ContainsEdgeCaseParallelDerivative", () {
    // this is a real-world edge case that can happen with round-rects
    final mPath = MutablePath();
    mPath.move(to: Point(x: 0.0, y: 1.0));
    // quad curve has derivative exactly horizontal at t=1
    mPath.addQuadCurve(to: Point(x: 1.0, y: 0.0), control: Point(x: 0, y: 0));
    mPath.addLine(to: Point(x: 2.0, y: -1.0e-5));
    mPath.addLine(to: Point(x: 4.0, y: 1));
    mPath.closeSubpath();
    final path = mPath.toPath();
    expect(path.contains(Point(x: 0.5, y: 0.5)), isTrue);
    expect(path.contains(Point(x: 3.0, y: 0.0)), isFalse);
  });

  test("ContainsPath", () {
    final rect1 = Path.fromRect(Rectangle(1, 1, 5, 5));
    // fully contained inside rect1
    final rect2 = Path.fromRect(Rectangle(2, 2, 3, 3));
    // starts inside, but not contained in rect1
    final rect3 = Path.fromRect(Rectangle(2, 2, 5, 3));
    // fully outside rect1
    final rect4 = Path.fromRect(Rectangle(7, 1, 5, 5));
    expect(rect1.containsPath(rect2), isTrue);
    expect(rect1.containsPath(rect3), isFalse);
    expect(rect1.containsPath(rect4), isFalse);
  });

  // TODO: more tests of contains path using .winding rule and where intersections are not crossings

  test("Offset", () {
    // ellipse with radius 1 centered at 1,1;
    final circle = Path(ellipseIn: Rectangle(0, 0, 2, 2));
    // should be roughly an ellipse with radius 2;
    final offsetCircle = circle.offset(distance: -1);
    expect(offsetCircle.components.length, 1);
    // make sure that the offsetting process created a series of elements that is *contiguous*
    final component = offsetCircle.components.first;
    final elementCount = component.numberOfElements;
    for (var i = 0; i < elementCount; i++) {
      expect(component.element(at: i).endingPoint,
          component.element(at: (i + 1) % elementCount).startingPoint);
    }
    // make sure that the offset circle is a actually circle, or, well, close to one
    const expectedRadius = 2.0;
    final expectedCenter = Point(x: 1.0, y: 1.0);
    for (var i = 0; i < offsetCircle.components[0].numberOfElements; i++) {
      final c = offsetCircle.components[0].element(at: i);
      for (final p in c.lookupTable(steps: 10)) {
        final radius = distance(p, expectedCenter);
        final percentError =
            100.0 * (radius - expectedRadius).abs() / expectedRadius;
        expect(percentError, lessThan(0.1),
            reason:
                "expected offset circle to have radius $expectedRadius, but there's a point distance ${distance(p, expectedCenter)} from the expected center.");
      }
    }
  });

  test("OffsetDegenerate", () {
    // this can actually happen in practice if the path is created from a circle with zero radius
    final point = Point(x: 245.2276926738644, y: 76.62374839782714);
    final curve = CubicCurve(p0: point, p1: point, p2: point, p3: point);
    final path =
        Path(components: [PathComponent(curves: List.filled(4, curve))]);
    final result = path.offset(distance: 1);
    expect(result.isEmpty, isTrue);
  });

  test("DisjointComponentsNesting", () {
    expect(Path().disjointComponents(), []);
    // test that a simple square just gives the same square back
    final squarePath = Path.fromRect(Rectangle(0, 0, 7, 7));
    final result1 = squarePath.disjointComponents();
    expect(result1.length, 1);
    expect(squarePath, result1.first);
    // test that a square with a hole associates the hole correctly with the square
    final squareWithHolePath = () {
      final hole = Path.fromRect(Rectangle(1, 1, 5, 5)).reversed();
      return Path(components: squarePath.components + hole.components);
    }();
    final result2 = squareWithHolePath.disjointComponents();
    expect(result2.length, 1);
    expect(squareWithHolePath, result2.first);
    // test that nested paths correctly produce two paths
    final pegPath = Path.fromRect(Rectangle(2, 2, 3, 3));
    final squareWithPegPath =
        Path(components: squareWithHolePath.components + pegPath.components);
    final result3 = squareWithPegPath.disjointComponents();
    expect(result3.length, 2);
    expect(result3.contains(squareWithHolePath), isTrue);
    expect(result3.contains(pegPath), isTrue);
    // test a trickier case: a square with a hole, nested inside a square with a hole
    final pegWithHolePath = () {
      final hole = Path.fromRect(Rectangle(3, 3, 1, 1)).reversed();
      return Path(components: pegPath.components + hole.components);
    }();
    final squareWithPegWithHolePath = Path(
        components: squareWithHolePath.components + pegWithHolePath.components);
    final result4 = squareWithPegWithHolePath.disjointComponents();
    expect(result4.length, 2);
    expect(result4.contains(squareWithHolePath), isTrue);
    expect(result4.contains(pegWithHolePath), isTrue);
  });

  test("DisjointComponentsWindingBackwards", () {
    final innerSquare = Path.fromRect(Rectangle(2, 2, 1, 1));
    final hole = Path.fromRect(Rectangle(1, 1, 3, 3)).reversed();
    final outerSquare = Path.fromRect(Rectangle(0, 0, 5, 5));
    final path = Path(
        components:
            innerSquare.components + outerSquare.components + hole.components);

    final disjointPaths = path.disjointComponents();

    // it's expected that disjointComponents should separate the path into
    // the outer square plus hole as one path, and the inner square as another
    final outerSquareWithHole =
        Path(components: outerSquare.components + hole.components);
    final expectedPaths = [outerSquareWithHole, innerSquare];

    expect(disjointPaths.length, expectedPaths.length);
    for (var $0 in expectedPaths) {
      expect(disjointPaths.contains($0), isTrue);
    }
  });

  test("BoundingBoxOfPath", () {
    expect(Path().boundingBoxOfPath, BoundingBox.empty);
    final quad1 = QuadraticCurve(
        p0: Point(x: 1, y: 2), p1: Point(x: 2, y: 4), p2: Point(x: 3, y: 2));
    final quad2 = QuadraticCurve(
        p0: Point(x: 3, y: 2), p1: Point(x: 2, y: 0), p2: Point(x: 1, y: 2));
    final path1 = Path.fromCurve(quad1);
    expect(path1.boundingBoxOfPath,
        BoundingBox(p1: Point(x: 1, y: 2), p2: Point(x: 3, y: 4)));
    final path2 = Path(components: [
      PathComponent(curve: quad1),
      PathComponent(curve: quad2),
    ]);
    expect(path2.boundingBoxOfPath,
        BoundingBox(p1: Point(x: 1, y: 0), p2: Point(x: 3, y: 4)));
  });

  test("NSCoder", () {
    // just some random curves, but we ensure they're continuous
    final l1 = LineSegment(
        p0: Point(x: 4.9652, y: 8.2774), p1: Point(x: 3.8449, y: 4.9902));
    final q1 = QuadraticCurve(
        p0: Point(x: 3.8449, y: 4.9902),
        p1: Point(x: 4.0766, y: 7.0715),
        p2: Point(x: 7.7088, y: 8.6246));
    final l2 = LineSegment(
        p0: Point(x: 7.7088, y: 8.6246), p1: Point(x: 3.6054, y: 3.0114));
    final c1 = CubicCurve(
        p0: Point(x: 3.6054, y: 3.0114),
        p1: Point(x: 6.9423, y: 2.5472),
        p2: Point(x: 3.2955, y: 9.4288),
        p3: Point(x: 1.8175, y: 6.9295));
    final path = Path(components: [
      PathComponent(curves: [l1, q1, l2, c1])
    ]);

    final data = path.data;
    final decodedPath = Path.fromData(data);
    expect(path, decodedPath);
  });

  test("IndexedPathLocation", () {
    final location1 =
        IndexedPathLocation(componentIndex: 0, elementIndex: 1, t: 0.5);
    final location2 =
        IndexedPathLocation(componentIndex: 0, elementIndex: 1, t: 1.0);
    final location3 =
        IndexedPathLocation(componentIndex: 0, elementIndex: 2, t: 0.0);
    final location4 =
        IndexedPathLocation(componentIndex: 1, elementIndex: 0, t: 0.0);
    final location5 = IndexedPathLocation.fromComponent(
        componentIndex: location4.componentIndex,
        locationInComponent: location4.locationInComponent);
    expect(location1, lessThan(location2));
    expect(location1, lessThan(location3));
    expect(location1, lessThan(location4));
    // no! t is greater
    expect(location2, greaterThanOrEqualTo(location1));
    // no! element index is greater
    expect(location3, greaterThanOrEqualTo(location1));
    // no! component index is greater
    expect(location4, greaterThanOrEqualTo(location1));
    expect(
        location1.locationInComponent,
        IndexedPathComponentLocation(
            elementIndex: location1.elementIndex, t: location1.t));
    expect(location4, location5);
  });
}
