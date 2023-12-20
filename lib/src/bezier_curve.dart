//
//  BezierCurve.swift
//  BezierKit
//
//  Created by Holmes Futrell on 2/19/17.
//  Copyright © 2017 Holmes Futrell. All rights reserved.
//

// extension Subcurve: Equatable where CurveType: Equatable {
//     // extension exists for automatic Equatable synthesis
// }

import 'dart:math';

import 'package:bezier_kit/src/affine_transform.dart';
import 'package:bezier_kit/src/bezier_curve_implicitization.dart';
import 'package:bezier_kit/src/bezier_curve_internals.dart';
import 'package:bezier_kit/src/bezier_curve_polynomial.dart';
import 'package:bezier_kit/src/box.dart';
import 'package:bezier_kit/src/point.dart';
import 'package:bezier_kit/src/polynomial.dart';
import 'package:bezier_kit/src/root_finding.dart';
import 'package:bezier_kit/src/types.dart';
import 'package:bezier_kit/src/utils.dart';
import 'package:collection/collection.dart';

part 'bezier_curve_intersection.dart';
part 'line_segment.dart';
part 'cubic_curve.dart';
part 'quadratic_curve.dart';

extension BezierCurveExtension on BezierCurve {
//     // MARK: -

//     // MARK: - outlines

//      func outline(distance double d1) -> PathComponent {
//         return internalOutline(d1: d1, d2: d1)
//     }

//      func outline(distanceAlongNormal double d1, distanceOppositeNormal double d2) -> PathComponent {
//         return internalOutline(d1: d1, d2: d2)
//     }

//     private func internalOutline(double d1, double d2) -> PathComponent {
//         final reduced = this.reduce();
//         final length = reduced.length;
//         var forwardCurves: List<BezierCurve> = reduced.compactMap { $0.curve.scale(distance: d1) }
//         var backCurves: List<BezierCurve> = reduced.compactMap { $0.curve.scale(distance: -d2) }
//         _ensureContinuous(&forwardCurves)
//         _ensureContinuous(&backCurves)
//         // reverse the "return" outline
//         backCurves = backCurves.reversed().map { $0.reversed() }
//         // form the endcaps as lines
//         final forwardStart = forwardCurves[0].points[0];
//         final forwardEnd = forwardCurves[length-1].points[forwardCurves[length-1].points.length-1];
//         final backStart = backCurves[length-1].points[backCurves[length-1].points.length-1];
//         final backEnd = backCurves[0].points[0];
//         final lineStart = LineSegment(p0: backStart, p1: forwardStart);
//         final lineEnd = LineSegment(p0: forwardEnd, p1: backEnd);
//         final segments = [lineStart] + forwardCurves + [lineEnd] + backCurves;
//         return PathComponent(curves: segments)
//     }

//     // MARK: shapes

//      func outlineShapes(distance double d1, accuracy: double = defaultIntersectionAccuracy) -> [Shape] {
//         return this.outlineShapes(distanceAlongNormal: d1, distanceOppositeNormal: d1, accuracy: accuracy)
//     }

//      func outlineShapes(distanceAlongNormal double d1, distanceOppositeNormal double d2, accuracy: double = defaultIntersectionAccuracy) -> [Shape] {
//         final outline = this.outline(distanceAlongNormal: d1, distanceOppositeNormal: d2);
//         var shapes: [Shape] = []
//         final len = outline.numberOfElements;
//         for i in 1..<len/2 {
//             final shape = Shape(outline.element(at: i), outline.element(at: len-i), i > 1, i < len/2-1);
//             shapes.add(shape)
//         }
//         return shapes
//     }
}

const defaultIntersectionAccuracy = 0.5;
const reduceStepSize = 0.01;

abstract interface class BoundingBoxProtocol {
  BoundingBox get boundingBox;
}

abstract interface class Transformable {
  Transformable copy({required AffineTransform using});
}

abstract interface class Reversible {
  Reversible reversed();
}

