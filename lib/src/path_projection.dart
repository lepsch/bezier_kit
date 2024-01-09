//
//  Path+Project.swift
//  BezierKit
//
//  Created by Holmes Futrell on 11/23/20.
//  Copyright © 2020 Holmes Futrell. All rights reserved.
//

import 'package:bezier_kit/src/bounding_box_hierarchy.dart';
import 'package:bezier_kit/src/path.dart';
import 'package:bezier_kit/src/path_component.dart';
import 'package:bezier_kit/src/point.dart';
import 'package:collection/collection.dart';

typedef _Candidate = ({Point point, IndexedPathLocation location});

extension PathProjectionExtension on Path {
  _Candidate? _searchForClosestLocation({
    required Point to,
    required double maximumDistance,
    required bool requireBest,
  }) {
    // sort the components by proximity to avoid searching distant components later on
    final tuples = components.indexed.map((p) {
      final (i, component) = p;
      final boundingBox = component.boundingBox;
      final upper = boundingBox.upperBoundOfDistance(to: to);
      return (component: component, index: i, upperBound: upper);
    }).sorted(($0, $1) => $0.upperBound < $1.upperBound
        ? -1
        : ($0.upperBound > $1.upperBound ? 1 : 0));
    // iterate through each component and search for closest point
    _Candidate? bestSoFar;
    for (final next in tuples) {
      final projection = next.component._searchForClosestLocation(
          to: to, maximumDistance: maximumDistance, requireBest: requireBest);
      if (projection == null) continue;

      final projectionDistance = distance(to, projection.point);
      assert(projectionDistance <= maximumDistance);
      final candidate = (
        point: projection.point,
        location: IndexedPathLocation.fromComponent(
            componentIndex: next.index,
            locationInComponent: projection.location)
      );
      maximumDistance = projectionDistance;
      bestSoFar = candidate;
    }
    // return the best answer
    final best = bestSoFar;
    if (best != null) {
      return (point: best.point, location: best.location);
    }
    return null;
  }

  ({Point point, IndexedPathLocation location})? project(Point point) {
    return _searchForClosestLocation(
        to: point, maximumDistance: double.infinity, requireBest: true);
  }

  bool pointIsWithinDistanceOfBoundary(
    Point point, {
    required double distance,
  }) {
    return _searchForClosestLocation(
            to: point, maximumDistance: distance, requireBest: false) !=
        null;
  }
}

extension PathComponentProjectionExtension on PathComponent {
  IndexedPathComponentLocation _anyLocation(BoundingBoxHierarchyNode node) {
    switch (node.type) {
      case BoundingBoxHierarchyNodeTypeLeaf(:final index):
        return IndexedPathComponentLocation(elementIndex: index, t: 0);
      case BoundingBoxHierarchyNodeTypeInternal(:final start):
        return IndexedPathComponentLocation(elementIndex: start, t: 0);
    }
  }

  ({Point point, IndexedPathComponentLocation location})?
      _searchForClosestLocation({
    required Point to,
    required double maximumDistance,
    required bool requireBest,
  }) {
    IndexedPathComponentLocation? bestSoFar;
    bvh.visit((node, _) {
      if (!requireBest && bestSoFar != null) {
        return false; // we're done already
      }
      final boundingBox = node.boundingBox;
      final lowerBound = boundingBox.lowerBoundOfDistance(to: to);
      if (lowerBound > maximumDistance) {
        return false; // nothing in this node can be within maximum distance
      }
      if (requireBest == false) {
        final upperBound = boundingBox.upperBoundOfDistance(to: to);
        if (upperBound <= maximumDistance) {
          // restrict the search to this new upper bound
          maximumDistance = upperBound;
          bestSoFar = _anyLocation(node);
          return false;
        }
      }
      switch (node.type) {
        case BoundingBoxHierarchyNodeTypeLeaf(:final index):
          final curve = element(at: index);
          final projection = curve.project(to);
          final distanceToCurve = distance(to, projection.point);
          if (distanceToCurve <= maximumDistance) {
            maximumDistance = distanceToCurve;
            bestSoFar = IndexedPathComponentLocation(
                elementIndex: index, t: projection.t);
          }
          break;
        default:
          break; // visit children (if they exist)
      }
      return true; // visit children (if they exist)
    });
    if (bestSoFar != null) {
      return (point: point(at: bestSoFar!), location: bestSoFar!);
    }
    return null;
  }

  ({Point point, IndexedPathComponentLocation location}) project(Point point) {
    final result = _searchForClosestLocation(
        to: point, maximumDistance: double.infinity, requireBest: true);
    assert(result != null, "expected non-empty result");
    if (result == null) {
      return (point: startingPoint, location: startingIndexedLocation);
    }
    return result;
  }

  bool pointIsWithinDistanceOfBoundary(Point point,
      {required double distance}) {
    return _searchForClosestLocation(
          to: point,
          maximumDistance: distance,
          requireBest: false,
        ) !=
        null;
  }
}
