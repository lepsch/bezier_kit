//
//  PathComponent.swift
//  BezierKit
//
//  Created by Holmes Futrell on 11/23/16.
//  Copyright © 2016 Holmes Futrell. All rights reserved.
//

import 'package:bezier_kit/src/affine_transform.dart';
import 'package:bezier_kit/src/bezier_curve.dart';
import 'package:bezier_kit/src/bezier_curve_internals.dart';
import 'package:bezier_kit/src/bounding_box_hierarchy.dart';
import 'package:bezier_kit/src/path.dart';
import 'package:bezier_kit/src/path_component_winding_count.dart';
import 'package:bezier_kit/src/path_internals.dart';
import 'package:bezier_kit/src/point.dart';
import 'package:bezier_kit/src/types.dart';
import 'package:bezier_kit/src/utils.dart';
import 'package:collection/collection.dart';

class PathComponent implements Reversible, Transformable {
  final List<int> _offsets;
  final List<Point> points;
  final List<int> orders;

  PathComponent({required this.points, required this.orders})
      : _offsets = PathComponent._computeOffsets(from: orders) {
    // TODO: I don't like that this constructor is exposed, but for certain performance critical things you need it
    final expectedPointsCount = orders.fold(1, (result, value) {
      return result + value;
    });
    assert(points.length == expectedPointsCount);
  }

  factory PathComponent.fromCurve(BezierCurve curve) {
    return PathComponent.fromList(curves: [curve]);
  }

  factory PathComponent.fromList({required List<BezierCurve> curves}) {
    assert(curves.isEmpty == false,
        "Path components are by definition non-empty.");

    final orders = curves.map(($0) => $0.order).toList();

    var temp = [curves.first.startingPoint];
    // temp.reserveCapacity(this._offsets.last! + this.orders.last! + 1);
    for (final $0 in curves) {
      assert($0.startingPoint == temp.last, "curves are not contiguous.");
      temp += $0.points.sublist(1);
    }
    final points = temp;
    return PathComponent(points: points, orders: orders);
  }

  static List<int> _computeOffsets({required List<int> from}) {
    final offsets = <int>[];
    var sum = 0;
    offsets[0] = 0;
    for (var i = 1; i < from.length; i++) {
      sum += from[i - 1];
      offsets[i] = sum;
    }
    return offsets;
  }

  List<BezierCurve> get curves {
    // in most cases use element(at:)
    return Iterable.generate(numberOfElements)
        .map(($0) => element(at: $0))
        .toList();
  }

  // TODO: Check other lazy vars and do this
  BoundingBoxHierarchy get _bvh =>
      _lazyBvh ??
      (_lazyBvh = BoundingBoxHierarchy(boxes: [
        for (var at = 0; at < numberOfElements; at++)
          element(at: at).boundingBox
      ]));
  BoundingBoxHierarchy? _lazyBvh;

  // int? _hash;

  BoundingBox get _boundingBoxOfPath =>
      _lazyBoundingBoxOfPath ??
      (_lazyBoundingBoxOfPath =
          points.fold<BoundingBox>(BoundingBox.empty, (result, value) {
        return result.unionPoint(value);
      }));

  BoundingBox? _lazyBoundingBoxOfPath;

  BoundingBoxHierarchy get bvh => _bvh;

  int get numberOfElements => orders.length;

  Point get startingPoint => points.first;

  Point get endingPoint => points.last;

  IndexedPathComponentLocation get startingIndexedLocation =>
      IndexedPathComponentLocation(elementIndex: 0, t: 0.0);

  IndexedPathComponentLocation get endingIndexedLocation =>
      IndexedPathComponentLocation(elementIndex: numberOfElements - 1, t: 1.0);

  /// if the path component represents a single point
  bool get isPoint {
    return points.length == 1;
  }

  BezierCurve element({required int at}) {
    assert(at >= 0 && at < numberOfElements);
    final order = orders[at];
    if (order == 3) {
      return cubic(at: at);
    } else if (order == 2) {
      return quadratic(at: at);
    } else if (order == 1) {
      return line(at: at);
    } else {
      // TODO: add Point:BezierCurve
      // for now just return a degenerate line
      final p = points[_offsets[at]];
      return LineSegment(p0: p, p1: p);
    }
  }

  Point startingPointForElement({required int at}) {
    return points[_offsets[at]];
  }

