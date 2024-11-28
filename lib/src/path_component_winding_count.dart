// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'package:bezier_kit/src/bezier_curve.dart';
import 'package:bezier_kit/src/bounding_box_hierarchy.dart';
import 'package:bezier_kit/src/path_component.dart';
import 'package:bezier_kit/src/point.dart';
import 'package:bezier_kit/src/types.dart';
import 'package:bezier_kit/src/utils.dart';

double _xIntercept<A extends BezierCurve>(
    {required A curve, required double y}) {
  final startingPoint = curve.startingPoint;
  final endingPoint = curve.endingPoint;
  if (y == curve.startingPoint.y) return curve.startingPoint.x;
  if (y == curve.endingPoint.y) return curve.endingPoint.x;
  final linearSolutionT =
      (y - startingPoint.y) / (endingPoint.y - startingPoint.y);
  final linearSolution = LineSegment(p0: startingPoint, p1: endingPoint)
      .point(at: linearSolutionT)
      .x;
  double? solution;
  void callback(double root) {
    if (root < 0.0 || root > 1.0) return;
    solution = solution ?? root;
  }

  switch (curve) {
    case QuadraticCurve():
      Utils.droots3(curve.p0.y - y, curve.p1.y - y, curve.p2.y - y,
          callback: callback);
    case CubicCurve():
      Utils.droots4(
          curve.p0.y - y, curve.p1.y - y, curve.p2.y - y, curve.p3.y - y,
          callback: callback);
    default:
      break;
  }
  if (solution != null) {
    return curve.point(at: solution!).x;
  }
  return linearSolution;
}

int _windingCountAdjustment(double y, double startY, double endY) {
  if (endY < y && y <= startY) {
    return 1;
  } else if (startY < y && y <= endY) {
    return -1;
  } else {
    return 0;
  }
}

int windingCountIncrementer<A extends BezierCurve>(
  A curve, {
  required BoundingBox boundingBox,
  required Point point,
}) {
  if (boundingBox.min.x > point.x) return 0;
  // we include the highest point and exclude the lowest point
  // that ensures if the juncture between curves changes direction it's counted twice or not at all
  // and if the juncture between curves does not change direction it's counted exactly once
  final increment = _windingCountAdjustment(
      point.y, curve.startingPoint.y, curve.endingPoint.y);
  if (increment == 0) return 0;
  if (boundingBox.max.x >= point.x) {
    // slowest path: must determine x intercept and test against it
    final x = _xIntercept(curve: curve, y: point.y);
    if (point.x <= x) return 0;
  }
  return increment;
}

extension PathComponentExtension on PathComponent {
  void _enumerateYMonotonicComponentsForQuadratic({
    required int at,
    required void Function(QuadraticCurve) callback,
  }) {
    final curve = quadratic(at: at);
    final p0 = curve.p0;
    final p1 = curve.p1;
    final p2 = curve.p2;
    final d0 = p1.y - p0.y;
    final d1 = p2.y - p1.y;
    var last = 0.0;
    Utils.droots(d0, d1, callback: (t) {
      if (t <= 0 || t >= 1) return;
      callback(curve.split(from: last, to: t));
      last = t;
    });
    if (last < 1.0) {
      callback(curve.split(from: last, to: 1.0));
    }
  }

  void _enumerateYMonotonicComponentsForCubic({
    required int at,
    required void Function(CubicCurve) callback,
  }) {
    final curve = cubic(at: at);
    final p0 = curve.p0;
    final p1 = curve.p1;
    final p2 = curve.p2;
    final p3 = curve.p3;
    final d0 = p1.y - p0.y;
    final d1 = p2.y - p1.y;
    final d2 = p3.y - p2.y;
    var last = 0.0;
    Utils.droots3(d0, d1, d2, callback: (t) {
      if (t <= 0 || t >= 1) return;
      callback(curve.split(from: last, to: t));
      last = t;
    });
    if (last < 1.0) {
      callback(curve.split(from: last, to: 1.0));
    }
  }

  int windingCount({required Point at}) {
    if (!isClosed || !boundingBox.contains(at)) return 0;

    var windingCount = 0;
    bvh.visit((node, _) {
      final boundingBox = node.boundingBox;
      if (boundingBox.min.y > at.y ||
          boundingBox.max.y < at.y ||
          boundingBox.min.x > at.x) {
        // ray cast from at in -x direction does not intersect node's bounding box, nothing to do
        return false;
      }
      if (boundingBox.max.x < at.x) {
        // ray cast from at in -x direction intersects the node's bounding box
        // but we are outside bounding box in +x direction
        // as an optimization we can avoid visiting any of node's children
        // beause we need only adjust the winding count if y coordinate falls between start and end y
        final int startingElementIndex;
        final int endingElementIndex;
        switch (node.type) {
          case BoundingBoxHierarchyNodeTypeLeaf(:final index):
            startingElementIndex = index;
            endingElementIndex = index;
          case BoundingBoxHierarchyNodeTypeInternal(:final start, :final end):
            startingElementIndex = start;
            endingElementIndex = end;
        }
        final startingPoint = startingPointForElement(at: startingElementIndex);
        final endingPoint = endingPointForElement(at: endingElementIndex);
        windingCount +=
            _windingCountAdjustment(at.y, startingPoint.y, endingPoint.y);
        return false;
      }

      final int elementIndex;
      switch (node.type) {
        case BoundingBoxHierarchyNodeTypeLeaf(:final index):
          elementIndex = index;
          break;
        case BoundingBoxHierarchyNodeTypeInternal():
          // internal node where at falls within bounding box: recursively visit child nodes
          return true;
      }

      // now we are assured that node is a leaf node and at falls within the node's bounding box
      final order = orders[elementIndex];
      switch (order) {
        case 0:
          windingCount += 0;
          break;
        case 1:
          windingCount += windingCountIncrementer(line(at: elementIndex),
              boundingBox: boundingBox, point: at);
          break;
        case 2:
          _enumerateYMonotonicComponentsForQuadratic(
              at: elementIndex,
              callback: ($0) {
                windingCount += windingCountIncrementer($0,
                    boundingBox: boundingBox, point: at);
              });
          break;
        case 3:
          _enumerateYMonotonicComponentsForCubic(
              at: elementIndex,
              callback: ($0) {
                windingCount += windingCountIncrementer($0,
                    boundingBox: boundingBox, point: at);
              });
          break;
        default:
          throw Exception("unsupported");
      }
      return true;
    });
    return windingCount;
  }
}
