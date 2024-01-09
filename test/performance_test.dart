//
//  PerformanceTests.swift
//  BezierKit
//
//  Created by Holmes Futrell on 5/3/21.
//  Copyright © 2021 Holmes Futrell. All rights reserved.
//

import 'dart:math';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:bezier_kit/src/mutable_path.dart';
import 'package:test/test.dart';

var rnd = Random();

List<CubicCurve> generateRandomCurves(
    {required int count, bool? selfIntersect, int? reseed}) {
  if (reseed != null) {
    // seed with zero so that "random" values are actually the same across test runs
    rnd = Random(reseed);
  }

  Point randomPoint() {
    final x = rnd.nextDouble();
    final y = rnd.nextDouble();
    return Point(x: x, y: y);
  }

  CubicCurve randomCurve() {
    return CubicCurve(
      p0: randomPoint(),
      p1: randomPoint(),
      p2: randomPoint(),
      p3: randomPoint(),
    );
  }

  var curves = <CubicCurve>[];
  while (curves.length < count) {
    final curve = randomCurve();
    if (selfIntersect == null || curve.selfIntersects == selfIntersect) {
      curves.add(curve);
    }
  }
  return curves;
}

Path parametricPath({
  required int numCurves,
  required double Function(double) theta,
  required double Function(double) dthetadt,
  required double Function(double) r,
  required double Function(double) drdt,
}) {
  Point p(double t) {
    return Point(x: r(t) * cos(theta(t)), y: r(t) * sin(theta(t)));
  }

  Point d(double t) {
    return Point(
        x: drdt(t) * cos(theta(t)) - r(t) * sin(theta(t)) * dthetadt(t),
        y: drdt(t) * sin(theta(t)) + r(t) * cos(theta(t)) * dthetadt(t));
  }

  var previousT = 0.0;
  var previousPoint = p(previousT);
  final delta = 1.0 / numCurves;
  final mPath = MutablePath();
  mPath.move(to: previousPoint);
  for (var i = 1; i <= numCurves; i++) {
    final nextT = i / numCurves;
    final nextPoint = p(nextT);
    mPath.addCurve(
      to: nextPoint,
      control1: previousPoint + d(previousT) * delta / 3.0,
      control2: nextPoint - d(nextT) * delta / 3.0,
    );
    previousPoint = nextPoint;
    previousT = nextT;
  }
  return mPath.toPath();
}

