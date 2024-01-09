//
//  Utils.swift
//  BezierKit
//
//  Created by Holmes Futrell on 11/3/16.
//  Copyright © 2016 Holmes Futrell. All rights reserved.
//

import 'dart:math' hide Point;

import 'package:bezier_kit/src/bezier_curve.dart';
import 'package:bezier_kit/src/bezier_curve_internals.dart';
import 'package:bezier_kit/src/box.dart';
import 'package:bezier_kit/src/point.dart';
import 'package:bezier_kit/src/types.dart';
import 'package:collection/collection.dart';

extension SortedUniqueIterableExtension<Element extends Comparable>
    on List<Element> {
  Iterable<Element> sortedAndUniqued() {
    if (length <= 1) return this;

    return sorted((a, b) => a.compareTo(b))._duplicatesRemovedFromSorted();
  }

  Iterable<Element> _duplicatesRemovedFromSorted() {
    return fold<List<Element>>([], (previousValue, element) {
      if (previousValue.isEmpty || previousValue.last != element) {
        previousValue.add(element);
      }
      return previousValue;
    });
  }
}

class Utils {
  Utils._();

  static final List<List<double>> _binomialTable = [
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
    [1, 2, 1, 0, 0, 0, 0, 0, 0, 0],
    [1, 3, 3, 1, 0, 0, 0, 0, 0, 0],
    [1, 4, 6, 4, 1, 0, 0, 0, 0, 0],
    [1, 5, 10, 10, 5, 1, 0, 0, 0, 0],
    [1, 6, 15, 20, 15, 6, 1, 0, 0, 0],
    [1, 7, 21, 35, 35, 21, 7, 1, 0, 0],
    [1, 8, 28, 56, 70, 56, 28, 8, 1, 0],
    [1, 9, 36, 84, 126, 126, 84, 36, 9, 1]
  ];

  static double binomialCoefficient(int n, {required int choose}) {
    assert(n >= 0 && choose >= 0 && n <= 9 && choose <= 9);
    return _binomialTable[n][choose];
  }

  // float precision significant decimal
  static const epsilon = 1.0e-5;
  static const tau = 2.0 * pi;

  // Legendre-Gauss abscissae with n=24 (x_i values, defined at i=n as the roots of the nth order Legendre polynomial Pn(x))
  // ignore: constant_identifier_names
  static const _Tvalues = [
    -0.0640568928626056260850430826247450385909,
    0.0640568928626056260850430826247450385909,
    -0.1911188674736163091586398207570696318404,
    0.1911188674736163091586398207570696318404,
    -0.3150426796961633743867932913198102407864,
    0.3150426796961633743867932913198102407864,
    -0.4337935076260451384870842319133497124524,
    0.4337935076260451384870842319133497124524,
    -0.5454214713888395356583756172183723700107,
    0.5454214713888395356583756172183723700107,
    -0.6480936519369755692524957869107476266696,
    0.6480936519369755692524957869107476266696,
    -0.7401241915785543642438281030999784255232,
    0.7401241915785543642438281030999784255232,
    -0.8200019859739029219539498726697452080761,
    0.8200019859739029219539498726697452080761,
    -0.8864155270044010342131543419821967550873,
    0.8864155270044010342131543419821967550873,
    -0.9382745520027327585236490017087214496548,
    0.9382745520027327585236490017087214496548,
    -0.9747285559713094981983919930081690617411,
    0.9747285559713094981983919930081690617411,
    -0.9951872199970213601799974097007368118745,
    0.9951872199970213601799974097007368118745,
  ];

  // Legendre-Gauss weights with n=24 (w_i values, defined by a function linked to in the Bezier primer article)
  // ignore: constant_identifier_names
  static const Cvalues = [
    0.1279381953467521569740561652246953718517,
    0.1279381953467521569740561652246953718517,
    0.1258374563468282961213753825111836887264,
    0.1258374563468282961213753825111836887264,
    0.1216704729278033912044631534762624256070,
    0.1216704729278033912044631534762624256070,
    0.1155056680537256013533444839067835598622,
    0.1155056680537256013533444839067835598622,
    0.1074442701159656347825773424466062227946,
    0.1074442701159656347825773424466062227946,
    0.0976186521041138882698806644642471544279,
    0.0976186521041138882698806644642471544279,
    0.0861901615319532759171852029837426671850,
    0.0861901615319532759171852029837426671850,
    0.0733464814110803057340336152531165181193,
    0.0733464814110803057340336152531165181193,
    0.0592985849154367807463677585001085845412,
    0.0592985849154367807463677585001085845412,
    0.0442774388174198061686027482113382288593,
    0.0442774388174198061686027482113382288593,
    0.0285313886289336631813078159518782864491,
    0.0285313886289336631813078159518782864491,
    0.0123412297999871995468056670700372915759,
    0.0123412297999871995468056670700372915759,
  ];

