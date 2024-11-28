// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'dart:math';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

void main() {
  test("Project", () {
    final line = PathComponent(
        curve: LineSegment(p0: Point(x: 1, y: 1), p1: Point(x: 2, y: 2)));
    final point1 = Point(x: 1, y: 2);
    final result1 = line.project(point1);
    expect(result1.point, Point(x: 1.5, y: 1.5));
    expect(result1.location.t, 0.5);
    expect(result1.location.elementIndex, 0);
    expect(line.pointIsWithinDistanceOfBoundary(point1, distance: 2), isTrue);
    expect(
        line.pointIsWithinDistanceOfBoundary(point1, distance: 0.5), isFalse);

    final rectangle = Path.fromRect(Rectangle(1, 2, 8, 4));
    final component = rectangle.components.first;
    final point2 = Point(x: 3, y: 5);
    final result2 = component.project(point2);
    expect(result2.point, Point(x: 3, y: 6));
    expect(result2.location.t, 0.75);
    expect(result2.location.elementIndex, 2);
    expect(component.pointIsWithinDistanceOfBoundary(point2, distance: 10),
        isTrue);
    expect(
        component.pointIsWithinDistanceOfBoundary(point2, distance: 2), isTrue);
    expect(component.pointIsWithinDistanceOfBoundary(point2, distance: 0.5),
        isFalse);
  });
}