sealed class BezierCurve
    with FlatnessMixin
    implements BoundingBoxProtocol, Transformable, Reversible {
  bool get simple;
  List<Point> get points;
  Point get startingPoint;
  set startingPoint(Point value);
  Point get endingPoint;
  set endingPoint(Point value);
  int get order;
  // BezierCurve({required this.points});
  Point point({required double at});
  Point derivative({required double at});
  Point normal({required double at});
  BezierCurve split({required double from, required double to});
  ({BezierCurve left, BezierCurve right}) splitAt(double at);
  // double length();
  ({List<double> x, List<double> y, List<double> all}) extrema();
  // List<Point> lookupTable({required int steps});
  ({Point point, double t}) project(Point point);
  // intersection routines
  bool get selfIntersects;
  List<Intersection> get selfIntersections;
  bool intersectsLine(LineSegment line);
  bool intersectsCurve(BezierCurve curve, {double? accuracy});
  List<Intersection> intersectionsWithLine(
    LineSegment line, {
    bool checkCoincidence = false,
  });
  List<Intersection> intersectionsWithCurve(
    BezierCurve curve, {
    double? accuracy,
  });
  
  @override
  BezierCurve copy({required AffineTransform using});

  @override
  bool operator ==(Object? other) {
    if (identical(this, other)) return true;
    if (other is! BezierCurve) return false;
    return ListEquality().equals(points, other.points);
  }

  @override
  int get hashCode => Object.hashAll(points);

  /*
     Calculates the length of this Bezier curve. Length is calculated using numerical approximation, specifically the Legendre-Gauss quadrature algorithm.
   */
  double length() {
    return Utils.length((t) => derivative(at: t));
  }

  List<Point> hull(double t) {
    return Utils.hull(points, t);
  }

  List<Point> lookupTable({int steps = 100}) {
    assert(steps >= 0);
    return Iterable.generate(steps + 1).map(($0) {
      final t = $0 / steps;
      return point(at: t);
    }).toList();
  }

  List<BezierCurve> offset({required double distance}) {
    // for non-linear curves we need to create a set of curves
    final result = reduce()
        .map(($0) => $0.curve.scale(distance: distance))
        .nonNulls
        .toList();
    _ensureContinuous(result);
    return result;
  }

  Point offsetAt(double at, {required double distance}) {
    return point(at: at) + normal(at: at) * distance;
  }

  void _ensureContinuous(List<BezierCurve> curves) {
    for (var i = 0; i < curves.length; i++) {
      if (i > 0) {
        curves[i].startingPoint = curves[i - 1].endingPoint;
      }
      if (i < curves.length - 1) {
        curves[i].endingPoint =
            (curves[i].endingPoint + curves[i + 1].startingPoint) * 0.5;
      }
    }
  }

  /*
     Reduces a curve to a collection of "simple" subcurves, where a simpleness is defined as having all control points on the same side of the baseline (cubics having the additional constraint that the control-to-end-point lines may not cross), and an angle between the end point normals no greater than 60 degrees.

     The main reason this function exists is to make it possible to scale curves. As mentioned in the offset function, curves cannot be offset without cheating, and the cheating is implemented in this function. The array of simple curves that this function yields can safely be scaled.

     */

  List<Subcurve<BezierCurve>> reduce() {
    final step = reduceStepSize;
    var extrema = <double>[];
    this.extrema().all.forEach(($0) {
      if ($0 < step) {
        return; // filter out extreme points very close to 0.0
      } else if ((1.0 - $0) < step) {
        return; // filter out extreme points very close to 1.0
      } else {
        final last = extrema.lastOrNull;
        if (last != null && $0 - last < step) {
          return;
        }
      }
      return extrema.add($0);
    });
    // aritifically add 0.0 and 1.0 to our extreme points
    extrema.insert(0, 0.0);
    extrema.add(1.0);

    // first pass: split on extrema
    final pass1 = Iterable.generate(extrema.length - 1).map(($0) {
      final t1 = extrema[$0];
      final t2 = extrema[$0 + 1];
      final curve = split(from: t1, to: t2);
      return Subcurve(t1: t1, t2: t2, curve: curve);
    }).toList();

    double bisectionMethod({
      required double min,
      required double max,
      required double tolerance,
      required bool Function(double) callback,
    }) {
      var lb = min; // lower bound (callback(x <= lb) should return true
      var ub = max; // upper bound (callback(x >= ub) should return false
      while ((ub - lb) > tolerance) {
        final val = 0.5 * (lb + ub);
        if (callback(val)) {
          lb = val;
        } else {
          ub = val;
        }
      }
      return lb;
    }

    // second pass: further reduce these segments to simple segments
    final pass2 = <Subcurve<BezierCurve>>[];
    // pass2.reserveCapacity(pass1.length)
    for (var p1 in pass1) {
      final adjustedStep = step / (p1.t2 - p1.t1);
      var t1 = 0.0;
      while (t1 < 1.0) {
        final fullSegment = p1.split(from: t1, to: 1.0);
        if ((1.0 - t1) <= adjustedStep || fullSegment.curve.simple) {
          // if the step is small or the full segment is simple, use it
          pass2.add(fullSegment);
          t1 = 1.0;
        } else {
          // otherwise use bisection method to find a suitable step size
          final t2 = bisectionMethod(
              min: t1 + adjustedStep,
              max: 1.0,
              tolerance: adjustedStep,
              callback: ($0) => p1.split(from: t1, to: $0).curve.simple);
          final partialSegment = p1.split(from: t1, to: t2);
          pass2.add(partialSegment);
          t1 = t2;
        }
      }
    }
    return pass2;
  }

  /// Scales a curve with respect to the intersection between the end point normals. Note that this will only work if that intersection point exists, which is only guaranteed for simple segments.
  /// - Parameter distance: desired distance the resulting curve should fall from the original (in the direction of its normals).
  BezierCurve? scale({required double distance}) {
    final order = this.order;
    assert(order < 4, "only works with cubic or lower order");
    if (order <= 0) return this; // points cannot be scaled
    final points = this.points;

    final n1 = normal(at: 0);
    final n2 = normal(at: 1);
    if (!n1.x.isFinite || !n1.y.isFinite || !n2.x.isFinite || !n2.y.isFinite) {
      return null;
    }

    final origin = Utils.linesIntersection(
        startingPoint, startingPoint + n1, endingPoint, endingPoint - n2);
    Point scaledPoint(int index) {
      final referencePointIsStart =
          (index < 2 && order > 1) || (index == 0 && order == 1);
      final referenceT = referencePointIsStart ? 0.0 : 1.0;
      final referenceIndex = referencePointIsStart ? 0 : this.order;
      final referencePoint = offsetAt(referenceT, distance: distance);
      if (index == 0 || index == order) {
        return referencePoint;
      }

      final tangent = normal(at: referenceT).perpendicular;
      if (origin != null) {
        final intersection = Utils.linesIntersection(
            referencePoint, referencePoint + tangent, origin, points[index]);
        if (intersection != null) {
          return intersection;
        }
      }

      // no origin to scale control points through, just use start and end points as a reference
      return referencePoint + (points[index] - points[referenceIndex]);
    }

    final scaledPoints =
        Iterable<int>.generate(this.points.length).map(scaledPoint).toList();
    return copyWith(points: scaledPoints);
  }

  BezierCurve copyWith({List<Point>? points});
}