  static ({Point A, Point B, Point C}) getABC({
    required int n,
    required Point S,
    required Point B,
    required Point E,
    double t = 0.5,
  }) {
    final u = projectionRatio(n: n, t: t);
    final um = 1 - u;
    final C = Point(x: u * S.x + um * E.x, y: u * S.y + um * E.y);
    final s = abcRatio(n: n, t: t);
    final A = Point(x: B.x + (B.x - C.x) / s, y: B.y + (B.y - C.y) / s);
    return (A: A, B: B, C: C);
  }

  static double abcRatio({required int n, double t = 0.5}) {
    // see ratio(t) note on http://pomax.github.io/bezierinfo/#abc
    assert(n == 2 || n == 3);
    if (t == 0 || t == 1) {
      return t;
    }
    final bottom = pow(t, n) + pow(1 - t, n);
    final top = bottom - 1;
    return (top / bottom).abs();
  }

  static double projectionRatio({required int n, double t = 0.5}) {
    // see u(t) note on http://pomax.github.io/bezierinfo/#abc
    assert(n == 2 || n == 3);
    if (t == 0 || t == 1) {
      return t;
    }
    final top = pow(1.0 - t, n);
    final bottom = pow(t, n) + top;
    return top / bottom;
  }

  static double map(double v, double ds, double de, double ts, double te) {
    final t = (v - ds) / (de - ds);
    return t * te + (1 - t) * ts;
  }

  static bool approximately(double a, double b, {required double precision}) {
    return (a - b).abs() <= precision;
  }

  static Point? linesIntersection(
      Point line1p1, Point line1p2, Point line2p1, Point line2p2) {
    final x1 = line1p1.x;
    final y1 = line1p1.y;
    final x2 = line1p2.x;
    final y2 = line1p2.y;
    final x3 = line2p1.x;
    final y3 = line2p1.y;
    final x4 = line2p2.x;
    final y4 = line2p2.y;
    final d = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if (d == 0 || !d.isFinite) return null;
    final a = x1 * y2 - y1 * x2;
    final b = x3 * y4 - y3 * x4;
    final n = (line2p1 - line2p2) * a - (line1p1 - line1p2) * b;
    return n * (1.0 / d);
  }

  // cube root function yielding real roots
  static double _crt(double v) {
    return (v < 0)
        ? -pow(-v, 1.0 / 3.0).toDouble()
        : pow(v, 1.0 / 3.0).toDouble();
  }

  static double clamp(double x, double a, double b) {
    assert(b >= a);
    if (x < a) {
      return a;
    } else if (x > b) {
      return b;
    } else {
      return x;
    }
  }

