// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

part of 'bezier_curve.dart';

abstract interface class QuadraticCurveBase extends NonlinearBezierCurve {
  abstract Point p0, p1, p2;
}

class QuadraticCurve extends QuadraticCurveBase
    with
        QuadraticCurveImplicitizationMixin,
        BezierCurveIntersectionMixin,
        NonlinearBezierCurveIntersectionMixin,
        QuadraticCurvePolynomialMixin {
  @override
  Point p0, p1, p2;

  QuadraticCurve.fromList({required List<Point> points})
      : assert(points.length == 3),
        p0 = points[0].copyWith(),
        p1 = points[1].copyWith(),
        p2 = points[2].copyWith();

  QuadraticCurve({required this.p0, required this.p1, required this.p2});

  factory QuadraticCurve.fromLine(LineSegment lineSegment) {
    return QuadraticCurve(
      p0: lineSegment.p0,
      p1: (lineSegment.p0 + lineSegment.p1) * 0.5,
      p2: lineSegment.p1,
    );
  }

  @override
  QuadraticCurve copyWith({List<Point>? points}) {
    return QuadraticCurve.fromList(points: points ?? this.points);
  }

  ({LineSegment lineSegment, double error}) get downgradedToLineSegment {
    final line = LineSegment(p0: startingPoint, p1: endingPoint);
    final error = 0.5 * (p1 - line.point(at: 0.5)).length;
    return (lineSegment: line, error: error);
  }

  factory QuadraticCurve.from3Points({
    required Point start,
    required Point end,
    required Point mid,
    double t = 0.5,
  }) {
    // shortcuts, although they're really dumb
    if (t == 0) {
      return QuadraticCurve(p0: mid, p1: mid, p2: end);
    }

    if (t == 1) {
      return QuadraticCurve(p0: start, p1: mid, p2: mid);
    }

    // real fitting.
    final abc = Utils.getABC(n: 2, S: start, B: mid, E: end, t: t);
    return QuadraticCurve(p0: start, p1: abc.A, p2: end);
  }

  @override
  List<Point> get points {
    return [p0, p1, p2];
  }

  @override
  Point get startingPoint => p0;
  @override
  set startingPoint(Point newValue) => p0 = newValue;

  @override
  Point get endingPoint => p2;
  @override
  set endingPoint(Point newValue) => p2 = newValue;

  @override
  int get order => 2;

  @override
  bool get simple {
    if (p0 == p1 && p1 == p2) return true;
    final n1 = normal(at: 0);
    final n2 = normal(at: 1);
    final s = Utils.clamp(n1.dot(n2), -1.0, 1.0);
    final angle = acos(s).abs();
    return angle < (pi / 3.0);
  }

  @override
  Point normal({required double at}) {
    var d = derivative(at: at);
    if (d == Point.zero && (at == 0.0 || at == 1.0)) {
      if (at == 0.0) {
        d = p2 - p1;
      } else {
        d = p1 - p0;
      }
    }
    return d.perpendicular.normalize();
  }

  @override
  Point derivative({required double at}) {
    final double mt = 1 - at;
    final double k = 2;
    final p0 = (this.p1 - this.p0) * k;
    final p1 = (p2 - this.p1) * k;
    final a = mt;
    final b = at;
    return p0 * a + p1 * b;
  }

  @override
  QuadraticCurve split({required double from, required double to}) {
    if (from == 0.0 && to == 1.0) return this;
    final k = (to - from) / 2;
    final p0 = point(at: from);
    final p2 = point(at: to);
    final p1 =
        (p0 + p2) / 2 + (derivative(at: from) - derivative(at: to)) * k / 2;
    return QuadraticCurve(p0: p0, p1: p1, p2: p2);
  }

  @override
  ({BezierCurve left, BezierCurve right}) splitAt(double at) {
    // use "de Casteljau" iteration.
    final h0 = p0;
    final h1 = p1;
    final h2 = p2;
    final h3 = Utils.linearInterpolate(h0, h1, at);
    final h4 = Utils.linearInterpolate(h1, h2, at);
    final h5 = Utils.linearInterpolate(h3, h4, at);

    final leftCurve = QuadraticCurve(p0: h0, p1: h3, p2: h5);
    final rightCurve = QuadraticCurve(p0: h5, p1: h4, p2: h2);

    return (left: leftCurve, right: rightCurve);
  }

  @override
  ({Point point, double t}) project(Point point) {
    Point multiplyCoordinates(Point a, Point b) {
      return Point(x: a.x * b.x, y: a.y * b.y);
    }

    final q = copy(
        using:
            AffineTransform.translation(translationX: -point.x, y: -point.y));
    // p0, p1, p2, p3 form the control points of a cubic Bezier curve
    // created by multiplying the curve with its derivative
    final qd0 = q.p1 - q.p0;
    final qd1 = q.p2 - q.p1;
    final p0 = multiplyCoordinates(q.p0, qd0) * 3;
    final p1 =
        multiplyCoordinates(q.p0, qd1) + multiplyCoordinates(q.p1, qd0) * 2;
    final p2 =
        multiplyCoordinates(q.p2, qd0) + multiplyCoordinates(q.p1, qd1) * 2;
    final p3 = multiplyCoordinates(q.p2, qd1) * 3;
    final lengthSquaredStart = q.startingPoint.lengthSquared;
    final lengthSquaredEnd = q.endingPoint.lengthSquared;
    var minimumT = 0.0;
    var minimumDistanceSquared = lengthSquaredStart;
    if (lengthSquaredEnd < lengthSquaredStart) {
      minimumT = 1.0;
      minimumDistanceSquared = lengthSquaredEnd;
    }
    // the roots represent the values at which the curve and its derivative are perpendicular
    // ie, the dot product of q and l is equal to zero
    Utils.droots4(p0.x + p0.y, p1.x + p1.y, p2.x + p2.y, p3.x + p3.y,
        callback: (t) {
      if (t <= 0.0 || t >= 1.0) return;
      final point = q.point(at: t);
      final distanceSquared = point.lengthSquared;
      if (distanceSquared < minimumDistanceSquared) {
        minimumDistanceSquared = distanceSquared;
        minimumT = t;
      }
    });
    return (point: this.point(at: minimumT), t: minimumT);
  }

  @override
  BoundingBox get boundingBox {
    final p0 = this.p0;
    final p1 = this.p1;
    final p2 = this.p2;

    var mmin = Point.min(p0, p2);
    var mmax = Point.max(p0, p2);

    final d0 = p1 - p0;
    final d1 = p2 - p1;

    for (var d = 0; d < Point.dimensions; d++) {
      Utils.droots(d0[d], d1[d], callback: (t) {
        if (t <= 0.0 || t >= 1.0) return;
        final value = point(at: t)[d];
        if (value < mmin[d]) {
          mmin = mmin.copyWith(at: (d, value));
        } else if (value > mmax[d]) {
          mmax = mmax.copyWith(at: (d, value));
        }
      });
    }
    return BoundingBox.minMax(min: mmin, max: mmax);
  }

  @override
  Point point({required double at}) {
    if (at == 0) {
      return p0;
    } else if (at == 1) {
      return p2;
    }
    final mt = 1.0 - at;
    final mt2 = mt * mt;
    final t2 = at * at;
    final a = mt2;
    final b = mt * at * 2;
    final c = t2;
    // making the final sum one line of code makes XCode take forever to compiler! Hence the temporary variables.
    final temp1 = p0 * a;
    final temp2 = p1 * b;
    final temp3 = p2 * c;
    return temp1 + temp2 + temp3;
  }

  @override
  QuadraticCurve copy({required AffineTransform using}) {
    return QuadraticCurve(
      p0: p0.applying(using),
      p1: p1.applying(using),
      p2: p2.applying(using),
    );
  }

  @override
  QuadraticCurve reversed() {
    return QuadraticCurve(p0: p2, p1: p1, p2: p0);
  }

  @override
  double get flatnessSquared {
    final Point a = p1 * 2.0 - p0 - p2;
    return (1.0 / 16.0) * (a.x * a.x + a.y * a.y);
  }
}