  Point endingPointForElement({required int at}) {
    return points[_offsets[at] + orders[at]];
  }

  CubicCurve cubic({required int at}) {
    assert(order(at: at) == 3);
    final offset = _offsets[at];
    final p = points;
    return CubicCurve(
        p0: p[offset], p1: p[offset + 1], p2: p[offset + 2], p3: p[offset + 3]);
  }

  QuadraticCurve quadratic({required int at}) {
    assert(order(at: at) == 2);
    final offset = _offsets[at];
    final p = points;
    return QuadraticCurve(p0: p[offset], p1: p[offset + 1], p2: p[offset + 2]);
  }

  LineSegment line({required int at}) {
    assert(order(at: at) == 1);
    final offset = _offsets[at];
    final p = points;
    return LineSegment(p0: p[offset], p1: p[offset + 1]);
  }

  int order({required int at}) => orders[at];

  double get length {
    return curves.fold(0.0, ($0, $1) => $0 + $1.length());
  }

  BoundingBox get boundingBox {
    return bvh.boundingBox;
  }

  BoundingBox get boundingBoxOfPath {
    return _boundingBoxOfPath;
  }

  bool get isClosed {
    return startingPoint == endingPoint;
  }

  PathComponent? offset({required double distance}) {
    var offsetCurves = curves
        .fold(<BezierCurve>[], ($0, $1) => $0 + $1.offset(distance: distance));
    if (offsetCurves.isEmpty) return null;
    // force the set of curves to be contiguous
    for (var i = 0; i < offsetCurves.length - 1; i++) {
      final start = offsetCurves[i + 1].startingPoint;
      final end = offsetCurves[i].endingPoint;
      final average = Utils.linearInterpolate(start, end, 0.5);
      offsetCurves[i].endingPoint = average;
      offsetCurves[i + 1].startingPoint = average;
    }
    // we've touched everything but offsetCurves[0].startingPoint and offsetCurves[length-1].endingPoint
    // if we are a closed componenet, keep the offset component closed as well
    if (isClosed) {
      final start = offsetCurves[0].startingPoint;
      final end = offsetCurves[offsetCurves.length - 1].endingPoint;
      final average = Utils.linearInterpolate(start, end, 0.5);
      offsetCurves[0].startingPoint = average;
      offsetCurves[offsetCurves.length - 1].endingPoint = average;
    }
    return PathComponent.fromList(curves: offsetCurves);
  }

  static List<Intersection>
      _intersectionBetween<U extends NonlinearBezierCurve>(
    U curve,
    int i2,
    PathComponent p2, {
    required double accuracy,
  }) {
    switch (p2.order(at: i2)) {
      case 0:
        return [];
      case 1:
        return helperIntersectsCurveLine(curve, p2.line(at: i2));
      case 2:
        return helperIntersectsCurveCurve(
            Subcurve.fromCurve(curve), Subcurve.fromCurve(p2.quadratic(at: i2)),
            accuracy: accuracy);
      case 3:
        return helperIntersectsCurveCurve(
            Subcurve.fromCurve(curve), Subcurve.fromCurve(p2.cubic(at: i2)),
            accuracy: accuracy);
      default:
        throw Exception("unsupported");
    }
  }

  static List<Intersection> _intersectionsBetweenElementAndLine(
    int index,
    LineSegment line,
    PathComponent component, {
    bool reversed = false,
  }) {
    switch (component.order(at: index)) {
      case 0:
        return [];
      case 1:
        final element = component.line(at: index);
        return reversed
            ? line.intersectionsWithLine(component.line(at: index))
            : element.intersectionsWithLine(line);
      case 2:
        return helperIntersectsCurveLine(component.quadratic(at: index), line,
            reversed: reversed);
      case 3:
        return helperIntersectsCurveLine(component.cubic(at: index), line,
            reversed: reversed);
      default:
        throw Exception("unsupported");
    }
  }

  static List<Intersection> _intersectionsBetweenElements(
    int i1,
    int i2,
    PathComponent p1,
    PathComponent p2, {
    required double accuracy,
  }) {
    switch (p1.order(at: i1)) {
      case 0:
        return [];
      case 1:
        return PathComponent._intersectionsBetweenElementAndLine(
            i2, p1.line(at: i1), p2,
            reversed: true);
      case 2:
        return PathComponent._intersectionBetween(p1.quadratic(at: i1), i2, p2,
            accuracy: accuracy);
      case 3:
        return PathComponent._intersectionBetween(p1.cubic(at: i1), i2, p2,
            accuracy: accuracy);
      default:
        throw Exception("unsupported");
    }
  }