  static void droots4(
    double p0,
    double p1,
    double p2,
    double p3, {
    required void Function(double) callback,
  }) {
    // convert the points p0, p1, p2, p3 to a cubic polynomial at^3 + bt^2 + ct + 1 and solve
    // see http://www.trans4mind.com/personal_development/mathematics/polynomials/cubicAlgebra.htm
    final d = -p0 + 3 * p1 - 3 * p2 + p3;
    const smallValue = 1.0e-8;
    if (d.abs() < smallValue) {
      // solve the quadratic polynomial at^2 + bt + c instead
      final a = (3 * p0 - 6 * p1 + 3 * p2);
      final b = (-3 * p0 + 3 * p1);
      final c = p0;
      droots3(c, b / 2.0 + c, a + b + c, callback: callback);
      return;
    }
    final a = (3 * p0 - 6 * p1 + 3 * p2) / d;
    final b = (-3 * p0 + 3 * p1) / d;
    final c = p0 / d;
    final p = (3 * b - a * a) / 3;
    final q = (2 * a * a * a - 9 * a * b + 27 * c) / 27;
    final q2 = q / 2;
    final discriminant = q2 * q2 + p * p * p / 27;
    const tinyValue = 1.0e-14;
    if (discriminant < -tinyValue) {
      final r = sqrt(-p * p * p / 27);
      final t = -q / (2 * r);
      final cosphi = t < -1
          ? -1
          : t > 1
              ? 1
              : t;
      final phi = acos(cosphi);
      final crtr = _crt(r);
      final t1 = 2 * crtr;
      final root1 = t1 * cos((phi + tau) / 3) - a / 3;
      final root2 = t1 * cos((phi + 2 * tau) / 3) - a / 3;
      final root3 = t1 * cos(phi / 3) - a / 3;
      callback(root1);
      if (root2 > root1) {
        callback(root2);
      }
      if (root3 > root2) {
        callback(root3);
      }
    } else if (discriminant > tinyValue) {
      final sd = sqrt(discriminant);
      final u1 = _crt(-q2 + sd);
      final v1 = _crt(q2 + sd);
      callback(u1 - v1 - a / 3);
    } else if (!discriminant.isNaN) {
      final u1 = q2 < 0 ? _crt(-q2) : -_crt(q2);
      final root1 = 2 * u1 - a / 3;
      final root2 = -u1 - a / 3;
      if (root1 < root2) {
        callback(root1);
        callback(root2);
      } else if (root1 > root2) {
        callback(root2);
        callback(root1);
      } else {
        callback(root1);
      }
    }
  }

  static void droots3(
    double p0,
    double p1,
    double p2, {
    required void Function(double) callback,
  }) {
    // quadratic roots are easy
    // do something with each root
    final d = p0 - 2.0 * p1 + p2;
    if (!d.isFinite) return;
    if (d.abs() <= epsilon) {
      if (p0 != p1) {
        callback(0.5 * p0 / (p0 - p1));
      }
      return;
    }
    final radical = p1 * p1 - p0 * p2;
    if (radical < 0) return;
    final m1 = sqrt(radical);
    final m2 = p0 - p1;
    final v1 = (m2 + m1) / d;
    final v2 = (m2 - m1) / d;
    if (v1 < v2) {
      callback(v1);
      callback(v2);
    } else if (v1 > v2) {
      callback(v2);
      callback(v1);
    } else {
      callback(v1);
    }
  }

  static void droots(
    double p0,
    double p1, {
    required void Function(double) callback,
  }) {
    if (p0 == p1) return;
    callback(p0 / (p0 - p1));
  }

  static Point linearInterpolate(Point v1, Point v2, double t) {
    return v1 + (v2 - v1) * t;
  }

  static double linearInterpolateF(double first, double second, double t) {
    return (1 - t) * first + t * second;
  }

  static double arcfn(double t, Point Function(double t) derivativeFn) {
    final d = derivativeFn(t);
    return d.magnitude;
  }

  static double length(Point Function(double t) derivativeFn) {
    final z = 0.5;
    var sum = 0.0;
    var i = 0;
    for (final tValue in _Tvalues) {
      final t = z * tValue + z;
      sum += Utils.Cvalues[i] * Utils.arcfn(t, derivativeFn);
      i++;
    }
    return z * sum;
  }

  static double angle({
    required Point o,
    required Point v1,
    required Point v2,
  }) {
    final d1 = v1 - o;
    final d2 = v2 - o;
    return atan2(d1.cross(d2), d1.dot(d2));
  }

  static bool _shouldRecurse<C extends BezierCurve>({
    required Subcurve<C> subcurve,
    required Point boundingBoxSize,
    required double accuracy,
  }) {
    if (!subcurve.canSplit) return false;
    if (boundingBoxSize.x + boundingBoxSize.y < accuracy) return false;
    // if (MemoryLayout<double>.size == 4) {
    //   final curve = subcurve.curve;
    //   // limit recursion when we exceed Float32 precision
    //   final midPoint = curve.point(at: 0.5);
    //   if (midPoint == curve.startingPoint || midPoint == curve.endingPoint) {
    //     if (!curve.selfIntersects) return false;
    //   }
    // }
    return true;
  }