void main() {
  void measure(void Function() block) {
    final timer = Stopwatch()..start();
    block();
    print("measured ${timer.elapsed.inMilliseconds}ms");
  }

  test("CubicSelfIntersectionsPerformanceNoIntersect", () {
    // test the performance of `selfIntersections` when the curves DO NOT self-intersect
    // -Onone 0.036 seconds
    // -Os 0.004 seconds
    final dataCount = 100000;
    final curves =
        generateRandomCurves(count: dataCount, selfIntersect: false, reseed: 0);
    measure(() {
      var count = 0;
      for (final curve in curves) {
        count += curve.selfIntersections.length;
      }
      expect(count, 0);
    });
  });

  test("CubicSelfIntersectionsPerformanceYesIntersect", () {
    // test the performance of `selfIntersections` when the curves self-intersect
    // -Onone 0.048 seconds
    // -Os 0.014 seconds
    final dataCount = 100000;
    final curves =
        generateRandomCurves(count: dataCount, selfIntersect: true, reseed: 1);
    measure(() {
      var count = 0;
      for (final curve in curves) {
        count += curve.selfIntersections.length;
      }
      expect(count, dataCount);
    });
  });

  test("CubicIntersectionsPerformance", () {
    // test the performance of `intersections(with:,accuracy:)`
    // -Onone 0.57 seconds
    // -Os 0.075 seconds
    final dataCount = 50;
    final curves = generateRandomCurves(count: dataCount, reseed: 2);
    measure(() {
      var count = 0.0;
      for (final curve1 in curves) {
        for (final curve2 in curves) {
          count +=
              curve1.intersectionsWithCurve(curve2, accuracy: 1.0e-5).length;
        }
      }
    });
  });

  test("CubicIntersectionsPerformanceTangentEndpoint", () {
    // test the performance of `intersections(with:,accuracy:)`
    // -Onone 0.89 seconds
    // -Os 0.059 seconds
    final dataCount = 250;
    final curves = generateRandomCurves(count: dataCount, reseed: 3);
    measure(() {
      var count = 0.0;
      for (final curve1 in curves) {
        // create a curve that starts at the other curve's endpoint
        // and whose first tangent double's back on the curve
        // this is a difficult edge case for divide-and-conquer
        // algorithms
        final curve2 = CubicCurve(
            p0: curve1.endingPoint,
            p1: (curve1.p2 - curve1.p3) * rnd.nextDouble() + curve1.endingPoint,
            p2: Point(x: rnd.nextDouble(), y: rnd.nextDouble()),
            p3: Point(x: rnd.nextDouble(), y: rnd.nextDouble()));
        count += curve1.intersectionsWithCurve(curve2, accuracy: 1.0e-5).length;
      }
    });
  });

  test("QuadraticCurveProjectPerformance", () {
    final q = QuadraticCurve(
        p0: Point(x: -1, y: -1), p1: Point(x: 0, y: 2), p2: Point(x: 1, y: -1));
    measure(() {
      // roughly 0.043 -Onone, 0.022 with -Ospeed
      // if comparing with cubic performance, be sure to note `by` parameter in stride
      for (var theta = 0.0; theta < 2 * pi; theta += 0.0001) {
        q.project(Point(x: cos(theta), y: sin(theta)));
      }
    });
  });

  test("CubicCurveProjectPerformance", () {
    final c = CubicCurve(
        p0: Point(x: -1, y: -1),
        p1: Point(x: 3, y: 1),
        p2: Point(x: -3, y: 1),
        p3: Point(x: 1, y: -1));
    measure(() {
      // roughly 0.029 -Onone, 0.004 with -Ospeed
      for (var theta = 0.0; theta < 2 * pi; theta += 0.01) {
        c.project(Point(x: cos(theta), y: sin(theta)));
      }
    });
  });

  test("PathProjectPerformance", () {
    const k = 2.0 * pi * 10;
    const maxRadius = 100.0;
    double theta(double t) {
      return k * t;
    }

    double r(double t) {
      return t * maxRadius;
    }

    double drdt(double t) {
      return maxRadius;
    }

    double dthetadt(double t) {
      return k;
    }

    final spiral = parametricPath(
      numCurves: 100,
      theta: theta,
      dthetadt: dthetadt,
      r: r,
      drdt: drdt,
    );
    // about 0.31s in -Onone, 0.033s in -Ospeed
    measure(() {
      var pointsTested = 0;
      var totalDistance = 0.0;
      for (var x = -maxRadius; x <= maxRadius; x += 10) {
        for (var y = -maxRadius; y <= maxRadius; y += 10) {
          // print("($x, $y)")
          final point = Point(x: x, y: y);
          final projection = spiral.project(point)!.point;
          pointsTested += 1;
          totalDistance += distance(projection, point);
        }
      }
      // print("tested $pointsTested points, average distance from spiral = ${totalDistance / pointsTested})")
    });
  });

  test("PathSubtractionPerformance", () {
    Path circlePath({
      required Point origin,
      required double radius,
      required int numPoints,
    }) {
      final c = 0.551915024494 * radius * 4.0 / numPoints;
      var lastPoint = origin + Point(x: radius, y: 0.0);
      var lastTangent = Point(x: 0.0, y: c);
      final mPath = MutablePath();
      mPath.move(to: lastPoint);
      for (var i = 1; i <= numPoints; i++) {
        final theta = 2.0 * pi * (i % numPoints) / numPoints;
        final cosTheta = cos(theta);
        final sinTheta = sin(theta);
        final point = origin + Point(x: cosTheta, y: sinTheta) * radius;
        final tangent = Point(x: -sinTheta, y: cosTheta) * c;
        mPath.addCurve(
          to: point,
          control1: lastPoint + lastTangent,
          control2: point - tangent,
        );
        lastPoint = point;
        lastTangent = tangent;
      }
      return mPath.toPath();
    }

    final numPoints = 300;
    final path1 = circlePath(
        origin: Point(x: 0, y: 0), radius: 100, numPoints: numPoints);
    final path2 = circlePath(
        origin: Point(x: 1, y: 0), radius: 100, numPoints: numPoints);
    measure(() {
      // roughly 0.018s in debug mode
      path1.subtract(path2, accuracy: 1.0e-3);
    });
  });
}
