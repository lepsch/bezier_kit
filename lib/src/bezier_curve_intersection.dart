//
//  BezierCurve+Intersection.swift
//  BezierKit
//
//  Created by Holmes Futrell on 3/18/19.
//  Copyright © 2019 Holmes Futrell. All rights reserved.
//

part of './bezier_curve.dart';

const tinyValue = 1.0e-10;

mixin BezierCurveIntersectionMixin on BezierCurve {
  @override
  bool intersectsLine(LineSegment line) {
    return intersectionsWithLine(line).isNotEmpty;
  }

  @override
  bool intersectsCurve(
    BezierCurve curve, {
    double? accuracy = defaultIntersectionAccuracy,
  }) {
    return intersectsCurve(curve, accuracy: accuracy);
  }

  @override
  bool get selfIntersects => false;

  @override
  List<Intersection> get selfIntersections => [];
}

List<Intersection>?
    _coincidenceCheck<U extends BezierCurve, T extends BezierCurve>(
        U curve1, T curve2,
        {required double accuracy}) {
  double? pointIsCloseToCurve<X extends BezierCurve>(Point p, X curve) {
    final (:point, :t) = curve.project(p);
    if (distanceSquared(p, point) >= 4.0 * accuracy * accuracy) {
      return null;
    }
    return t;
  }

  var range1Start = double.infinity;
  var range1End = -double.infinity;
  var range2Start = double.infinity;
  var range2End = -double.infinity;
  if (range1Start > 0 || range2Start > 0 || range2End < 1) {
    final t2 = pointIsCloseToCurve(curve1.startingPoint, curve2);
    if (t2 != null) {
      range1Start = 0;
      range2Start = min(range2Start, t2);
      range2End = max(range2End, t2);
    }
  }
  if (range1End < 1 || range2Start > 0 || range2Start < 1) {
    final t2 = pointIsCloseToCurve(curve1.endingPoint, curve2);
    if (t2 != null) {
      range1End = 1;
      range2Start = min(range2Start, t2);
      range2End = max(range2End, t2);
    }
  }
  if (range2Start > 0 || range1Start > 0 || range1End < 1) {
    final t1 = pointIsCloseToCurve(curve2.startingPoint, curve1);
    if (t1 != null) {
      range2Start = 0;
      range1Start = min(range1Start, t1);
      range1End = max(range1End, t1);
    }
  }
  if (range2End < 1 || range1Start > 0 || range1End < 1) {
    final t1 = pointIsCloseToCurve(curve2.endingPoint, curve1);
    if (t1 != null) {
      range2End = 1;
      range1Start = min(range1Start, t1);
      range1End = max(range1End, t1);
    }
  }
  if (range1End <= range1Start || range2End <= range2Start) return null;
  final curve1Start = curve1.point(at: range1Start);
  final curve1End = curve1.point(at: range1End);
  final curve2Start = curve2.point(at: range2Start);
  final curve2End = curve2.point(at: range2End);
  // if curves do not represent entire range, prevent recognition of coincident sections smaller than `accuracy`
  if (range1End - range1Start < 1.0 && range2End - range2Start < 1.0) {
    if (distanceSquared(curve1Start, curve1End) < accuracy * accuracy) {
      return null;
    }
    if (distanceSquared(curve2Start, curve2End) < accuracy * accuracy) {
      return null;
    }
  }
  // determine proper ordering of intersections
  final reversed = () {
    final distance1 = distanceSquared(curve1Start, curve2Start);
    final distance2 = distanceSquared(curve1Start, curve2End);
    return distance1 > distance2;
  }();
  final firstT1 = range1Start;
  final secondT1 = range1End;
  final firstT2 = reversed ? range2End : range2Start;
  final secondT2 = reversed ? range2Start : range2End;
  // ensure curves are actually relatively equal by testing more points
  // for example with a quadratic curve we must test 1 additional point, and cubic two
  final numberOfPointsToTest = max(curve1.order, curve2.order) - 1;
  if (numberOfPointsToTest > 0) {
    final delta = (secondT1 - firstT1) / (numberOfPointsToTest + 1);
    for (var i = 1; i <= numberOfPointsToTest; i++) {
      final t = firstT1 + delta * i;
      if (pointIsCloseToCurve(curve1.point(at: t), curve2) == null) return null;
    }
  }
  return [
    Intersection(t1: firstT1, t2: firstT2),
    Intersection(t1: secondT1, t2: secondT2),
  ];
}

