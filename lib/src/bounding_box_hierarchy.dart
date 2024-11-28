// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'package:bezier_kit/src/types.dart';

/// returns the power of two greater than or equal to a given value
// TODO: Move internal functions to a separate file as extension
int roundUpPowerOfTwo(int value) {
  var result = 1;
  while (result < value) {
    result = result << 1;
  }
  return result;
}

/// left child node index by the formula 2*index+1
int _left(int index) {
  return 2 * index + 1;
}

/// right child node index by the formula 2*index+2
int _right(int index) {
  return 2 * index + 2;
}

/// parent node index index by the formula (index-1) / 2
int _parent(int index) {
  return (index - 1) ~/ 2;
}

class BoundingBoxHierarchyNodeTypeLeaf extends BoundingBoxHierarchyNodeType {
  final int index;

  BoundingBoxHierarchyNodeTypeLeaf._(this.index) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoundingBoxHierarchyNodeTypeLeaf && index == other.index;

  @override
  int get hashCode => index.hashCode;
}

class BoundingBoxHierarchyNodeTypeInternal
    extends BoundingBoxHierarchyNodeType {
  final int start;
  final int end;

  BoundingBoxHierarchyNodeTypeInternal._(this.start, this.end) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoundingBoxHierarchyNodeTypeInternal &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

sealed class BoundingBoxHierarchyNodeType {
  const BoundingBoxHierarchyNodeType._();

  static BoundingBoxHierarchyNodeType leaf({required int index}) =>
      BoundingBoxHierarchyNodeTypeLeaf._(index);
  static BoundingBoxHierarchyNodeType internal({
    required int startingElementIndex,
    required int endingElementIndex,
  }) =>
      BoundingBoxHierarchyNodeTypeInternal._(
        startingElementIndex,
        endingElementIndex,
      );
}

class BoundingBoxHierarchyNode {
  final BoundingBox boundingBox;
  final BoundingBoxHierarchyNodeType type;
  BoundingBoxHierarchyNode({required this.boundingBox, required this.type});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoundingBoxHierarchyNode &&
          boundingBox == other.boundingBox &&
          type == other.type;

  @override
  int get hashCode => Object.hash(boundingBox, type);
}

/// a strict (complete and full) binary tree representing a hierarchy of bounding boxes for a list of path elements
final class BoundingBoxHierarchy {
  final List<BoundingBox> _boundingBoxes;
  final int _lastRowIndex;
  final int _elementCount;

  static int leafNodeIndexToElementIndex(
    int nodeIndex, {
    required int elementCount,
    required int lastRowIndex,
  }) {
    assert(isLeaf(nodeIndex, elementCount: elementCount));
    var elementIndex = nodeIndex - lastRowIndex;
    if (elementIndex < 0) {
      elementIndex += elementCount;
    }
    return elementIndex;
  }

  static int elementIndexToNodeIndex(int elementIndex,
      {required int elementCount, required int lastRowIndex}) {
    assert(elementIndex >= 0 && elementIndex < elementCount);
    var nodeIndex = elementIndex + lastRowIndex;
    if (nodeIndex >= 2 * elementCount - 1) {
      nodeIndex -= elementCount;
    }
    return nodeIndex;
  }

  static bool isLeaf(int index, {required int elementCount}) {
    return index >= elementCount - 1;
  }

  BoundingBox get boundingBox => _boundingBoxes[0];

  BoundingBox boundingBoxAt(int at) {
    return _boundingBoxes[BoundingBoxHierarchy.elementIndexToNodeIndex(at,
        elementCount: _elementCount, lastRowIndex: _lastRowIndex)];
  }

  BoundingBoxHierarchy._(
    this._boundingBoxes,
    this._lastRowIndex,
    this._elementCount,
  );

  factory BoundingBoxHierarchy({required List<BoundingBox> boxes}) {
    assert(boxes.isNotEmpty);
    final elementCount = boxes.length;
    // in complete binary tree the number of inodes (internal nodes) is one fewer than the leafs
    final inodeCount = elementCount - 1;
    // compute `lastRowIndex` the index of the first leaf node in the bottom row of the tree
    var lastRowIndex = 0;
    while (lastRowIndex < inodeCount) {
      lastRowIndex = _left(lastRowIndex);
    }
    // compute bounding boxes
    final elementBoxes = boxes;
    boxes = List<BoundingBox?>.filled(elementCount + inodeCount, null).cast();
    for (var i = 0; i < elementCount; i++) {
      final nodeIndex = i + inodeCount;
      final elementIndex = leafNodeIndexToElementIndex(nodeIndex,
          elementCount: elementCount, lastRowIndex: lastRowIndex);
      boxes[nodeIndex] = elementBoxes[elementIndex];
    }
    for (var i = inodeCount - 1; i >= 0; i--) {
      boxes[i] =
          BoundingBox.fromBox(first: boxes[_left(i)], second: boxes[_right(i)]);
    }
    return BoundingBoxHierarchy._(boxes, lastRowIndex, elementCount);
  }

  void visit(bool Function(BoundingBoxHierarchyNode, int) callback) {
    final elementCount = _elementCount;
    final lastRowIndex = _lastRowIndex;
    final nodeCount = 2 * _elementCount & -1;
    final boxes = _boundingBoxes;

    void visitHelper({
      required int index,
      required int depth,
      required int maxLeafsInSubtree,
      required bool Function(BoundingBoxHierarchyNode, int) callback,
    }) {
      final leaf =
          BoundingBoxHierarchy.isLeaf(index, elementCount: elementCount);
      final BoundingBoxHierarchyNodeType nodeType;
      if (leaf) {
        nodeType = BoundingBoxHierarchyNodeType.leaf(
            index: BoundingBoxHierarchy.leafNodeIndexToElementIndex(index,
                elementCount: elementCount, lastRowIndex: lastRowIndex));
      } else {
        var startingIndex = maxLeafsInSubtree * (index + 1) - 1;
        var endingIndex = startingIndex + maxLeafsInSubtree - 1;
        if (endingIndex >= nodeCount) {
          endingIndex = _parent(endingIndex);
        }
        if (startingIndex >= nodeCount) {
          startingIndex = _parent(startingIndex);
        }
        final endingElementIndex =
            BoundingBoxHierarchy.leafNodeIndexToElementIndex(endingIndex,
                elementCount: elementCount, lastRowIndex: lastRowIndex);
        final startingElementIndex =
            BoundingBoxHierarchy.leafNodeIndexToElementIndex(startingIndex,
                elementCount: elementCount, lastRowIndex: lastRowIndex);
        nodeType = BoundingBoxHierarchyNodeType.internal(
            startingElementIndex: startingElementIndex,
            endingElementIndex: endingElementIndex);
      }
      final node =
          BoundingBoxHierarchyNode(boundingBox: boxes[index], type: nodeType);
      if (!callback(node, depth)) return;

      if (leaf == false) {
        final nextDepth = depth + 1;
        final nextMaxLeafsInSubtree = maxLeafsInSubtree ~/ 2;
        visitHelper(
          index: _left(index),
          depth: nextDepth,
          maxLeafsInSubtree: nextMaxLeafsInSubtree,
          callback: callback,
        );
        visitHelper(
          index: _right(index),
          depth: nextDepth,
          maxLeafsInSubtree: nextMaxLeafsInSubtree,
          callback: callback,
        );
      }
    }

    // maxLeafsInSubtree: refers to the number of leaf nodes in the subtree were the bottom level of the tree full
    visitHelper(
      index: 0,
      depth: 0,
      maxLeafsInSubtree: roundUpPowerOfTwo(elementCount),
      callback: callback,
    );
  }

  BoundingBox boundingBoxForElementIndex({required int index}) {
    return _boundingBoxes[BoundingBoxHierarchy.elementIndexToNodeIndex(
      index,
      elementCount: _elementCount,
      lastRowIndex: _lastRowIndex,
    )];
  }

  void enumerateSelfIntersections(void Function(int, int) callback) {
    enumerateIntersections(other: this, callback: callback);
  }

  void enumerateIntersections(
      {required BoundingBoxHierarchy other,
      required void Function(int, int) callback}) {
    final elementCount1 = _elementCount;
    final elementCount2 = other._elementCount;
    final boxes1 = _boundingBoxes;
    final boxes2 = other._boundingBoxes;
    final lastRowIndex1 = _lastRowIndex;
    final lastRowIndex2 = other._lastRowIndex;

    void intersects2({
      required int index1,
      required int index2,
      required void Function(int, int) callback,
    }) {
      if (!boxes1[index1].overlaps(boxes2[index2])) {
        return; // nothing to do
      }
      final leaf1 =
          BoundingBoxHierarchy.isLeaf(index1, elementCount: elementCount1);
      final leaf2 =
          BoundingBoxHierarchy.isLeaf(index2, elementCount: elementCount2);
      if (leaf1 && leaf2) {
        final elementIndex1 = BoundingBoxHierarchy.leafNodeIndexToElementIndex(
            index1,
            elementCount: elementCount1,
            lastRowIndex: lastRowIndex1);
        final elementIndex2 = BoundingBoxHierarchy.leafNodeIndexToElementIndex(
            index2,
            elementCount: elementCount2,
            lastRowIndex: lastRowIndex2);
        callback(elementIndex1, elementIndex2);
      } else if (leaf1) {
        intersects2(index1: index1, index2: _left(index2), callback: callback);
        intersects2(index1: index1, index2: _right(index2), callback: callback);
      } else if (leaf2) {
        intersects2(index1: _left(index1), index2: index2, callback: callback);
        intersects2(index1: _right(index1), index2: index2, callback: callback);
      } else {
        intersects2(
            index1: _left(index1), index2: _left(index2), callback: callback);
        intersects2(
            index1: _left(index1), index2: _right(index2), callback: callback);
        intersects2(
            index1: _right(index1), index2: _left(index2), callback: callback);
        intersects2(
            index1: _right(index1), index2: _right(index2), callback: callback);
      }
    }

    void intersects({
      required int index,
      required void Function(int, int) callback,
    }) {
      if (BoundingBoxHierarchy.isLeaf(index, elementCount: elementCount1)) {
        // if it's a leaf node
        final elementIndex = BoundingBoxHierarchy.leafNodeIndexToElementIndex(
            index,
            elementCount: elementCount1,
            lastRowIndex: lastRowIndex1);
        callback(elementIndex, elementIndex);
        return;
      }

      final l = _left(index);
      final r = _right(index);
      intersects(index: l, callback: callback);
      intersects2(index1: l, index2: r, callback: callback);
      intersects(index: r, callback: callback);
    }

    if (identical(other, this)) {
      intersects(index: 0, callback: callback);
    } else {
      intersects2(index1: 0, index2: 0, callback: callback);
    }
  }
}
