//
//  BezierPath.swift
//  BezierKit
//
//  Created by Holmes Futrell on 7/31/18.
//  Copyright © 2018 Holmes Futrell. All rights reserved.
//

import 'dart:math';
import 'dart:typed_data';

import 'package:bezier_kit/src/affine_transform.dart';
import 'package:bezier_kit/src/bezier_curve.dart';
import 'package:bezier_kit/src/mutable_path.dart';
import 'package:bezier_kit/src/path_component.dart';
import 'package:bezier_kit/src/path_component_winding_count.dart';
import 'package:bezier_kit/src/path_data.dart';
import 'package:bezier_kit/src/path_internals.dart';
import 'package:bezier_kit/src/point.dart';
import 'package:bezier_kit/src/rectangle_extension.dart';
import 'package:bezier_kit/src/types.dart';
import 'package:collection/collection.dart';

enum PathFillRule { winding, evenOdd }

abstract interface class PathBase {
  abstract final List<PathComponent> components;
}

class Path extends PathBase
    with PathDataMixin
    implements Transformable, Reversible {
  // components are not allowed to be empty
  bool get isEmpty => components.isEmpty;
  bool get isNotEmpty => !isEmpty;

  BoundingBox get boundingBox => _boundingBox;

  /// the smallest bounding box completely enclosing the points of the path, includings its control points.
  BoundingBox get boundingBoxOfPath => _boundingBoxOfPath;

  BoundingBox get _boundingBox {
    return _lazyBoundingBox ??
        (_lazyBoundingBox = components.fold<BoundingBox>(
            BoundingBox.empty,
            ($0, $1) =>
                BoundingBox.fromBox(first: $0, second: $1.boundingBox)));
  }

  BoundingBox? _lazyBoundingBox;

  BoundingBox get _boundingBoxOfPath {
    return _lazyBoundingBoxOfPath ??
        (_lazyBoundingBoxOfPath = components.fold<BoundingBox>(
            BoundingBox.empty,
            ($0, $1) =>
                BoundingBox.fromBox(first: $0, second: $1.boundingBoxOfPath)));
  }

  BoundingBox? _lazyBoundingBoxOfPath;

  @override
  final List<PathComponent> components;

  bool selfIntersects({double accuracy = defaultIntersectionAccuracy}) {
    return selfIntersections(accuracy: accuracy).isNotEmpty;
  }

  List<PathIntersection> selfIntersections({
    double accuracy = defaultIntersectionAccuracy,
  }) {
    var intersections = <PathIntersection>[];
    for (var i = 0; i < components.length; i++) {
      for (var j = i; j < components.length; j++) {
        PathIntersection componentIntersectionToPathIntersection(
            PathComponentIntersection componentIntersection) {
          return PathIntersection._(
            componentIntersection: componentIntersection,
            componentIndex1: i,
            componentIndex2: j,
          );
        }

        if (i == j) {
          intersections += components[i]
              .selfIntersections(accuracy: accuracy)
              .map(componentIntersectionToPathIntersection)
              .toList();
        } else {
          intersections += components[i]
              .intersections(components[j], accuracy: accuracy)
              .map(componentIntersectionToPathIntersection)
              .toList();
        }
      }
    }
    return intersections;
  }

  bool intersects(
    Path other, {
    double accuracy = defaultIntersectionAccuracy,
  }) {
    return intersections(other: other, accuracy: accuracy).isNotEmpty;
  }

  List<PathIntersection> intersections({
    required Path other,
    double accuracy = defaultIntersectionAccuracy,
  }) {
    if (!boundingBox.overlaps(other.boundingBox)) return [];

    var intersections = <PathIntersection>[];
    for (var i = 0; i < components.length; i++) {
      for (var j = 0; j < other.components.length; j++) {
        PathIntersection componentIntersectionToPathIntersection(
                PathComponentIntersection componentIntersection) =>
            PathIntersection._(
                componentIntersection: componentIntersection,
                componentIndex1: i,
                componentIndex2: j);

        final s1 = components[i];
        final s2 = other.components[j];
        final componentIntersections = s1.intersections(s2, accuracy: accuracy);
        intersections += componentIntersections
            .map(componentIntersectionToPathIntersection)
            .toList();
      }
    }
    return intersections;
  }

  Path({List<PathComponent>? components, Rectangle? ellipseIn})
      : components = components ?? [] {
    if (ellipseIn != null) {
      this.components.addAll(MutablePath(ellipseIn: ellipseIn).components);
    }
  }

  Path.fromCurve(BezierCurve curve)
      : this(components: [PathComponent(curve: curve)]);

  factory Path.fromRect(Rectangle rect) {
    return Path()..addRect(rect);
  }

  static Path? Function(Uint8List data) fromData = PathDataMixin.fromData;

  void addRect(Rectangle rect) {
    final points = [
      rect.origin,
      Point(x: rect.origin.x + rect.width, y: rect.origin.y),
      Point(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height),
      Point(x: rect.origin.x, y: rect.origin.y + rect.height),
      rect.origin,
    ];
    final component =
        PathComponent.raw(points: points, orders: List.filled(4, 1));
    components.add(component);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Path) return false;
    return ListEquality().equals(components, other.components);
  }

  @override
  int get hashCode => Object.hashAll(components);

  void _assertValidComponent(IndexedPathLocation location) {
    assert(location.componentIndex >= 0 &&
        location.componentIndex < components.length);
  }

  Point point({required IndexedPathLocation at}) {
    _assertValidComponent(at);
    return components[at.componentIndex].point(at: at.locationInComponent);
  }

  Point derivative({required IndexedPathLocation at}) {
    _assertValidComponent(at);
    return components[at.componentIndex].derivative(at: at.locationInComponent);
  }

  Point normal({required IndexedPathLocation at}) {
    _assertValidComponent(at);
    return components[at.componentIndex].normal(at: at.locationInComponent);
  }

  int windingCount(Point point, {PathComponent? ignoring}) {
    final windingCount = components.fold(0, ($0, $1) {
      if ($1 != ignoring) {
        return $0 + $1.windingCount(at: point);
      }
      return $0;
    });
    return windingCount;
  }

  bool contains(Point point, {PathFillRule using = PathFillRule.winding}) {
    final length = windingCount(point);
    return windingCountImpliesContainment(length, using: using);
  }

  bool containsPath(
    Path other, {
    PathFillRule using = PathFillRule.winding,
    double accuracy = defaultIntersectionAccuracy,
  }) {
    // first, check that each component of `other` starts inside this
    for (final component in other.components) {
      final p = component.startingPoint;
      if (!contains(p, using: using)) return false;
    }
    // next, for each intersection (if there are any) check that we stay inside the path
    // TODO: use enumeration over intersections so we don't have to necessarily have to find each one
    // TODO: make this work with winding fill rule and intersections that don't cross (suggestion, use AugmentedGraph)
    return !intersects(other, accuracy: accuracy);
  }

  Path offset({required double distance}) {
    return Path(
      components: components
          .map(($0) => $0.offset(distance: distance))
          .nonNulls
          .toList(),
    );
  }

  List<Path> disjointComponents() {
    final rule = PathFillRule.evenOdd;
    var outerComponents = <PathComponent, List<PathComponent>>{};
    var innerComponents = <PathComponent>[];
    // determine which components are outer and which are inner
    for (final component in components) {
      final windingCount =
          this.windingCount(component.startingPoint, ignoring: component);
      if (windingCountImpliesContainment(windingCount, using: rule)) {
        innerComponents.add(component);
      } else {
        outerComponents[component] = [component];
      }
    }
    // file the inner components into their "owning" outer components
    for (final component in innerComponents) {
      PathComponent? owner;
      for (final outer in outerComponents.keys) {
        if (owner != null) {
          if (outer.boundingBox.intersection(owner.boundingBox) !=
              outer.boundingBox) {
            continue;
          }
        }
        if (outer.contains(component.startingPoint, using: rule)) {
          owner = outer;
        }
      }
      if (owner != null) {
        outerComponents[owner]?.add(component);
      }
    }
    return outerComponents.values.map(($0) => Path(components: $0)).toList();
  }

  @override
  Path reversed() {
    return Path(components: components.map(($0) => $0.reversed()).toList());
  }

  @override
  Path copy({required AffineTransform using}) {
    return Path(
        components: components.map(($0) => $0.copy(using: using)).toList());
  }
}

