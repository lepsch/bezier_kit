//
//  BezierPath.swift
//  BezierKit
//
//  Created by Holmes Futrell on 7/31/18.
//  Copyright © 2018 Holmes Futrell. All rights reserved.
//

import 'dart:math';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:bezier_kit/src/rectangle_extension.dart';

class MutablePath {
  static const kappa = 0.55228474979999997;

  final _components = <PathComponent>[];
  final _subpath = <Point>[];
  final _orders = <int>[];
  Point? _origin;

  List<PathComponent> get components => toPath().components;

  MutablePath({Rectangle? ellipseIn}) {
    if (ellipseIn != null) {
      addEllipse(rect: ellipseIn);
    }
  }

  void addLine({required Point to}) {
    if (_subpath.isEmpty) {
      if (_origin == null && _components.isNotEmpty) {
        _origin = _components.last.points.last;
      }
      if (_origin != to) _subpath.add(_origin!);
      _origin = null;
    }
    _subpath.add(to);
    _orders.add(1);
  }

  void addLines({required List<Point> between}) {
    if (between.isEmpty) return;
    move(to: between.first);
    for (final point in between.sublist(0, between.length - 1)) {
      addLine(to: point);
    }
    _subpath.add(between.last);
  }

  void addRect(Rectangle rect) {
    final points = [
      rect.origin,
      Point(x: rect.origin.x + rect.width, y: rect.origin.y),
      Point(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height),
      Point(x: rect.origin.x, y: rect.origin.y + rect.height),
      rect.origin,
    ];
    _subpath.addAll(points);
    _orders.addAll(List.filled(points.length - 1, 1));
    closeSubpath();
  }

  void addCurve({
    required Point to,
    required Point control1,
    required Point control2,
  }) {
    if (_subpath.isEmpty && _origin != null) {
      if (_origin != to) _subpath.add(_origin!);
      _origin = null;
    }
    _subpath.addAll([control1, control2, to]);
    _orders.add(3);
  }

  void addQuadCurve({required Point to, required Point control}) {
    if (_subpath.isEmpty && _origin != null) {
      if (_origin != to) _subpath.add(_origin!);
      _origin = null;
    }
    _subpath.addAll([control, to]);
    _orders.add(2);
  }

  void addEllipse({required Rectangle rect}) {
    final cx = rect.width / 2;
    final cy = rect.height / 2;
    final ox = cx * kappa; // control point offset horizontal
    final oy = cy * kappa; // control point offset vertical
    final xe = rect.origin.x + rect.width; // x-end
    final ye = rect.origin.y + rect.height; // y-end
    final xm = rect.origin.x + cx; // x-middle
    final ym = rect.origin.y + cy; // y-middle

    move(to: Point(x: xe, y: ym));
    _subpath.add(Point(x: xe, y: ym));
    addCurve(
      to: Point(x: xm, y: ye),
      control1: Point(x: xe, y: ym + oy),
      control2: Point(x: xm + ox, y: ye),
    );
    addCurve(
      to: Point(x: rect.origin.x, y: ym),
      control1: Point(x: xm - ox, y: ye),
      control2: Point(x: rect.origin.x, y: ym + oy),
    );
    addCurve(
      to: Point(x: xm, y: rect.origin.y),
      control1: Point(x: rect.origin.x, y: ym - oy),
      control2: Point(x: xm - ox, y: rect.origin.y),
    );
    addCurve(
      to: Point(x: xe, y: ym),
      control1: Point(x: xm + ox, y: rect.origin.y),
      control2: Point(x: xe, y: ym - oy),
    );
  }

  void addArc({
    required Point tangent1End,
    required Point tangent2End,
    required double radius,
  }) {
    final p0 = _subpath.last;
    final p1 = tangent1End;
    final p2 = tangent2End;
    final d = radius * kappa;
    final c1 = Point(
      x: p0.x + d * (p2.y - p1.y) / radius,
      y: p0.y + d * (p1.x - p2.x) / radius,
    );
    final c2 = Point(
      x: p2.x + d * (p1.y - p0.y) / radius,
      y: p2.y + d * (p0.x - p1.x) / radius,
    );
    _subpath.addAll([p0, c1, c2, p2]);
    _orders.addAll([1, 3]);
  }

  void move({required Point to}) {
    if (_subpath.isEmpty && _origin != null) {
      _origin = to;
      return;
    }
    _subpathToPathComponent();
    _origin = to;
  }

  void closeSubpath() {
    if (_subpath.isNotEmpty) {
      if (_subpath.first != _subpath.last) {
        _subpath.add(_subpath.first);
        _orders.add(1);
      }
    }
    _subpathToPathComponent();
  }

  void _subpathToPathComponent() {
    if (_subpath.isNotEmpty) {
      _components
          .add(PathComponent.raw(points: [..._subpath], orders: [..._orders]));
      _subpath.clear();
      _orders.clear();
    } else {
      if (_origin != null) {
        _subpath.add(_origin!);
        _orders.add(0);
        _origin = null;
        closeSubpath();
      }
    }
  }

  Path toPath() {
    final copy = MutablePath();
    copy._components.addAll(_components);
    copy._subpath.addAll(_subpath);
    copy._orders.addAll(_orders);
    copy._origin = _origin;
    copy._subpathToPathComponent();
    return Path(components: copy._components);
  }
}
