//
//  LineSegment.swift
//  BezierKit
//
//  Created by Holmes Futrell on 5/14/17.
//  Copyright © 2017 Holmes Futrell. All rights reserved.
//

part of 'bezier_curve.dart';

abstract interface class LineSegmentBase extends ImplicitizeableBezierCurve {
  abstract Point p0, p1;
}

class LineSegment extends LineSegmentBase
    with
        LineSegmentIntersectionMixin,
        BezierCurveIntersectionMixin,
        LineSegmentPolynomialMixin,
        LineSegmentImplicitizationMixin {
  @override
  Point p0, p1;

  LineSegment.fromList({required List<Point> points})
      : assert(points.length == 2),
        p0 = points[0].copyWith(),
        p1 = points[1].copyWith();

  @override
  LineSegment copyWith({List<Point>? points}) {
    return LineSegment.fromList(points: points ?? this.points);
  }

  LineSegment({required this.p0, required this.p1});

  @override
  List<Point> get points => [p0, p1];

  @override
  Point get startingPoint => p0;
  @override
  set startingPoint(Point newValue) => p0 = newValue;

  @override
  Point get endingPoint => p1;
  @override
  set endingPoint(Point newValue) => p1 = newValue;

  @override
  int get order => 1;

  @override
  bool get simple => true;

  @override
  Point derivative({required double at}) {
    return p1 - p0;
  }

  @override
  Point normal({required double at}) {
    return (p1 - p0).perpendicular.normalize();
  }

  @override
  LineSegment split({required double from, required double to}) {
    return LineSegment(p0: point(at: from), p1: point(at: to));
  }

  @override
  ({LineSegment left, LineSegment right}) splitAt(double at) {
    final mid = Utils.linearInterpolate(p0, p1, at);
    final left = LineSegment(p0: p0, p1: mid);
    final right = LineSegment(p0: mid, p1: p1);
    return (left: left, right: right);
  }

  @override
  BoundingBox get boundingBox {
    return BoundingBox.minMax(min: Point.min(p0, p1), max: Point.max(p0, p1));
  }

  @override
  Point point({required double at}) {
    if (at == 0) {
      return p0;
    } else if (at == 1) {
      return p1;
    } else {
      return Utils.linearInterpolate(p0, p1, at);
    }
  }

  @override
  double length() {
    return (p1 - p0).length;
  }

  @override
  ({List<double> x, List<double> y, List<double> all}) extrema() {
    return (x: [], y: [], all: []);
  }

  @override
  ({Point point, double t}) project(Point point) {
    // optimized implementation for line segments can be directly computed
    // default project implementation is found in BezierCurve protocol extension
    final relativePoint = point - p0;
    final delta = p1 - p0;
    final t =
        Utils.clamp(relativePoint.dot(delta) / delta.dot(delta), 0.0, 1.0);
    return (point: this.point(at: t), t: t);
  }

  @override
  LineSegment copy({required AffineTransform using}) {
    return LineSegment(p0: p0.applying(using), p1: p1.applying(using));
  }

  @override
  LineSegment reversed() {
    return LineSegment(p0: p1, p1: p0);
  }

  @override
  final flatnessSquared = 0.0;

  @override
  final flatness = 0.0;
}
