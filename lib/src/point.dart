import 'dart:math';
import 'dart:typed_data';

import 'package:bezier_kit/src/affine_transform.dart';

class Point {
  double get x => _xy.first.x;
  set x(double value) => _xy.first = Float64x2(value, y);
  double get y => _xy.first.y;
  set y(double value) => _xy.first = Float64x2(x, value);

  final Float64x2List _xy;

  static final zero = Point(x: 0, y: 0);

  Point({required double x, required double y})
      : _xy = Float64x2List(1)..first = Float64x2(x, y);

  Point.fromData(Float64x2List xy) : _xy = xy;

  Point.fromFloat64x2(Float64x2 xy) : _xy = Float64x2List(1)..first = xy;

  double get magnitude => sqrt(lengthSquared);

  double get length => magnitude;

  double get lengthSquared => dot(this);

  Point normalize() {
    return this / length;
  }

  Point get perpendicular {
    return Point(x: -y, y: x);
  }

  double dot(Point other) {
    return x * other.x + y * other.y;
  }

  Point operator +(Point other) {
    return Point.fromFloat64x2(_xy.first + other._xy.first);
  }

  Point operator -(Point other) {
    return Point.fromFloat64x2(_xy.first - other._xy.first);
  }

  Point operator -() {
    return Point(x: -_xy.first.x, y: -_xy.first.y);
  }

  Point operator *(num factor) {
    return Point(x: x * factor, y: y * factor);
  }

  Point operator /(num factor) {
    return Point(x: x / factor, y: y / factor);
  }

  double operator [](int index) {
    if (index == 0) {
      return x;
    } else if (index == 1) {
      return y;
    } else {
      throw RangeError.index(index, this);
    }
  }

  void operator []=(int index, double value) {
    if (index == 0) {
      _xy.first = Float64x2(value, _xy.first.y);
    } else if (index == 1) {
      _xy.first = Float64x2(_xy.first.x, value);
    } else {
      throw RangeError.index(index, this);
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is Point) {
      return x == other.x && y == other.y;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(x, y);

  static Point min(Point p1, Point p2) {
    return Point(x: p1.x < p2.x ? p1.x : p2.x, y: p1.y < p2.y ? p1.y : p2.y);
  }

  static Point max(Point p1, Point p2) {
    return Point(x: p1.x > p2.x ? p1.x : p2.x, y: p1.y > p2.y ? p1.y : p2.y);
  }

  static final Point infinity = Point(x: double.infinity, y: double.infinity);

  static const dimensions = 2;

  double cross(Point other) {
    return x * other.y - y * other.x;
  }

  Point applying(AffineTransform t) {
    return Point(
      x: t.a * x + t.c * y + t.tx,
      y: t.b * x + t.d * y + t.ty,
    );
  }
}

typedef PointList = List<Point>;

double distance(Point p1, Point p2) {
  return (p1 - p2).length;
}

double distanceSquared(Point p1, Point p2) {
  return (p1 - p2).lengthSquared;
}