  List<PathComponentIntersection> intersections(
    PathComponent other, {
    double accuracy = defaultIntersectionAccuracy,
  }) {
    final intersections = <PathComponentIntersection>[];
    final isClosed1 = isClosed;
    final isClosed2 = other.isClosed;
    bvh.enumerateIntersections(
        other: other.bvh,
        callback: (i1_, i2_) {
          final elementIntersections =
              PathComponent._intersectionsBetweenElements(i1_, i2_, this, other,
                  accuracy: accuracy);
          final pathComponentIntersections = elementIntersections.map((i) {
            final i1 = IndexedPathComponentLocation(elementIndex: i1_, t: i.t1);
            final i2 = IndexedPathComponentLocation(elementIndex: i2_, t: i.t2);
            if (i1.t == 0.0 && (isClosed1 || i1.elementIndex > 0)) {
              // handle this intersection instead at i1.elementIndex-1 w/ t=1
              return null;
            }
            if (i2.t == 0.0 && (isClosed2 || i2.elementIndex > 0)) {
              // handle this intersection instead at i2.elementIndex-1 w/ t=1
              return null;
            }
            return PathComponentIntersection(
                indexedComponentLocation1: i1, indexedComponentLocation2: i2);
          }).nonNulls;
          intersections.addAll(pathComponentIntersections);
        });
    return intersections;
  }

  bool _neighborsIntersectOnlyTrivially(int i1, int i2) {
    final b1 = bvh.boundingBoxAt(i1);
    final b2 = bvh.boundingBoxAt(i2);
    if (b1.intersection(b2).area != 0) return false;

    final numPoints = order(at: i2) + 1;
    final offset = _offsets[i2];
    for (var i = 1; i < numPoints; i++) {
      if (b1.contains(points[offset + i])) {
        return false;
      }
    }
    return true;
  }

  List<PathComponentIntersection> selfIntersections(
      {double accuracy = defaultIntersectionAccuracy}) {
    final intersections = <PathComponentIntersection>[];
    final isClosed = this.isClosed;
    bvh.enumerateSelfIntersections((i1, i2) {
      var elementIntersections = <Intersection>[];
      if (i1 == i2) {
        // we are intersecting a path element against itself (only possible with cubic or higher order)
        if (order(at: i1) == 3) {
          elementIntersections = cubic(at: i1).selfIntersections;
        }
      } else if (i1 < i2) {
        // we are intersecting two distinct path elements
        final areNeighbors = (i1 == i2 - 1) ||
            (isClosed && i1 == 0 && i2 == numberOfElements - 1);
        if (areNeighbors && _neighborsIntersectOnlyTrivially(i1, i2)) {
          // optimize the very common case of element i intersecting i+1 at its endpoint
          elementIntersections = [];
        } else {
          elementIntersections = PathComponent._intersectionsBetweenElements(
                  i1, i2, this, this,
                  accuracy: accuracy)
              .where(($0) {
            if (i1 == i2 - 1 && $0.t1 == 1.0 && $0.t2 == 0.0) {
              return false; // exclude intersections of i and i+1 at t=1
            }
            if (i1 == 0 &&
                i2 == numberOfElements - 1 &&
                $0.t1 == 0.0 &&
                $0.t2 == 1.0) {
              assert(this.isClosed); // how else can that happen?
              return false; // exclude intersections of endpoint and startpoint
            }
            if ($0.t1 == 0.0 && (i1 > 0 || isClosed)) {
              // handle the intersections instead at i1-1, t=1
              return false;
            }
            if ($0.t2 == 0.0) {
              // handle the intersections instead at i2-1, t=1 (we know i2 > 0 because i2 > i1)
              return false;
            }
            return true;
          }).toList();
        }
      }
      intersections.addAll(elementIntersections.map(($0) {
        return PathComponentIntersection(
            indexedComponentLocation1:
                IndexedPathComponentLocation(elementIndex: i1, t: $0.t1),
            indexedComponentLocation2:
                IndexedPathComponentLocation(elementIndex: i2, t: $0.t2));
      }));
    });
    return intersections;
  }