extension on BezierCurve {
  double get derivativeBounds {
    final points = this.points;
    final speeds = <double>[];
    for (var i = 1; i < points.length; i++) {
      final vector = points[i] - points[i - 1];
      final speed = vector.dot(vector);
      speeds.add(speed);
    }
    return order * speeds.max;
  }
}

List<Intersection> helperIntersectsCurveCurve<U extends NonlinearBezierCurve,
        T extends NonlinearBezierCurve>(Subcurve<U> curve1, Subcurve<T> curve2,
    {required double accuracy}) {
  // try intersecting using subdivision
  final lb = curve1.curve.boundingBox;
  final rb = curve2.curve.boundingBox;
  var pairIntersections = <Intersection>[];
  var subdivisionIterations = Box(0);
  if (Utils.pairiteration(curve1, curve2, lb, rb, pairIntersections, accuracy,
      subdivisionIterations)) {
    return pairIntersections.sortedAndUniqued().toList();
  }

  // subdivision failed, check if the curves are coincident
  final double insignificantDistance = 0.5 * accuracy;
  final coincidence =
      _coincidenceCheck(curve1.curve, curve2.curve, accuracy: 0.1 * accuracy);
  if (coincidence != null) {
    return coincidence;
  }

  // find any intersections using curve implicitization
  final transform = AffineTransform.translation(
      translationX: -curve2.curve.startingPoint.x,
      y: -curve2.curve.startingPoint.y);
  final c2 = curve2.curve
      .downgradedIfPossible(maximumError: insignificantDistance)
      .copy(using: transform);

  final c1 = curve1.curve.copy(using: transform);
  final equation = c2.implicitPolynomial.value(c1.xPolynomial, c1.yPolynomial);
  final roots = equation.distinctRealRootsInUnitInterval(
      configuration: RootFindingConfiguration(
          errorThreshold: RootFindingConfiguration.minimumErrorThreshold));

  final t1Tolerance = insignificantDistance / c1.derivativeBounds;
  final t2Tolerance = insignificantDistance / c2.derivativeBounds;

  Intersection? intersectionIfCloseEnough({required double at}) {
    final point = c1.point(at: at);
    if (!c2.boundingBox.contains(point)) return null;
    var t2 = c2.project(point).t;
    if (t2 < t2Tolerance) {
      t2 = 0;
    } else if (t2 > 1 - t2Tolerance) {
      t2 = 1;
    }
    if (distance(point, c2.point(at: t2)) >= accuracy) return null;
    return Intersection(t1: at, t2: t2);
  }

  var intersections = roots
      .map((t1) {
        if (t1 < t1Tolerance) {
          return null; // (t1 near 0 handled explicitly)
        } else if (t1 > 1 - t1Tolerance) {
          return null; // (t1 near 1 handled explicitly)
        }
        return intersectionIfCloseEnough(at: t1);
      })
      .nonNulls
      .toList();
  if (intersections.any(($0) => $0.t1 == 0) == false) {
    final intersection = intersectionIfCloseEnough(at: 0);
    if (intersection != null) {
      intersections.add(intersection);
    }
  }
  if (intersections.any(($0) => $0.t1 == 1) == false) {
    final intersection = intersectionIfCloseEnough(at: 1);
    if (intersection != null) {
      intersections.add(intersection);
    }
  }
  // TODO: handle case where curve2 this-intersects and curve intersects it there;
  return intersections.sortedAndUniqued().toList();
}