  static bool pairiteration<C1 extends BezierCurve, C2 extends BezierCurve>(
    Subcurve<C1> c1,
    Subcurve<C2> c2,
    BoundingBox c1b,
    BoundingBox c2b,
    List<Intersection> results,
    double accuracy,
    Box<int> totalIterations,
  ) {
    final maximumIterations = 900;
    final maximumIntersections = c1.curve.order * c2.curve.order;

    totalIterations.value += 1;
    if (totalIterations.value > maximumIterations) return false;
    if (results.length > maximumIntersections) return false;
    if (!c1b.overlaps(c2b)) return true;

    final shouldRecurse1 = _shouldRecurse(
        subcurve: c1, boundingBoxSize: c1b.size, accuracy: accuracy);
    final shouldRecurse2 = _shouldRecurse(
        subcurve: c2, boundingBoxSize: c2b.size, accuracy: accuracy);

    if (shouldRecurse1 == false && shouldRecurse2 == false) {
      // subcurves are small enough or we simply cannot recurse any more
      final l1 =
          LineSegment(p0: c1.curve.startingPoint, p1: c1.curve.endingPoint);
      final l2 =
          LineSegment(p0: c2.curve.startingPoint, p1: c2.curve.endingPoint);
      final intersection =
          l1.intersectionsWithLine(l2, checkCoincidence: false).firstOrNull;
      if (intersection == null) return true;
      final t1 = intersection.t1;
      final t2 = intersection.t2;
      results.add(Intersection(
          t1: t1 * c1.t2 + (1.0 - t1) * c1.t1,
          t2: t2 * c2.t2 + (1.0 - t2) * c2.t1));
    } else if (shouldRecurse1 && shouldRecurse2) {
      final cc1 = c1.splitAt(0.5);
      final cc2 = c2.splitAt(0.5);
      final cc1lb = cc1.left.curve.boundingBox;
      final cc1rb = cc1.right.curve.boundingBox;
      final cc2lb = cc2.left.curve.boundingBox;
      final cc2rb = cc2.right.curve.boundingBox;
      if (!Utils.pairiteration(cc1.left, cc2.left, cc1lb, cc2lb, results,
          accuracy, totalIterations)) {
        return false;
      }
      if (!Utils.pairiteration(cc1.left, cc2.right, cc1lb, cc2rb, results,
          accuracy, totalIterations)) {
        return false;
      }
      if (!Utils.pairiteration(cc1.right, cc2.left, cc1rb, cc2lb, results,
          accuracy, totalIterations)) {
        return false;
      }
      if (!Utils.pairiteration(cc1.right, cc2.right, cc1rb, cc2rb, results,
          accuracy, totalIterations)) {
        return false;
      }
    } else if (shouldRecurse1) {
      final cc1 = c1.splitAt(0.5);
      final cc1lb = cc1.left.curve.boundingBox;
      final cc1rb = cc1.right.curve.boundingBox;
      if (!Utils.pairiteration(
          cc1.left, c2, cc1lb, c2b, results, accuracy, totalIterations)) {
        return false;
      }
      if (!Utils.pairiteration(
          cc1.right, c2, cc1rb, c2b, results, accuracy, totalIterations)) {
        return false;
      }
    } else if (shouldRecurse2) {
      final cc2 = c2.splitAt(0.5);
      final cc2lb = cc2.left.curve.boundingBox;
      final cc2rb = cc2.right.curve.boundingBox;
      if (!Utils.pairiteration(
          c1, cc2.left, c1b, cc2lb, results, accuracy, totalIterations)) {
        return false;
      }
      if (!Utils.pairiteration(
          c1, cc2.right, c1b, cc2rb, results, accuracy, totalIterations)) {
        return false;
      }
    }
    return true;
  }

  static List<Point> hull(List<Point> p, double t) {
    final c = p.length;
    var q = p;
    // we linearInterpolate between all points (in-place), until we have 1 point left.
    var start = 0;
    for (final count in [for (var i = 1; i < c; i++) i].reversed) {
      final end = start + count;
      for (var i = start; i < end; i++) {
        final pt = Utils.linearInterpolate(q[i], q[i + 1], t);
        q.add(pt);
      }
      start = end + 1;
    }
    return q;
  }
}