  @override
  bool operator ==(Object? other) {
    if (identical(this, other)) return true;
    if (other is! PathComponent) return false;
    return ListEquality().equals(orders, other.orders) &&
        ListEquality().equals(points, other.points);
  }

  @override
  int get hashCode {
    return Object.hash(Object.hashAll(orders), Object.hashAll(points));
  }

  void _assertLocationHasValidElementIndex(
      IndexedPathComponentLocation location) {
    assert(
        location.elementIndex >= 0 && location.elementIndex < numberOfElements);
  }

  void _assertionFailureBadCurveOrder(int order) {
    assert(false,
        "unexpected curve order $order. Expected between 0 (point) and 3 (cubic curve).");
  }

  Point point({required IndexedPathComponentLocation at}) {
    _assertLocationHasValidElementIndex(at);
    final elementIndex = at.elementIndex;
    final t = at.t;
    final order = orders[elementIndex];
    switch (orders[elementIndex]) {
      case 3:
        return cubic(at: elementIndex).point(at: t);
      case 2:
        return quadratic(at: elementIndex).point(at: t);
      case 1:
        return line(at: elementIndex).point(at: t);
      case 0:
        return points[_offsets[elementIndex]];
      default:
        _assertionFailureBadCurveOrder(order);
        return points[_offsets[elementIndex]];
    }
  }

  Point derivative({required IndexedPathComponentLocation at}) {
    _assertLocationHasValidElementIndex(at);
    final elementIndex = at.elementIndex;
    final t = at.t;
    final order = orders[elementIndex];
    switch (order) {
      case 3:
        return cubic(at: elementIndex).derivative(at: t);
      case 2:
        return quadratic(at: elementIndex).derivative(at: t);
      case 1:
        return line(at: elementIndex).derivative(at: t);
      case 0:
        return Point.zero;
      default:
        _assertionFailureBadCurveOrder(order);
        return Point.zero;
    }
  }

  Point normal({required IndexedPathComponentLocation at}) {
    _assertLocationHasValidElementIndex(at);
    final elementIndex = at.elementIndex;
    final t = at.t;
    final order = orders[elementIndex];
    switch (order) {
      case 3:
        return cubic(at: elementIndex).normal(at: t);
      case 2:
        return quadratic(at: elementIndex).normal(at: t);
      case 1:
        return line(at: elementIndex).normal(at: t);
      case 0:
        return Point(x: double.nan, y: double.nan);
      default:
        _assertionFailureBadCurveOrder(order);
        return Point(x: double.nan, y: double.nan);
    }
  }

  // TODO: Check the places that were using this
  bool contains(Point point, {PathFillRule using = PathFillRule.winding}) {
    final windingCount = this.windingCount(at: point);
    return windingCountImpliesContainment(windingCount, using: using);
  }

  void enumeratePoints({
    required bool includeControlPoints,
    required void Function(Point) using,
  }) {
    if (includeControlPoints) {
      for (final p in points) {
        using(p);
      }
    } else {
      for (final o in _offsets) {
        using(points[o]);
      }
      if (points.length > 1) {
        using(points.last);
      }
    }
  }

  PathComponent splitStandardizedRange(PathComponentRange range) {
    assert(range.isStandardized);

    if (isPoint) return this;

    final start = range.start;
    final end = range.end;

    final resultPoints = <Point>[];
    final resultOrders = <int>[];

    void appendElement(
      int index,
      double start,
      double end, {
      required bool includeStart,
      required bool includeEnd,
    }) {
      assert(includeStart || includeEnd);
      final element = this.element(at: index).split(from: start, to: end);
      final startIndex = includeStart ? 0 : 1;
      final endIndex = includeEnd ? element.order : element.order - 1;
      resultPoints.addAll(element.points.sublist(startIndex, endIndex));
      resultOrders.add(orders[index]);
    }

    if (start.elementIndex == end.elementIndex) {
      // we just need to go from start.t to end.t
      appendElement(start.elementIndex, start.t, end.t,
          includeStart: true, includeEnd: true);
    } else {
      // if end.t = 1, add from start.elementIndex+1 through end.elementIndex, otherwise to end.elementIndex
      final lastFullElementIndex =
          end.t != 1.0 ? (end.elementIndex - 1) : end.elementIndex;
      final firstFullElementIndex =
          start.t != 0.0 ? (start.elementIndex + 1) : start.elementIndex;
      // if needed, add start.elementIndex from t=start.t to t=1
      if (firstFullElementIndex != start.elementIndex) {
        appendElement(start.elementIndex, start.t, 1.0,
            includeStart: true, includeEnd: false);
      }
      // if there exist full elements to copy, use the fast path to get them all in one fell swoop
      final hasFullElements = firstFullElementIndex <= lastFullElementIndex;
      if (hasFullElements) {
        resultPoints.addAll(points.sublist(_offsets[firstFullElementIndex],
            _offsets[lastFullElementIndex] + orders[lastFullElementIndex]));
        resultOrders.addAll(
            orders.sublist(firstFullElementIndex, lastFullElementIndex));
      }
      // if needed, add from end.elementIndex from t=0, to t=end.t
      if (lastFullElementIndex != end.elementIndex) {
        appendElement(end.elementIndex, 0.0, end.t,
            includeStart: !hasFullElements, includeEnd: true);
      }
    }
    return PathComponent(points: resultPoints, orders: resultOrders);
  }