mixin FlatnessMixin {
  // the flatness of a curve is defined as the square of the maximum distance it is from a line connecting its endpoints https://jeremykun.com/2013/05/11/bezier-curves-and-picasso/
  double get flatnessSquared;
  double get flatness => sqrt(flatnessSquared);
}

sealed class NonlinearBezierCurve extends BezierCurve
    implements ComponentPolynomials, Implicitizeable {
  /// default implementation of `extrema` by finding roots of component polynomials
  @override
  ({List<double> x, List<double> y, List<double> all}) extrema() {
    List<double> rootsForPolynomial<B extends BernsteinPolynomial>(
        B polynomial) {
      final firstOrderDerivative = polynomial.derivative as BernsteinPolynomial;
      var roots = findDistinctRootsInUnitInterval(of: firstOrderDerivative);
      if (order >= 3) {
        final secondOrderDerivative =
            firstOrderDerivative.derivative as BernsteinPolynomial;
        roots += findDistinctRootsInUnitInterval(of: secondOrderDerivative);
      }
      return roots.sortedAndUniqued().toList();
    }

    final xRoots = rootsForPolynomial(xPolynomial);
    final yRoots = rootsForPolynomial(yPolynomial);
    final allRoots = (xRoots + yRoots).sortedAndUniqued().toList();
    return (x: xRoots, y: yRoots, all: allRoots);
  }

  @override
  NonlinearBezierCurve copy({required AffineTransform using});
}
