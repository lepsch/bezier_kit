// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

typedef Tuple = ({int first, int second});

void main() {
  test("IntersectsVisitsEachOnce", () {
    // in this test each bounding box is identical and therefore
    // each bounding box overlaps. What we are testing here is that
    // the callback is invoked exactly once for each i <= j
    final box = BoundingBox(p1: Point(x: 1, y: 2), p2: Point(x: 4, y: 5));
    final bvh =
        BoundingBoxHierarchy(boxes: List<BoundingBox>.generate(5, (_) => box));
    final visitedSet = <Tuple>{};
    bvh.enumerateSelfIntersections((i, j) {
      final Tuple tuple = (first: i, second: j);
      expect(visitedSet.contains(tuple), isFalse,
          reason: "we already visited ($i, $j)!");
      visitedSet.add(tuple);
    });
    final expectedSet = () {
      var set = <Tuple>{};
      for (var i = 0; i <= 4; i++) {
        for (var j = i; j <= 4; j++) {
          set.add((first: i, second: j));
        }
      }
      return set;
    }();
    expect(visitedSet, expectedSet);
  });

  test("BoundingBoxForElement", () {
    final boxes = [
      BoundingBox(p1: Point(x: 1, y: 2), p2: Point(x: 3, y: 4)),
      BoundingBox(p1: Point(x: 5, y: 6), p2: Point(x: 7, y: 8)),
      BoundingBox(p1: Point(x: 9, y: 10), p2: Point(x: 11, y: 12)),
    ];
    final bvh = BoundingBoxHierarchy(boxes: boxes);
    expect(bvh.boundingBoxAt(0), boxes[0]);
    expect(bvh.boundingBoxAt(1), boxes[1]);
    expect(bvh.boundingBoxAt(2), boxes[2]);
  });

  test("LeafNodeToElementIndex", () {
    // check the simple case of a 1 element tree
    expect(
        BoundingBoxHierarchy.leafNodeIndexToElementIndex(0,
            elementCount: 1, lastRowIndex: 0),
        0);
    // check the case of a 3 element tree
    expect(
        BoundingBoxHierarchy.leafNodeIndexToElementIndex(3,
            elementCount: 3, lastRowIndex: 3),
        0);
    expect(
        BoundingBoxHierarchy.leafNodeIndexToElementIndex(4,
            elementCount: 3, lastRowIndex: 3),
        1);
    expect(
        BoundingBoxHierarchy.leafNodeIndexToElementIndex(2,
            elementCount: 3, lastRowIndex: 3),
        2);
  });

  test("ElementIndexToNodeIndex", () {
    // check the simple case of a 1 element tree
    expect(
        BoundingBoxHierarchy.elementIndexToNodeIndex(0,
            elementCount: 1, lastRowIndex: 0),
        0);
    // check the case of a 3 element tree
    expect(
        BoundingBoxHierarchy.elementIndexToNodeIndex(0,
            elementCount: 3, lastRowIndex: 3),
        3);
    expect(
        BoundingBoxHierarchy.elementIndexToNodeIndex(1,
            elementCount: 3, lastRowIndex: 3),
        4);
    expect(
        BoundingBoxHierarchy.elementIndexToNodeIndex(2,
            elementCount: 3, lastRowIndex: 3),
        2);
  });

  /// constructs a test hierarchy with a given number of leaf nodes, all using the same bounding box
  /// useful for testing that leaf node elementIndex and internal node startingElementIndex and endingElementIndex are correct
  BoundingBoxHierarchy constructTestHierarchy(
      {required int leafNodeCount, required BoundingBox repeatingBoundingBox}) {
    return BoundingBoxHierarchy(
        boxes: List<BoundingBox>.filled(leafNodeCount, repeatingBoundingBox));
  }

  List<BoundingBoxHierarchyNode> createListFromAllNodesVisited(
      {required BoundingBoxHierarchy in_}) {
    final result = <BoundingBoxHierarchyNode>[];
    in_.visit((node, _) {
      result.add(node);
      return true;
    });
    return result;
  }

  BoundingBoxHierarchyNode internalNode(
      {required int start, required int end, required BoundingBox box}) {
    return BoundingBoxHierarchyNode(
        boundingBox: box,
        type: BoundingBoxHierarchyNodeType.internal(
            startingElementIndex: start, endingElementIndex: end));
  }

  BoundingBoxHierarchyNode leafNode(
      {required int elementIndex, required BoundingBox box}) {
    return BoundingBoxHierarchyNode(
        boundingBox: box,
        type: BoundingBoxHierarchyNodeType.leaf(index: elementIndex));
  }

  test("RoundPowerOfTwo", () {
    expect(roundUpPowerOfTwo(0), 1);
    expect(roundUpPowerOfTwo(1), 1);
    expect(roundUpPowerOfTwo(2), 2);
    expect(roundUpPowerOfTwo(3), 4);
    expect(roundUpPowerOfTwo(63), 64);
    expect(roundUpPowerOfTwo(65), 128);
    expect(roundUpPowerOfTwo(128), 128);
  });

  /// test that when we visit a bounding volume hierarchy the leaf node elementIndex and internal node start and end element indexes are correct
  test("VisitElementIndexes", () {
    final sampleBox = BoundingBox.minMax(min: Point.zero, max: Point.zero);

    // simplest possible case (1 leaf node)
    final bvh1 = constructTestHierarchy(
        leafNodeCount: 1, repeatingBoundingBox: sampleBox);
    final result1 = createListFromAllNodesVisited(in_: bvh1);
    expect(result1, [leafNode(elementIndex: 0, box: sampleBox)]);

    // simplest case with internal node
    final bvh2 = constructTestHierarchy(
        leafNodeCount: 2, repeatingBoundingBox: sampleBox);
    final result2 = createListFromAllNodesVisited(in_: bvh2);
    expect(result2, [
      internalNode(start: 0, end: 1, box: sampleBox),
      leafNode(elementIndex: 0, box: sampleBox),
      leafNode(elementIndex: 1, box: sampleBox)
    ]);

    // a more complex case where leaf nodes exist on different levels of the tree
    final bvh3 = constructTestHierarchy(
        leafNodeCount: 5, repeatingBoundingBox: sampleBox);
    final result3 = createListFromAllNodesVisited(in_: bvh3);
    expect(result3, [
      internalNode(start: 0, end: 4, box: sampleBox),
      internalNode(start: 0, end: 2, box: sampleBox),
      internalNode(start: 0, end: 1, box: sampleBox),
      leafNode(elementIndex: 0, box: sampleBox),
      leafNode(elementIndex: 1, box: sampleBox),
      leafNode(elementIndex: 2, box: sampleBox),
      internalNode(start: 3, end: 4, box: sampleBox),
      leafNode(elementIndex: 3, box: sampleBox),
      leafNode(elementIndex: 4, box: sampleBox),
    ]);
  });
}