  PathComponent splitRange(PathComponentRange range) {
    final reverse = range.end < range.start;
    final result = splitStandardizedRange(range.standardized);
    return reverse ? result.reversed() : result;
  }

  PathComponent split({
    required IndexedPathComponentLocation from,
    required IndexedPathComponentLocation to,
  }) {
    return splitRange(PathComponentRange(from: from, to: to));
  }

  @override
  PathComponent reversed() {
    return PathComponent(
        points: points.reversed.toList(), orders: orders.reversed.toList());
  }

  @override
  PathComponent copy({required AffineTransform using}) {
    return PathComponent(
        points: points.map(($0) => $0.applying(using)).toList(),
        orders: orders);
  }
}

class IndexedPathComponentLocation {
  final int elementIndex;
  final double t;

  const IndexedPathComponentLocation({
    required this.elementIndex,
    required this.t,
  });

  bool operator <(IndexedPathComponentLocation rhs) {
    if (elementIndex < rhs.elementIndex) {
      return true;
    } else if (elementIndex > rhs.elementIndex) {
      return false;
    }
    return t < rhs.t;
  }

  bool operator >(IndexedPathComponentLocation rhs) {
    if (elementIndex > rhs.elementIndex) {
      return true;
    } else if (elementIndex < rhs.elementIndex) {
      return false;
    }
    return t > rhs.t;
  }

  bool operator <=(IndexedPathComponentLocation rhs) {
    if (elementIndex <= rhs.elementIndex) {
      return true;
    } else if (elementIndex >= rhs.elementIndex) {
      return false;
    }
    return t <= rhs.t;
  }

  bool operator >=(IndexedPathComponentLocation rhs) {
    if (elementIndex >= rhs.elementIndex) {
      return true;
    } else if (elementIndex <= rhs.elementIndex) {
      return false;
    }
    return t >= rhs.t;
  }
}

class PathComponentIntersection {
  final IndexedPathComponentLocation indexedComponentLocation1,
      indexedComponentLocation2;
  PathComponentIntersection({
    required this.indexedComponentLocation1,
    required this.indexedComponentLocation2,
  });
}

// TODO: Ver o que pode ser const
class PathComponentRange {
  final IndexedPathComponentLocation start;
  final IndexedPathComponentLocation end;
  const PathComponentRange(
      {required IndexedPathComponentLocation from,
      required IndexedPathComponentLocation to})
      : start = from,
        end = to;

  bool get isStandardized => this == standardized;

  /// the range standardized so that end >= start and adjusted to avoid possible degeneracies when splitting components
  PathComponentRange get standardized {
    var start = this.start;
    var end = this.end;
    if (end < start) {
      (start, end) = (end, start);
    }
    if (start.elementIndex < end.elementIndex) {
      if (start.t == 1.0) {
        final candidate = IndexedPathComponentLocation(
            elementIndex: start.elementIndex + 1, t: 0.0);
        if (candidate <= end) {
          start = candidate;
        }
      }
      if (end.t == 0.0) {
        final candidate = IndexedPathComponentLocation(
            elementIndex: end.elementIndex - 1, t: 1.0);
        if (candidate >= start) {
          end = candidate;
        }
      }
    }
    return PathComponentRange(from: start, to: end);
  }
}
