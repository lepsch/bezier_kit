//
//  Shape.swift
//  BezierKit
//
//  Created by Holmes Futrell on 1/13/18.
//  Copyright © 2018 Holmes Futrell. All rights reserved.
//

import 'package:bezier_kit/src/bezier_curve.dart';
import 'package:bezier_kit/src/types.dart';
import 'package:collection/collection.dart';

class ShapeIntersection {
  final BezierCurve curve1;
  final BezierCurve curve2;
  final List<Intersection> intersections;

  ShapeIntersection(
      {required this.curve1,
      required this.curve2,
      required this.intersections});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ShapeIntersection) return false;
    return curve1 == other.curve1 &&
        curve2 == other.curve2 &&
        ListEquality().equals(intersections, other.intersections);
  }

  @override
  int get hashCode =>
      Object.hashAll([curve1.hashCode, curve2.hashCode, ...intersections]);
}

class ShapeCap {
  final BezierCurve curve;
  final bool
      virtual; // a cap is virtual if it is internal (not part of the outline of the boundary)
  ShapeCap({required this.curve, required this.virtual});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ShapeCap) return false;
    return curve == other.curve && virtual == other.virtual;
  }

  @override
  int get hashCode => Object.hash(curve.hashCode, virtual.hashCode);
}

class Shape {
  static const defaultShapeIntersectionThreshold = 0.5;
  final ShapeCap startcap;
  final ShapeCap endcap;
  final BezierCurve forward;
  final BezierCurve back;

  Shape(this.forward, this.back, bool startCapVirtual, bool endCapVirtual)
      : startcap = ShapeCap(
            curve: LineSegment(p0: back.endingPoint, p1: forward.startingPoint),
            virtual: startCapVirtual),
        endcap = ShapeCap(
            curve: LineSegment(p0: forward.endingPoint, p1: back.startingPoint),
            virtual: endCapVirtual);

  BoundingBox get boundingBox {
    return _nonvirtualSegments().fold(BoundingBox.empty,
        ($0, $1) => BoundingBox.fromBox(first: $0, second: $1.boundingBox));
  }

  List<BezierCurve> _nonvirtualSegments() {
    final segments = <BezierCurve>[];
    segments.add(forward);
    if (endcap.virtual == false) {
      segments.add(endcap.curve);
    }
    segments.add(back);
    if (startcap.virtual == false) {
      segments.add(startcap.curve);
    }
    return segments;
  }

  List<ShapeIntersection> intersects({
    required Shape shape,
    double accuracy = defaultIntersectionAccuracy,
  }) {
    if (boundingBox.overlaps(shape.boundingBox) == false) return [];

    final intersections = <ShapeIntersection>[];
    final a1 = _nonvirtualSegments();
    final a2 = shape._nonvirtualSegments();
    for (final l1 in a1) {
      for (final l2 in a2) {
        final iss = l1.intersectionsWithCurve(l2, accuracy: accuracy);
        if (iss.isNotEmpty) {
          intersections.add(
              ShapeIntersection(curve1: l1, curve2: l2, intersections: iss));
        }
      }
    }
    return intersections;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Shape) return false;
    return startcap == other.startcap &&
        endcap == other.endcap &&
        forward == other.forward &&
        back == other.back;
  }

  @override
  int get hashCode => Object.hash(startcap, endcap, forward, back);
}
