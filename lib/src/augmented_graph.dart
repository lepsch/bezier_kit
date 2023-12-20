//
//  AugmentedGraph.swift
//  BezierKit
//
//  Created by Holmes Futrell on 8/28/18.
//  Copyright © 2018 Holmes Futrell. All rights reserved.
//

import 'package:bezier_kit/src/path.dart';
import 'package:bezier_kit/src/path_component.dart';
import 'package:bezier_kit/src/point.dart';
import 'package:collection/collection.dart';

enum BooleanPathOperation {
  union,
  subtract,
  intersect,
  removeCrossings,
}

class Node {
  IndexedPathLocation location;
  IndexedPathComponentLocation get componentLocation =>
      location.locationInComponent;

  Edge? forwardEdge;
  Edge? backwardEdge;
  final List<Node> neighbors = <Node>[];
  Path path;

  PathComponent get pathComponent => path.components[location.componentIndex];

  Node({required this.location, required this.path});

  bool neighborsContain(Node node) {
    return neighbors.firstWhereOrNull(($0) => $0 == node) != null;
  }

  void addNeighbor(Node node) {
    assert(neighborsContain(node) == false);
    neighbors.add(node);
  }

  void _replaceNeighbor(Node node, {required Node replacement}) {
    for (var i = neighbors.length; neighbors[i] == node; i++) {
      neighbors[i] = replacement;
    }
  }

  void mergeNeighbors({required Node of}) {
    for (var $0 in of.neighbors) {
      $0._replaceNeighbor(of, replacement: this);
      addNeighbor($0);
    }
  }

  /// Nodes can have strong reference cycles either through their neighbors or through their edges, unlinking all nodes when owner no longer holds instance prevents memory leakage
  void unlink() {
    neighbors.clear();
    forwardEdge = null;
    backwardEdge = null;
  }
}

class Edge {
  bool visited = false;
  bool inSolution = false;
  Node endingNode;
  Node startingNode;

  Edge({required this.startingNode, required this.endingNode});

  bool get needsVisiting => visited == false && inSolution == true;

  PathComponent get component {
    final parentComponent = endingNode.pathComponent;
    var nextLocation = endingNode.componentLocation;
    if (nextLocation == parentComponent.startingIndexedLocation) {
      nextLocation = parentComponent.endingIndexedLocation;
    }
    return endingNode.pathComponent
        .split(from: startingNode.componentLocation, to: nextLocation);
  }

  void visitCoincidentEdges() {
    final location = IndexedPathComponentLocation(elementIndex: 0, t: 0.5);
    final point = component.point(at: location);
    final normal = component.normal(at: location);
    final smallDistance = AugmentedGraph._smallDistance;
    final point1 = point + normal * smallDistance;
    final point2 = point - normal * smallDistance;

    bool edgeIsCoincident(Edge edge) {
      final rule = PathFillRule.evenOdd;
      final component = edge.startingNode.pathComponent;
      return component.contains(point1, using: rule) !=
          component.contains(point2, using: rule);
    }

    bool tValueIsIntervalEnd(double t) {
      return t == 0 || t == 1;
    }

    for (final edge
        in startingNode.neighbors.map(($0) => $0.forwardEdge).nonNulls) {
      if (edge.visited) continue;
      if (!tValueIsIntervalEnd(startingNode.location.t) &&
          !tValueIsIntervalEnd(edge.startingNode.location.t)) {
        continue;
      }
      if (!tValueIsIntervalEnd(endingNode.location.t) &&
          !tValueIsIntervalEnd(edge.endingNode.location.t)) {
        continue;
      }
      if (edge.endingNode.neighborsContain(endingNode) &&
          edgeIsCoincident(edge)) {
        edge.visited = true;
      }
    }
    for (final edge
        in startingNode.neighbors.map(($0) => $0.backwardEdge).nonNulls) {
      if (edge.visited) continue;
      if (!tValueIsIntervalEnd(endingNode.location.t) &&
          !tValueIsIntervalEnd(edge.startingNode.location.t)) {
        continue;
      }
      if (!tValueIsIntervalEnd(startingNode.location.t) &&
          !tValueIsIntervalEnd(edge.endingNode.location.t)) {
        continue;
      }
      if (edge.startingNode.neighborsContain(endingNode) &&
          edgeIsCoincident(edge)) {
        edge.visited = true;
      }
    }
  }
}

class PathComponentGraph {
  final List<Node> _nodes;

  PathComponentGraph._(this._nodes);