class IndexedPathLocation {
  final int componentIndex;
  final int elementIndex;
  final double t;
  const IndexedPathLocation({
    required this.componentIndex,
    required this.elementIndex,
    required this.t,
  });

  factory IndexedPathLocation.fromComponent({
    required int componentIndex,
    required IndexedPathComponentLocation locationInComponent,
  }) {
    return IndexedPathLocation(
      componentIndex: componentIndex,
      elementIndex: locationInComponent.elementIndex,
      t: locationInComponent.t,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! IndexedPathLocation) return false;
    return componentIndex == other.componentIndex &&
        elementIndex == other.elementIndex &&
        t == other.t;
  }

  @override
  int get hashCode => Object.hash(componentIndex, elementIndex, t);

  bool operator <(IndexedPathLocation rhs) {
    if (componentIndex < rhs.componentIndex) {
      return true;
    } else if (componentIndex > rhs.componentIndex) {
      return false;
    }
    if (elementIndex < rhs.elementIndex) {
      return true;
    } else if (elementIndex > rhs.elementIndex) {
      return false;
    }
    return t < rhs.t;
  }

  bool operator >(IndexedPathLocation rhs) {
    if (componentIndex > rhs.componentIndex) {
      return true;
    } else if (componentIndex < rhs.componentIndex) {
      return false;
    }
    if (elementIndex > rhs.elementIndex) {
      return true;
    } else if (elementIndex < rhs.elementIndex) {
      return false;
    }
    return t > rhs.t;
  }

  IndexedPathComponentLocation get locationInComponent {
    return IndexedPathComponentLocation(elementIndex: elementIndex, t: t);
  }
}

class PathIntersection {
  final IndexedPathLocation indexedPathLocation1, indexedPathLocation2;
  const PathIntersection({
    required this.indexedPathLocation1,
    required this.indexedPathLocation2,
  });

  PathIntersection._({
    required PathComponentIntersection componentIntersection,
    required int componentIndex1,
    required int componentIndex2,
  })  : indexedPathLocation1 = IndexedPathLocation.fromComponent(
            componentIndex: componentIndex1,
            locationInComponent:
                componentIntersection.indexedComponentLocation1),
        indexedPathLocation2 = IndexedPathLocation.fromComponent(
            componentIndex: componentIndex2,
            locationInComponent:
                componentIntersection.indexedComponentLocation2);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PathIntersection) return false;
    return indexedPathLocation1 == other.indexedPathLocation1 &&
        indexedPathLocation2 == other.indexedPathLocation2;
  }

  @override
  int get hashCode => Object.hash(indexedPathLocation1, indexedPathLocation2);
}
