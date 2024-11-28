// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

part of 'bezier_curve.dart';

abstract interface class CubicCurveBase extends NonlinearBezierCurve {
  abstract Point p0, p1, p2, p3;
}

/// Cubic Bézier Curve
class CubicCurve extends CubicCurveBase
    with
        CubicCurvePolynomialMixin,
        NonlinearBezierCurveIntersectionMixin,
        BezierCurveIntersectionMixin,
        CubicCurveImplicitizationMixin,
        CubicCurveIntersectionMixin
    implements Transformable, Reversible {
  @override
  Point p0, p1, p2, p3;

  @override
  List<Point> get points => [p0, p1, p2, p3];

  @override
  int get order => 3;

  @override
  Point get startingPoint => p0;
  @override
  set startingPoint(Point newValue) => p0 = newValue;

  @override
  Point get endingPoint => p3;
  @override
  set endingPoint(Point newValue) => p3 = newValue;

  CubicCurve.fromList(List<Point> points)
      : assert(points.length == 4),
        p0 = points[0].copyWith(),
        p1 = points[1].copyWith(),
        p2 = points[2].copyWith(),
        p3 = points[3].copyWith();

  @override
  CubicCurve copyWith({List<Point>? points}) {
    return CubicCurve.fromList(points ?? this.points);
  }

  CubicCurve({
    required this.p0,
    required this.p1,
    required this.p2,
    required this.p3,
  });

  factory CubicCurve.fromLine(LineSegment lineSegment) {
    final oneThird = 1.0 / 3.0;
    final twoThirds = 2.0 / 3.0;
    return CubicCurve(
      p0: lineSegment.p0,
      p1: lineSegment.p0 * twoThirds + lineSegment.p1 * oneThird,
      p2: lineSegment.p0 * oneThird + lineSegment.p1 * twoThirds,
      p3: lineSegment.p1,
    );
  }

  factory CubicCurve.fromQuadratic(QuadraticCurve quadratic) {
    final oneThird = 1.0 / 3.0;
    final twoThirds = 2.0 / 3.0;
    return CubicCurve(
      p0: quadratic.p0,
      p1: quadratic.p1 * twoThirds + quadratic.p0 * oneThird,
      p2: quadratic.p2 * oneThird + quadratic.p1 * twoThirds,
      p3: quadratic.p2,
    );
  }

  ({QuadraticCurve quadratic, double error}) get downgradedToQuadratic {
    final line = LineSegment(p0: startingPoint, p1: endingPoint);
    final d1 = this.p1 - line.point(at: 1.0 / 3.0);
    final d2 = p2 - line.point(at: 2.0 / 3.0);
    final d = d1 * 0.5 + d2 * 0.5;
    final p1 = d * 1.5 + line.point(at: 0.5);
    final error = 0.144334 * (d1 - d2).length;
    final quadratic = QuadraticCurve(
      p0: line.startingPoint,
      p1: p1,
      p2: line.endingPoint,
    );
    return (quadratic: quadratic, error: error);
  }

  ({LineSegment lineSegment, double error}) get downgradedToLineSegment {
    final line = LineSegment(p0: startingPoint, p1: endingPoint);
    final d1 = p1 - line.point(at: 1.0 / 3.0);
    final d2 = p2 - line.point(at: 2.0 / 3.0);
    final dmaxx = max(d1.x * d1.x, d2.x * d2.x);
    final dmaxy = max(d1.y * d1.y, d2.y * d2.y);
    final error = 3 / 4 * sqrt(dmaxx + dmaxy);
    return (lineSegment: line, error: error);
  }

  /// Returns a CubicCurve which passes through three provided points: a starting point `start`, and ending point `end`, and an intermediate point `mid` at an optional t-value `t`.
  ///   - parameter start: the starting point of the curve
  ///   - parameter end: the ending point of the curve
  ///   - parameter mid: an intermediate point falling on the curve
  ///   - parameter t: optional t-value at which the curve will pass through the point `mid` (default = 0.5)
  ///   - parameter d: optional strut length with the full strut being length d * (1-t)/t. If omitted or `null` the distance from `mid` to the baseline (line from `start` to `end`) is used.
  factory CubicCurve.fromPoints3(
      {required Point start,
      required Point end,
      required Point mid,
      double t = 0.5,
      double? d}) {
    final s = start;
    final b = mid;
    final e = end;
    final oneMinusT = 1.0 - t;

    final abc = Utils.getABC(n: 3, S: s, B: b, E: e, t: t);

    final d1 = d ?? distance(b, abc.C);
    final d2 = d1 * oneMinusT / t;

    final selen = distance(start, end);
    final l = (e - s) * (1.0 / selen);
    final b1 = l * d1;
    final b2 = l * d2;

    // derivation of new hull coordinates
    final e1 = b - b1;
    final e2 = b + b2;
    final A = abc.A;
    final v1 = A + (e1 - A) / oneMinusT;
    final v2 = A + (e2 - A) / t;
    final nc1 = s + (v1 - s) / t;
    final nc2 = e + (v2 - e) / oneMinusT;
    // ...done
    return CubicCurve(p0: s, p1: nc1, p2: nc2, p3: e);
  }

  @override
  bool get simple {
    if (p0 == p1 && p1 == p2 && p2 == p3) return true;
    final a1 = Utils.angle(o: p0, v1: p3, v2: p1);
    final a2 = Utils.angle(o: p0, v1: p3, v2: p2);
    if (a1 > 0 && a2 < 0 || a1 < 0 && a2 > 0) {
      return false;
    }
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
        d = p2 - p0;
      } else {
        d = p3 - p1;
      }
      if (d == Point.zero) {
        d = p3 - p0;
      }
    }
    return d.perpendicular.normalize();
  }

  @override
  Point derivative({required double at}) {
    final mt = 1 - at;
    final k = 3.0;
    final p0 = (this.p1 - this.p0) * k;
    final p1 = (this.p2 - this.p1) * k;
    final p2 = (p3 - this.p2) * k;
    final a = mt * mt;
    final b = mt * at * 2;
    final c = at * at;
    // making the final sum one line of code makes XCode take forever to compiler! Hence the temporary variables.
    final temp1 = p0 * a;
    final temp2 = p1 * b;
    final temp3 = p2 * c;
    return temp1 + temp2 + temp3;
  }

  @override
  CubicCurve split({required double from, required double to}) {
    if (from == 0.0 && to == 1.0) return this;
    final k = (to - from) / 3.0;
    final p0 = point(at: from);
    final p3 = point(at: to);
    final p1 = p0 + derivative(at: from) * k;
    final p2 = p3 - derivative(at: to) * k;
    return CubicCurve(p0: p0, p1: p1, p2: p2, p3: p3);
  }

  @override
  ({BezierCurve left, BezierCurve right}) splitAt(double at) {
    final h0 = p0;
    final h1 = p1;
    final h2 = p2;
    final h3 = p3;
    final h4 = Utils.linearInterpolate(h0, h1, at);
    final h5 = Utils.linearInterpolate(h1, h2, at);
    final h6 = Utils.linearInterpolate(h2, h3, at);
    final h7 = Utils.linearInterpolate(h4, h5, at);
    final h8 = Utils.linearInterpolate(h5, h6, at);
    final h9 = Utils.linearInterpolate(h7, h8, at);

    final leftCurve = CubicCurve(p0: h0, p1: h4, p2: h7, p3: h9);
    final rightCurve = CubicCurve(p0: h9, p1: h8, p2: h6, p3: h3);

    return (left: leftCurve, right: rightCurve);
  }

  @override
  ({Point point, double t}) project(Point point) {
    Point mul(Point a, Point b) => Point(x: a.x * b.x, y: a.y * b.y);

    final c = copy(
        using:
            AffineTransform.translation(translationX: -point.x, y: -point.y));
    final q = QuadraticCurve(
      p0: this.p1 - this.p0,
      p1: this.p2 - this.p1,
      p2: this.p3 - this.p2,
    );
    // p0, p1, p2, p3 form the control points of a Cubic Bezier Curve formed
    // by multiplying the polynomials q and l
    final p0 = mul(c.p0, q.p0) * 10;
    final p1 = p0 + mul(c.p0, q.p1 - q.p0) * 4 + mul(c.p1 - c.p0, q.p0) * 6;
    final dd0 = mul(c.p2 - c.p1 * 2 + c.p0, q.p0) * 3 +
        mul(c.p1 - c.p0, q.p1 - q.p0) * 6 +
        mul(c.p0, q.p2 - q.p1 * 2 + q.p0);
    final p2 = p1 * 2 - p0 + dd0;
    //
    final p5 = mul(c.p3, q.p2) * 10;
    final p4 = p5 - mul(c.p3, q.p2 - q.p1) * 4 - mul(c.p3 - c.p2, q.p2) * 6;
    final dd1 = mul(c.p1 - c.p2 * 2 + c.p3, q.p2) * 3 +
        mul(c.p3 - c.p2, q.p2 - q.p1) * 6 +
        mul(c.p3, q.p2 - q.p1 * 2 + q.p0);
    final p3 = p4 * 2 - p5 + dd1;

    final lengthSquaredStart = c.p0.lengthSquared;
    final lengthSquaredEnd = c.p3.lengthSquared;
    var minimumT = 0.0;
    var minimumDistanceSquared = lengthSquaredStart;
    if (lengthSquaredEnd < lengthSquaredStart) {
      minimumT = 1.0;
      minimumDistanceSquared = lengthSquaredEnd;
    }
    // the roots represent the values at which the curve and its derivative are perpendicular
    // ie, the dot product of c and q is equal to zero
    final polynomial = BernsteinPolynomial5(
      b0: p0.x + p0.y,
      b1: p1.x + p1.y,
      b2: p2.x + p2.y,
      b3: p3.x + p3.y,
      b4: p4.x + p4.y,
      b5: p5.x + p5.y,
    );
    for (final t in findDistinctRootsInUnitInterval(of: polynomial)) {
      if (t <= 0.0 || t >= 1.0) break;
      final point = c.point(at: t);
      final distanceSquared = point.lengthSquared;
      if (distanceSquared < minimumDistanceSquared) {
        minimumDistanceSquared = distanceSquared;
        minimumT = t;
      }
    }
    return (point: this.point(at: minimumT), t: minimumT);
  }

  @override
  BoundingBox get boundingBox {
    final p0 = this.p0;
    final p1 = this.p1;
    final p2 = this.p2;
    final p3 = this.p3;

    var mmin = Point.min(p0, p3);
    var mmax = Point.max(p0, p3);

    final d0 = p1 - p0;
    final d1 = p2 - p1;
    final d2 = p3 - p2;

    for (var d = 0; d < Point.dimensions; d++) {
      final mmind = mmin[d];
      final mmaxd = mmax[d];
      final value1 = p1[d];
      final value2 = p2[d];
      if (value1 >= mmind &&
          value1 <= mmaxd &&
          value2 >= mmind &&
          value2 <= mmaxd) {
        continue;
      }
      Utils.droots3(d0[d], d1[d], d2[d], callback: (t) {
        if (t <= 0.0 || t >= 1.0) return;
        final value = point(at: t)[d];
        if (value < mmind) {
          mmin = mmin.copyWith(at: (d, value));
        } else if (value > mmaxd) {
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
      return p3;
    }
    final mt = 1.0 - at;
    final mt2 = mt * mt;
    final t2 = at * at;
    final a = mt2 * mt;
    final b = mt2 * at * 3.0;
    final c = mt * t2 * 3.0;
    final d = at * t2;
    // usage of temp variables are because of Swift Compiler error 'Expression was too complex to be solved in reasonable time; consider breaking up the expression into distinct sub extpressions'
    final temp1 = p0 * a;
    final temp2 = p1 * b;
    final temp3 = p2 * c;
    final temp4 = p3 * d;
    return temp1 + temp2 + temp3 + temp4;
  }

  @override
  CubicCurve copy({required AffineTransform using}) {
    return CubicCurve(
      p0: p0.applying(using),
      p1: p1.applying(using),
      p2: p2.applying(using),
      p3: p3.applying(using),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is CubicCurve) {
      return p0 == other.p0 &&
          p1 == other.p1 &&
          p2 == other.p2 &&
          p3 == other.p3;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(p0, p1, p2, p3);

  @override
  CubicCurve reversed() {
    return CubicCurve(p0: p3, p1: p2, p2: p1, p3: p0);
  }

  @override
  double get flatnessSquared {
    final a = p1 * 3.0 - p0 * 2.0 - p3;
    final b = p2 * 3.0 - p0 - p3 * 2.0;
    final temp1 = max(a.x * a.x, b.x * b.x);
    final temp2 = max(a.y * a.y, b.y * b.y);
    return (1.0 / 16.0) * (temp1 + temp2);
  }
}
