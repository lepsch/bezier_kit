// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'dart:math';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

void main() {
  const pointNan = Point(x: double.nan, y: double.nan);
  final zeroBox = BoundingBox(p1: Point.zero, p2: Point.zero);
  final infiniteBox = BoundingBox(p1: -Point.infinity, p2: Point.infinity);
  final sampleBox =
      BoundingBox(p1: Point(x: -1.0, y: -2.0), p2: Point(x: 3.0, y: -1.0));

  test("Empty", () {
    final nanBox = BoundingBox(p1: pointNan, p2: pointNan);
    final e = BoundingBox.empty;
    expect(e.size, Point.zero);
    expect(e == BoundingBox.empty, isTrue);

    expect(e.overlaps(e), isFalse);
    expect(e.overlaps(zeroBox), isFalse);
    expect(e.overlaps(sampleBox), isFalse);
    expect(e.overlaps(infiniteBox), isFalse);
    expect(e.overlaps(nanBox), isFalse);

    expect(infiniteBox.isEmpty, isFalse);
    expect(zeroBox.isEmpty, isFalse);
    expect(sampleBox.isEmpty, isFalse);
    expect(BoundingBox.empty.isEmpty, isTrue);
    expect(
        BoundingBox.minMax(min: Point(x: 5, y: 3), max: Point(x: 4, y: 4))
            .isEmpty,
        isTrue);
  });

  test("LowerAndUpperBounds", () {
    final box =
        BoundingBox(p1: Point(x: 2.0, y: 3.0), p2: Point(x: 3.0, y: 5.0));

    final p1 = Point(x: 2.0, y: 4.0);
    final p2 = Point(x: 2.5, y: 3.5);
    final p3 = Point(x: 1.0, y: 4.0);
    final p4 = Point(x: 3.0, y: 7.0);
    final p5 = Point(x: -1.0, y: -1.0);

    // on the boundary
    expect(box.lowerBoundOfDistance(to: p1), 0.0);
    // fully inside
    expect(box.lowerBoundOfDistance(to: p2), 0.0);
    // outside (straight horizontally)
    expect(box.lowerBoundOfDistance(to: p3), 1.0);
    // outside (straight vertically)
    expect(box.lowerBoundOfDistance(to: p4), 2.0);
    // outside (nearest bottom left corner)
    expect(box.lowerBoundOfDistance(to: p5), 5.0);

    expect(box.upperBoundOfDistance(to: p1), sqrt(2.0));
    expect(box.upperBoundOfDistance(to: p2), sqrt(2.5));
    expect(box.upperBoundOfDistance(to: p3), sqrt(5));
    expect(box.upperBoundOfDistance(to: p4), sqrt(17.0));
    expect(box.upperBoundOfDistance(to: p5), sqrt(52.0));
  });

  test("Area", () {
    final box =
        BoundingBox(p1: Point(x: 2.0, y: 3.0), p2: Point(x: 3.0, y: 5.0));
    expect(box.area, 2.0);
    final emptyBox = BoundingBox.empty;
    expect(emptyBox.area, 0.0);
  });

  test("Overlaps", () {
    final box1 =
        BoundingBox(p1: Point(x: 2.0, y: 3.0), p2: Point(x: 3.0, y: 5.0));
    final box2 =
        BoundingBox(p1: Point(x: 2.5, y: 6.0), p2: Point(x: 3.0, y: 8.0));
    final box3 =
        BoundingBox(p1: Point(x: 2.5, y: 4.0), p2: Point(x: 3.0, y: 8.0));
    expect(box1.overlaps(box2), isFalse);
    expect(box1.overlaps(box3), isTrue);
    expect(box1.overlaps(BoundingBox.empty), isFalse);
  });

  test("UnionBoxEmpty1", () {
    var empty1 = BoundingBox.empty;
    final empty2 = BoundingBox.empty;
    expect(empty1.union(empty2), BoundingBox.empty);
  });

  test("UnionBoxEmpty2", () {
    var empty = BoundingBox.empty;
    final box =
        BoundingBox(p1: Point(x: 2.0, y: 3.0), p2: Point(x: 3.0, y: 5.0));
    expect(empty.union(box), box);
  });

  test("UnionBox", () {
    var box1 =
        BoundingBox(p1: Point(x: 2.0, y: 3.0), p2: Point(x: 3.0, y: 5.0));
    final box2 =
        BoundingBox(p1: Point(x: 2.5, y: 6.0), p2: Point(x: 3.0, y: 8.0));
    expect(box1.union(box2),
        BoundingBox(p1: Point(x: 2.0, y: 3.0), p2: Point(x: 3.0, y: 8.0)));
  });

  test("UnionPointEmpty", () {
    var empty = BoundingBox.empty;
    final point = Point(x: 3, y: 4);
    expect(empty.unionPoint(point), BoundingBox(p1: point, p2: point));
  });

  test("UnionPoint", () {
    final box1 = BoundingBox(p1: Point(x: -1, y: -1), p2: Point(x: 3, y: 5));
    var box2 = box1;
    expect(box2.unionPoint(Point(x: 0, y: -1)), box1);
    expect(box2.unionPoint(Point(x: -2, y: 0)),
        BoundingBox(p1: Point(x: -2, y: -1), p2: Point(x: 3, y: 5)));
    expect(box2.unionPoint(Point(x: 1, y: 7)),
        BoundingBox(p1: Point(x: -2, y: -1), p2: Point(x: 3, y: 7)));
  });

  // test("Rectangle", () {
  //     // test a standard box
  //     final box1 = BoundingBox(p1: Point(x: 2.0, y: 3.0), p2: Point(x: 3.0, y: 5.0));
  //     expect(box1.rect, Rectangle(origin: Point(x: 2.0, y: 3.0), size: CGSize(width: 1.0, height: 2.0)));
  //     // test the empty box
  //     expect(BoundingBox.empty.cgRect, Rectangle.null);
  // });

  test("InitFirstSecond", () {
    final box1 =
        BoundingBox(p1: Point(x: 2.0, y: 3.0), p2: Point(x: 3.0, y: 5.0));
    final box2 =
        BoundingBox(p1: Point(x: 1.0, y: 1.0), p2: Point(x: 2.0, y: 2.0));
    final result = BoundingBox.fromBox(first: box1, second: box2);
    expect(result,
        BoundingBox(p1: Point(x: 1.0, y: 1.0), p2: Point(x: 3.0, y: 5.0)));
  });

  test("Intersection", () {
    final box1 = BoundingBox(p1: Point(x: 0, y: 0), p2: Point(x: 3, y: 2));
    final box2 = BoundingBox(
        p1: Point(x: 2, y: 1), p2: Point(x: 4, y: 5)); // overlaps box1
    final box3 = BoundingBox(
        p1: Point(x: 2, y: 4), p2: Point(x: 4, y: 5)); // does not overlap box1
    final box4 = BoundingBox(
        p1: Point(x: 3, y: 0),
        p2: Point(x: 5, y: 2)); // overlaps box1 exactly on x edge
    final box5 = BoundingBox(
        p1: Point(x: 0, y: 2),
        p2: Point(x: 3, y: 4)); // overlaps box1 exactly on y edge
    final box6 = BoundingBox(
        p1: Point(x: 0, y: 0),
        p2: Point(x: -5, y: -5)); // overlaps box1 only at (0,0)
    final expectedBox =
        BoundingBox(p1: Point(x: 2, y: 1), p2: Point(x: 3, y: 2));
    expect(box1.intersection(box2), expectedBox);
    expect(box2.intersection(box1), expectedBox);
    expect(box1.intersection(box3), BoundingBox.empty);
    expect(box1.intersection(BoundingBox.empty), BoundingBox.empty);
    expect(BoundingBox.empty.intersection(box1), BoundingBox.empty);
    expect(
        BoundingBox.empty.intersection(BoundingBox.empty), BoundingBox.empty);
    expect(box1.intersection(box4),
        BoundingBox(p1: Point(x: 3, y: 0), p2: Point(x: 3, y: 2)));
    expect(box1.intersection(box5),
        BoundingBox(p1: Point(x: 0, y: 2), p2: Point(x: 3, y: 2)));
    expect(
        box1.intersection(box6), BoundingBox(p1: Point.zero, p2: Point.zero));
  });
}