  factory PathComponentGraph(
      {required Path path,
      required int componentIndex,
      required List<Node> using}) {
    var nodes = using;
    final component = path.components[componentIndex];
    final startingLocation = IndexedPathLocation.fromComponent(
        componentIndex: componentIndex,
        locationInComponent: component.startingIndexedLocation);
    final endingLocation = IndexedPathLocation.fromComponent(
        componentIndex: componentIndex,
        locationInComponent: component.endingIndexedLocation);
    if (nodes.firstOrNull?.location != startingLocation) {
      nodes.insert(0, Node(location: startingLocation, path: path));
    }
    if (nodes.lastOrNull?.location != endingLocation) {
      nodes.add(Node(location: endingLocation, path: path));
    }
    for (var i = 1; i < nodes.length; i++) {
      final startingNode = nodes[i - 1];
      final endingNode = nodes[i];
      final edge = Edge(startingNode: startingNode, endingNode: endingNode);
      endingNode.backwardEdge = edge;
      startingNode.forwardEdge = edge;
    }
    // loop back the end to the start (if needed)
    if (component.isClosed) {
      final last = nodes.lastOrNull;
      final first = nodes.firstOrNull;
      if (first != null && last != null) {
        final secondToLast = last.backwardEdge?.startingNode;
        if (secondToLast != null) {
          final edge = Edge(startingNode: secondToLast, endingNode: first);
          secondToLast.forwardEdge = edge;
          first.backwardEdge = edge;
        }
        first.mergeNeighbors(of: last);
        last.unlink();
        nodes.removeLast();
      }
    }
    return PathComponentGraph._(nodes);
  }

  void forEachNode(void Function(Node node) callback) {
    _nodes.forEach(callback);
  }

  void deinit() {
    forEachNode(($0) => $0.unlink());
  }
}

class PathGraph {
  final Path path;
  final List<PathComponentGraph> components;

  PathGraph._({required this.path, required this.components});

  factory PathGraph({required Path path, required List<Node> using}) {
    final intersectionsByComponent = () {
      var temp = List<List<Node>>.generate(path.components.length, (_) => []);
      for (var $0 in using) {
        temp[$0.location.componentIndex].add($0);
      }
      return temp;
    }();
    final components = Iterable.generate(path.components.length)
        .map(($0) => PathComponentGraph(
            path: path,
            componentIndex: $0,
            using: intersectionsByComponent[$0]))
        .toList();
    return PathGraph._(path: path, components: components);
  }
}

class AugmentedGraph {
  /*private*/ final BooleanPathOperation operation;
  /*private*/ final PathGraph graph1;
  /*private*/ final PathGraph graph2;

  AugmentedGraph._({
    required this.operation,
    required this.graph1,
    required this.graph2,
  });

  factory AugmentedGraph({
    required Path path1,
    required Path path2,
    required List<PathIntersection> intersections,
    required BooleanPathOperation operation,
  }) {
    // take the pairwise intersections and make two mutually linked lists of intersections, one for each path
    final path1Intersections = <Node>[];
    final path2Intersections = <Node>[];
    for (var $0 in intersections) {
      final node1 = Node(location: $0.indexedPathLocation1, path: path1);
      final node2 = Node(location: $0.indexedPathLocation2, path: path2);
      node1.addNeighbor(node2);
      node2.addNeighbor(node1);
      path1Intersections.add(node1);
      if (operation != BooleanPathOperation.removeCrossings) {
        path2Intersections.add(node2);
      } else {
        path1Intersections.add(node2);
      }
    }

    AugmentedGraph._sortAndMergeDuplicates(of: path1Intersections);
    if (operation != BooleanPathOperation.removeCrossings) {
      AugmentedGraph._sortAndMergeDuplicates(of: path2Intersections);
    }
    // create graph representations of the two paths
    final graph1 = PathGraph(path: path1, using: path1Intersections);
    final graph2 = (operation != BooleanPathOperation.removeCrossings)
        ? PathGraph(path: path2, using: path2Intersections)
        : graph1;

    final augmentedGraph =
        AugmentedGraph._(operation: operation, graph1: graph1, graph2: graph2);

    // mark each edge as either included or excluded from the final result
    augmentedGraph._classifyEdges(graph: graph1, isForFirstPath: true);
    if (operation != BooleanPathOperation.removeCrossings) {
      augmentedGraph._classifyEdges(graph: graph2, isForFirstPath: false);
    }

    return augmentedGraph;
  }
  Path performOperation() {
    void performOperation(
        {required PathGraph graph,
        required List<PathComponent> appendingToComponents}) {
      for (var $0 in graph.components) {
        $0.forEachNode((node) {
          final path = _findUnvisitedPath(node: node, goal: node);
          if (path == null || path.isEmpty) return;
          appendingToComponents.add(_createComponent(using: path));
        });
      }
    }

    final components = <PathComponent>[];
    performOperation(graph: graph1, appendingToComponents: components);
    if (operation != BooleanPathOperation.removeCrossings) {
      performOperation(graph: graph2, appendingToComponents: components);
    }
    return Path(components: components);
  }

