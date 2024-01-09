import 'dart:math';

import 'package:bezier_kit/src/affine_transform.dart';

class Point {
  double get x => _x;
  double get y => _y;

  final double _x;
  final double _y;

  static const zero = Point(x: 0, y: 0);

  const Point({required double x, required double y})
      : _x = x,
        _y = y;

  double get magnitude => sqrt(lengthSquared);

  double get length => magnitude;

  double get lengthSquared => dot(this);

  Point normalize() {
    return this / length;
  }

  Point get perpendicular {
    return Point(x: -_y, y: _x);
  }

  double dot(Point other) {
    return _x * other._x + _y * other._y;
  }

  Point operator +(Point other) {
    return Point(x: _x + other._x, y: _y + other._y);
  }

  Point operator -(Point other) {
    return Point(x: _x - other._x, y: _y - other._y);
  }

  Point operator -() {
    return Point(x: -_x, y: -_y);
  }

  Point operator *(num factor) {
    return Point(x: _x * factor, y: _y * factor);
  }

  Point operator /(num factor) {
    return Point(x: _x / factor, y: _y / factor);
  }

  double operator [](int index) {
    if (index == 0) {
      return _x;
    } else if (index == 1) {
      return _y;
    } else {
      throw RangeError.index(index, this);
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is Point) {
      return _x == other._x && _y == other._y;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(_x, _y);

  static Point min(Point p1, Point p2) {
    return Point(
        x: p1._x < p2._x ? p1._x : p2._x, y: p1._y < p2._y ? p1._y : p2._y);
  }

  static Point max(Point p1, Point p2) {
    return Point(
        x: p1._x > p2._x ? p1._x : p2._x, y: p1._y > p2._y ? p1._y : p2._y);
  }

  static const Point infinity = Point(x: double.infinity, y: double.infinity);

  static const dimensions = 2;

  double cross(Point other) {
    return _x * other._y - _y * other._x;
  }

  Point applying(AffineTransform t) {
    return Point(
      x: t.a * _x + t.c * _y + t.tx,
      y: t.b * _x + t.d * _y + t.ty,
    );
  }

  Point copyWith({double? x, double? y, (int index, double value)? at}) {
    if (at != null) {
      if (at.$1 == 0) {
        return Point(x: at.$2, y: _y);
      } else if (at.$1 == 1) {
        return Point(x: _x, y: at.$2);
      } else {
        throw RangeError.index(at.$1, this);
      }
    }
    return Point(x: x ?? _x, y: y ?? _y);
  }

  @override
  String toString() => "x: $_x, y: $_y";
}

typedef PointList = List<Point>;

double distance(Point p1, Point p2) {
  return (p1 - p2).length;
}

double distanceSquared(Point p1, Point p2) {
  return (p1 - p2).lengthSquared;
}