List<Intersection> helperIntersectsCurveLine<U extends NonlinearBezierCurve>(
    U curve, LineSegment line,
    {bool reversed = false}) {
  if (!line.boundingBox.overlaps(curve.boundingBox)) return [];

  final coincidence = _coincidenceCheck(curve, line, accuracy: tinyValue);
  if (coincidence != null) return coincidence;

  final lineDirection = (line.p1 - line.p0);
  final lineLength = lineDirection.lengthSquared;
  if (lineLength <= 0) return [];

  double align(Point point) {
    return (point - line.p0).dot(lineDirection.perpendicular);
  }

  final intersections = <Intersection>[];
  void callback(double t) {
    var t1 = t;
    const smallValue = 1.0e-8;
    assert(smallValue < Utils.epsilon);
    if (t1 < -smallValue || t1 > 1.0 + smallValue) return;

    final p = curve.point(at: t1) - line.p0;
    var t2 = p.dot(lineDirection) / lineLength;
    if (t2 < -smallValue || t2 > 1.0 + smallValue) return;

    if (Utils.approximately(t1, 0.0, precision: Utils.epsilon)) {
      t1 = 0.0;
    } else if (Utils.approximately(t1, 1.0, precision: Utils.epsilon)) {
      t1 = 1.0;
    }
    if (Utils.approximately(t2, 0.0, precision: Utils.epsilon)) {
      t2 = 0.0;
    } else if (Utils.approximately(t2, 1.0, precision: Utils.epsilon)) {
      t2 = 1.0;
    }
    intersections.add(
        reversed ? Intersection(t1: t2, t2: t1) : Intersection(t1: t1, t2: t2));
  }

  switch (curve) {
    case QuadraticCurve():
      Utils.droots3(align(curve.p0), align(curve.p1), align(curve.p2),
          callback: callback);
      break;
    case CubicCurve():
      Utils.droots4(
          align(curve.p0), align(curve.p1), align(curve.p2), align(curve.p3),
          callback: callback);
      break;
    default:
      assert(false, "unexpected curve type.");
      break;
  }
  return intersections.sortedAndUniqued().toList();
}

// extensions to support intersection

// extension CubicCurveIntersectionExtension on CubicCurve {

//     private var selfIntersectionInfo: (double discriminant, canonicalPoint: Point)? {
//         final d1 = this.p1 - this.p0;
//         final d2 = this.p2 - this.p0;
//         // https://pomax.github.io/bezierinfo/#canonical
//         // we'll use cramer's rule to find a matrix M that maps d1 -> (1, 0) and d2 -> (0, 1)
//         // then compute the transform to canonical form as [[0, 1], [1, 1]] * M
//         final a = d1.x
//         final c = d1.y
//         final b = d2.x
//         final d = d2.y
//         final det = a * d - b * c
//         guard det != 0 else { return null }
//         final d3 = this.p3 - this.p0;
//         // find the coordinates of the last point in canonical form
//         final x = (1 / det) * (-c * d3.x + a * d3.y)
//         final y = (1 / det) * ((d - c) * d3.x + (a - b) * d3.y)
//         // use the coordinates of the last point to determine if any this-intersections exist;
//         guard x < 1 else { return null }
//         final xSquared = x * x
//         final cuspEdge = -3 * xSquared + 6 * x - 12 * y + 9
//         guard cuspEdge > 0 else { return null }
//         if x <= 0 {
//             final loopAtTZeroEdge = (-xSquared + 3 * x) / 3
//             guard y >= loopAtTZeroEdge else { return null }
//         } else {
//             final loopAtTOneEdge = (sqrt(3 * (4 * x - xSquared)) - x) / 2
//             guard y >= loopAtTOneEdge else { return null }
//         }
//         return (discriminant: cuspEdge, canonicalPoint: Point(x: x, y: y))
//     }

//      var selfIntersects: bool {
//         return this.selfIntersectionInfo != null;
//     }

//      var selfIntersections: List<Intersection> {
//         guard final info = this.selfIntersectionInfo else { return [] };
//         final discriminant = info.discriminant
//         final x = info.canonicalPoint.x
//         final y = info.canonicalPoint.y
//         final radical = sqrt(discriminant)
//         final denominator = (3 - x - y)
//         final t1 = 0.5 * (3 - x - radical) / denominator
//         final t2 = 0.5 * (3 - x + radical) / denominator
//         return [Intersection(t1: Utils.clamp(t1, 0, 1),
//                              t2: Utils.clamp(t2, 0, 1))]
//     }
// }

abstract interface class ImplicitizeableBezierCurve extends BezierCurve
    implements Implicitizeable {
  @override
  ImplicitizeableBezierCurve copy({required AffineTransform using});
}

extension BezierCurveDowngradedExtension on NonlinearBezierCurve {
  ImplicitizeableBezierCurve downgradedIfPossible(
      {required double maximumError}) {
    switch (order) {
      case 3:
        final cubic = (this as CubicCurve);
        final ls = cubic.downgradedToLineSegment;
        if (ls.error <= maximumError) {
          return ls.lineSegment as ImplicitizeableBezierCurve;
        }
        final q = cubic.downgradedToQuadratic;
        if (q.error <= maximumError) {
          return q.quadratic as ImplicitizeableBezierCurve;
        }
        return this as ImplicitizeableBezierCurve;
      case 2:
        final quadratic = (this as QuadraticCurve);
        final ls = quadratic.downgradedToLineSegment;
        if (ls.error <= maximumError) {
          return ls.lineSegment as ImplicitizeableBezierCurve;
        }
        return this as ImplicitizeableBezierCurve;
      default:
        return this as ImplicitizeableBezierCurve;
    }
  }
}

