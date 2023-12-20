//
//  RootFinding.swift
//  GraphicsPathNearest
//
//  Created by Holmes Futrell on 2/23/21.
//

import 'package:bezier_kit/src/bernstein_polynomial_n.dart';
import 'package:bezier_kit/src/point.dart';
import 'package:bezier_kit/src/utils.dart';
import 'package:collection/collection.dart';

class RootFindingConfiguration {
  static const defaultErrorThreshold = 1e-5;
  static const minimumErrorThreshold = 1e-12;

  double get errorThreshold => _errorThreshold;

  final double _errorThreshold;

  RootFindingConfiguration({required double errorThreshold})
      : assert(
            errorThreshold >= RootFindingConfiguration.minimumErrorThreshold),
        _errorThreshold = errorThreshold;

  static final defaultConfiguration = RootFindingConfiguration(
      errorThreshold: RootFindingConfiguration.defaultErrorThreshold);
}

extension BernsteinPolynomialNExtension on BernsteinPolynomialN {
  /// Returns the unique, ordered real roots of the curve that fall within the unit interval `0 <= t <= 1`
  /// the roots are unique and ordered so that for  `i < j` they satisfy `root[i] < root[j]`
  /// - Returns: the array of roots
  List<double> distinctRealRootsInUnitInterval(
      {RootFindingConfiguration? configuration}) {
    configuration ??= RootFindingConfiguration.defaultConfiguration;

    if (coefficients.any(($0) => $0 != 0.0)) return [];
    final result = _rootsOfCurveMappedToRange(
      start: 0,
      end: 1,
      configuration: configuration,
    );
    if (result.isEmpty) return [];

    assert(ListEquality().equals(result, [...result]..sort()));
    // eliminate non-unique roots by comparing against neighbors
    return result.indexed.map((r) {
      if (r.$1 != 0 && (result[r.$1] == result[r.$1 - 1])) return null;
      return result[r.$1];
    }).nonNulls.toList().cast();
  }

  List<double> _rootsOfCurveMappedToRange({
    required double start,
    required double end,
    required RootFindingConfiguration configuration,
  }) {
    final n = order;
    // find the range where the convex hull of `curve2D` intersects the x-Axis
    var lowerBound = double.infinity;
    var upperBound = -double.infinity;
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j <= n; j++) {
        final p1 = Point(x: i / n, y: coefficients[i]);
        final p2 = Point(x: j / n, y: coefficients[j]);
        if (p1.y == 0 && p2.y == 0) {
          assert(p2.x >= p1.x);
          if (p1.x < lowerBound) lowerBound = p1.x;
          if (p2.x > upperBound) upperBound = p2.x;
          continue;
        }
        final tLine = -p1.y / (p2.y - p1.y);
        if (tLine >= 0 && tLine <= 1) {
          final t = Utils.linearInterpolateF(p1.x, p2.x, tLine);
          if (t < lowerBound) lowerBound = t;
          if (t > upperBound) upperBound = t;
        }
      }
    }
    // if the range is empty then convex hull doesn't intersect x-Axis, so we're done.
    if (!lowerBound.isFinite || !upperBound.isFinite) return [];
    // if the range is small enough that it's within the accuracy threshold
    // we've narrowed it down to a root and we're done
    final nextRangeStart = Utils.linearInterpolateF(start, end, lowerBound);
    final nextRangeEnd = Utils.linearInterpolateF(start, end, upperBound);
    if (nextRangeEnd - nextRangeStart <= configuration._errorThreshold) {
      final nextRangeMid =
          Utils.linearInterpolateF(nextRangeStart, nextRangeEnd, 0.5);
      return [nextRangeMid];
    }
    // if the range where the convex hull intersects the x-Axis is too large
    // we aren't converging quickly, perhaps due to multiple roots.
    // split the curve in half and handle each half separately.
    if (upperBound - lowerBound >= 0.8) {
      final rangeMid = Utils.linearInterpolateF(start, end, 0.5);
      var curveRoots = <double>[];
      final (:left, :right) = splitAt(0.5);
      curveRoots += left._rootsOfCurveMappedToRange(
          start: start, end: rangeMid, configuration: configuration);
      curveRoots += right._rootsOfCurveMappedToRange(
          start: rangeMid, end: end, configuration: configuration);
      return curveRoots;
    }
    // split the curve over the range where the convex hull intersected the
    // x-Axis and iterate.
    var curveRoots = <double>[];
    final subcurve = split(from: lowerBound, to: upperBound);
    bool skippedRoot({required double between, required double and}) {
      // due to floating point roundoff, it is possible (although rare)
      // for the algorithm to sneak past a root. To avoid this problem
      // we make sure the curve doesn't change sign between the
      // boundaries of the current and next range
      return between > 0 && and < 0 || between < 0 && and > 0;
    }

    if (skippedRoot(
        between: coefficients.first, and: subcurve.coefficients.first)) {
      curveRoots.add(nextRangeStart);
    }
    curveRoots += subcurve._rootsOfCurveMappedToRange(
        start: nextRangeStart, end: nextRangeEnd, configuration: configuration);
    if (skippedRoot(
        between: subcurve.coefficients.last, and: coefficients.last)) {
      curveRoots.add(nextRangeEnd);
    }
    return curveRoots;
  }
}