  static double get _smallDistance => 8 > 4 ? 1.0e-6 : 1.0e-4;

  void _classifyEdges(
      {required PathGraph graph, required bool isForFirstPath}) {
    void classifyEdge(Edge edge) {
      // TODO: we use a crummy point location
      final component = edge.component;
      final location = IndexedPathComponentLocation(elementIndex: 0, t: 0.5);
      final point = component.point(at: location);
      final normal = component.normal(at: location);
      final smallDistance = AugmentedGraph._smallDistance;
      final point1 = point + normal * smallDistance;
      final point2 = point - normal * smallDistance;
      final included1 =
          _pointIsContainedInBooleanResult(point: point1, operation: operation);
      final included2 =
          _pointIsContainedInBooleanResult(point: point2, operation: operation);
      edge.inSolution = (included1 != included2);
    }

    void classifyComponentEdges({required PathComponentGraph component}) {
      component.forEachNode(($0) {
        final edge = $0.forwardEdge;
        if (edge != null) {
          classifyEdge(edge);
        }
      });
    }

    for (var $0 in graph.components) {
      classifyComponentEdges(component: $0);
    }
  }

  bool _pointIsContainedInBooleanResult(
      {required Point point, required BooleanPathOperation operation}) {
    final rule = (operation == BooleanPathOperation.removeCrossings)
        ? PathFillRule.winding
        : PathFillRule.evenOdd;
    final contained1 = graph1.path.contains(point, using: rule);
    final contained2 = operation != BooleanPathOperation.removeCrossings
        ? graph2.path.contains(point, using: rule)
        : contained1;
    switch (operation) {
      case BooleanPathOperation.union:
        return contained1 || contained2;
      case BooleanPathOperation.intersect:
        return contained1 && contained2;
      case BooleanPathOperation.subtract:
        return contained1 && !contained2;
      case BooleanPathOperation.removeCrossings:
        return contained1;
    }
  }

  static _sortAndMergeDuplicates({required List<Node> of}) {
    if (of.length <= 1) return;
    of.sort(($0, $1) =>
        $0.location < $1.location ? -1 : ($0.location > $1.location ? 1 : 0));
    var currentUniqueIndex = 0;
    for (var i = 1; i < of.length; i++) {
      final node = of[i];
      if (node.location == of[currentUniqueIndex].location) {
        of[currentUniqueIndex].mergeNeighbors(of: node);
      } else {
        currentUniqueIndex += 1;
        of[currentUniqueIndex] = node;
      }
    }
    final nodes = of.sublist(0, currentUniqueIndex + 1);
    of
      ..clear()
      ..addAll(nodes);
  }

  List<(Edge, bool)>? _findUnvisitedPath(
      {required /*from*/ Node node, required /*to*/ Node goal}) {
    List<(Edge, bool)>? pathUsingEdge(Edge? edge,
        {required /*from*/ Node node, required bool forwards}) {
      if (edge == null || edge.needsVisiting) return null;
      edge.visited = true;
      edge.visitCoincidentEdges();
      final nextNode = forwards ? edge.endingNode : edge.startingNode;
      final path = _findUnvisitedPath(node: nextNode, goal: goal);
      if (path != null) {
        return [(edge, forwards)] + path;
      }

      return null;
    }

    // we prefer to keep the direction of the path the same which is why
    // we try all the possible forward edges before any back edges
    var result = pathUsingEdge(node.forwardEdge, node: node, forwards: true);
    if (result != null) return result;
    for (final neighbor in node.neighbors) {
      result =
          pathUsingEdge(neighbor.forwardEdge, node: neighbor, forwards: true);
      if (result != null) return result;
    }
    result = pathUsingEdge(node.backwardEdge, node: node, forwards: false);
    if (result != null) return result;
    for (final neighbor in node.neighbors) {
      result =
          pathUsingEdge(neighbor.backwardEdge, node: neighbor, forwards: false);
      if (result != null) return result;
    }
    if (node == goal || node.neighborsContain(goal)) return [];
    return null;
  }

  PathComponent _createComponent({required List<(Edge, bool)> using}) {
    var points = <Point>[];
    var orders = <int>[];
    void appendComponent(PathComponent component) {
      if (points.isEmpty) {
        points.add(component.startingPoint);
      }
      points += component.points.sublist(1);
      orders += component.orders;
    }

    for (final (edge, forwards) in using) {
      final component = edge.component;
      appendComponent(forwards ? component : component.reversed());
    }
    points[points.length - 1] = points[0];
    return PathComponent(points: points, orders: orders);
  }
}