mixin NonlinearBezierCurveIntersectionMixin on NonlinearBezierCurve {
  @override
  List<Intersection> intersectionsWithLine(
    LineSegment line, {
    bool checkCoincidence = false,
  }) {
    return helperIntersectsCurveLine(this, line);
  }

  @override
  List<Intersection> intersectionsWithCurve(
    BezierCurve curve, {
    double? accuracy = defaultIntersectionAccuracy,
  }) {
    switch (curve.order) {
      case 3:
        return helperIntersectsCurveCurve(
            Subcurve<NonlinearBezierCurve>.fromCurve(this),
            Subcurve.fromCurve(curve as CubicCurve),
            accuracy: accuracy ?? defaultIntersectionAccuracy);
      case 2:
        return helperIntersectsCurveCurve(Subcurve.fromCurve(this),
            Subcurve.fromCurve(curve as QuadraticCurve),
            accuracy: accuracy ?? defaultIntersectionAccuracy);
      case 1:
        return helperIntersectsCurveLine(this, curve as LineSegment);
      default:
        throw Exception("unsupported");
    }
  }
}

mixin LineSegmentIntersectionMixin on LineSegmentBase {
  @override
  List<Intersection> intersectionsWithCurve(
    BezierCurve curve, {
    double? accuracy = defaultIntersectionAccuracy,
  }) {
    switch (curve.order) {
      case 3:
        return helperIntersectsCurveLine(
            curve as CubicCurve, this as LineSegment,
            reversed: true);
      case 2:
        return helperIntersectsCurveLine(
            curve as QuadraticCurve, this as LineSegment,
            reversed: true);
      case 1:
        return intersectionsWithCurve(curve as LineSegment);
      default:
        throw Exception("unsupported");
    }
  }

  @override
  List<Intersection> intersectionsWithLine(
    LineSegment line,  {
     bool checkCoincidence = true,
  }) {
    if (p1 == p0 || line.p1 == line.p0) return [];

    if (!boundingBox.overlaps(line.boundingBox)) return [];

    final coincidence = checkCoincidence
        ? _coincidenceCheck(this, line, accuracy: tinyValue)
        : null;
    if (coincidence != null) {
      return coincidence;
    }

    final a1 = p0;
    final b1 = p1 - p0;
    final a2 = line.p0;
    final b2 = line.p1 - line.p0;

    if (p1 == line.p1) {
      return [Intersection(t1: 1.0, t2: 1.0)];
    } else if (p1 == line.p0) {
      return [Intersection(t1: 1.0, t2: 0.0)];
    } else if (p0 == line.p1) {
      return [Intersection(t1: 0.0, t2: 1.0)];
    } else if (p0 == line.p0) {
      return [Intersection(t1: 0.0, t2: 0.0)];
    }

    final a = b1.x;
    final b = -b2.x;
    final c = b1.y;
    final d = -b2.y;

    // by Cramer's rule we have
    // t1 = ed - bf / ad - bc
    // t2 = af - ec / ad - bc
    final det = a * d - b * c;
    final invDet = 1.0 / det;

    if (invDet.isFinite == false) {
      // lines are effectively parallel. Multiplying by inv_det will yield Inf or NaN, neither of which is valid
      return [];
    }

    final e = -a1.x + a2.x;
    final f = -a1.y + a2.y;

    // if inv_det is inf then this is NaN!
    var t1 = (e * d - b * f) * invDet;
    // if inv_det is inf then this is NaN!
    var t2 = (a * f - e * c) * invDet;

    if (Utils.approximately(t1, 0.0, precision: Utils.epsilon)) {
      t1 = 0.0;
    }
    if (Utils.approximately(t1, 1.0, precision: Utils.epsilon)) {
      t1 = 1.0;
    }
    if (Utils.approximately(t2, 0.0, precision: Utils.epsilon)) {
      t2 = 0.0;
    }
    if (Utils.approximately(t2, 1.0, precision: Utils.epsilon)) {
      t2 = 1.0;
    }

    if (t1 > 1.0 || t1 < 0.0) {
      return []; // t1 out of interval [0, 1]
    }
    if (t2 > 1.0 || t2 < 0.0) {
      return []; // t2 out of interval [0, 1]
    }
    return [Intersection(t1: t1, t2: t2)];
  }
}
