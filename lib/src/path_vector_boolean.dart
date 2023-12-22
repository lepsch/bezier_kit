//
//  Path+VectorBoolean.swift
//  BezierKit
//
//  Created by Holmes Futrell on 2/8/21.
//  Copyright © 2021 Holmes Futrell. All rights reserved.
//

import 'package:bezier_kit/src/augmented_graph.dart';
import 'package:bezier_kit/src/bezier_curve.dart';
import 'package:bezier_kit/src/path.dart';

extension PathVectorBooleanExtension on Path {
  Path subtract(Path other, {double accuracy = defaultIntersectionAccuracy}) {
    return performBooleanOperation(
      BooleanPathOperation.subtract,
      other: other.reversed(),
      accuracy: accuracy,
    );
  }

  Path union(Path other, {double accuracy = defaultIntersectionAccuracy}) {
    if (isEmpty) return other;
    if (other.isEmpty) return this;

    return performBooleanOperation(
      BooleanPathOperation.union,
      other: other,
      accuracy: accuracy,
    );
  }

  Path intersect(Path other, {double accuracy = defaultIntersectionAccuracy}) {
    return performBooleanOperation(
      BooleanPathOperation.intersect,
      other: other,
      accuracy: accuracy,
    );
  }

  Path crossingsRemoved({double accuracy = defaultIntersectionAccuracy}) {
    final intersections = selfIntersections(accuracy: accuracy);
    final augmentedGraph = AugmentedGraph(
      path1: this,
      path2: this,
      intersections: intersections,
      operation: BooleanPathOperation.removeCrossings,
    );
    return augmentedGraph.performOperation();
  }
}

extension on Path {
  Path performBooleanOperation(BooleanPathOperation operation,
      {required Path other, required double accuracy}) {
    final intersections = this.intersections(other: other, accuracy: accuracy);
    final augmentedGraph = AugmentedGraph(
      path1: this,
      path2: other,
      intersections: intersections,
      operation: operation,
    );
    return augmentedGraph.performOperation();
  }
}
