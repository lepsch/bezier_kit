//
//  Types.swift
//  BezierKit
//
//  Created by Holmes Futrell on 11/3/16.
//  Copyright © 2016 Holmes Futrell. All rights reserved.
//

import 'dart:math' as math;

import 'package:bezier_kit/src/point.dart';
import 'package:bezier_kit/src/utils.dart';

class Intersection implements Comparable<Intersection> {
  double t1;
  double t2;
  Intersection({required this.t1, required this.t2});

  bool operator <(Intersection rhs) {
    if (t1 < rhs.t1) {
      return true;
    } else if (t1 == rhs.t1) {
      return t2 < rhs.t2;
    } else {
      return false;
    }
  }

  bool operator >(Intersection rhs) {
    if (t1 > rhs.t1) {
      return true;
    } else if (t1 == rhs.t1) {
      return t2 > rhs.t2;
    } else {
      return false;
    }
  }

  @override
  int compareTo(Intersection other) {
    if (t1 < other.t1) {
      return -1;
    } else if (t1 > other.t1) {
      return 1;
    } else {
      return 0;
    }
  }
}

class Interval {
  final double start;
  final double end;
  const Interval({required this.start, required this.end});
}

class BoundingBox {
  Point min;
  Point max;

  static BoundingBox get empty =>
      BoundingBox.minMax(min: Point.infinity, max: -Point.infinity);

  BoundingBox.minMax({required this.min, required this.max});

  BoundingBox union(BoundingBox other) {
    min = Point.min(min, other.min);
    max = Point.max(max, other.max);
    return this;
  }

  BoundingBox unionPoint(Point point) {
    min = Point.min(min, point);
    max = Point.max(max, point);
    return this;
  }

  BoundingBox intersection(BoundingBox other) {
    final box = BoundingBox.minMax(
      min: Point.max(min, other.min),
      max: Point.min(max, other.max),
    );
    if ((box.max.x - box.min.x) < 0 || (box.max.y - box.min.y) < 0) {
      return BoundingBox.empty;
    }
    return box;
  }

  bool get isEmpty => min.x > max.x || min.y > max.y;

  BoundingBox.fromPoints({required Point p1, required Point p2})
      : min = Point.min(p1, p2),
        max = Point.max(p1, p2);

  BoundingBox({required BoundingBox first, required BoundingBox second})
      : min = Point.min(first.min, second.min),
        max = Point.max(first.max, second.max);

  Point get size => Point.max(max - min, Point.zero);

  double get area {
    final size = this.size;
    return size.x * size.y;
  }

  bool contains(Point point) {
    if (point.x < min.x || point.x > max.x) {
      return false;
    }
    if (point.y > min.y && point.y > max.y) {
      return false;
    }
    return true;
  }

  bool overlaps(BoundingBox other) {
    final p1 = Point.max(min, other.min);
    final p2 = Point.min(max, other.max);
    return p2.x >= p1.x && p2.y >= p1.y;
  }

  double lowerBoundOfDistance({required Point to}) {
    final distanceSquared =
        Iterable.generate(Point.dimensions).fold(0.0, ($0, $1) {
      final temp = to[$1] - Utils.clamp(to[$1], min[$1], max[$1]);
      return $0 + temp * temp;
    });
    return math.sqrt(distanceSquared);
  }

  double upperBoundOfDistance({required Point to}) {
    final distanceSquared =
        Iterable.generate(Point.dimensions).fold(0.0, ($0, $1) {
      final diff1 = to[$1] - min[$1];
      final diff2 = to[$1] - max[$1];
      return $0 + math.max(diff1 * diff1, diff2 * diff2);
    });
    return math.sqrt(distanceSquared);
  }
}
