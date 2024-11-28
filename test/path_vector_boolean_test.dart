// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'dart:math';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

extension on Path {
  /// copies the path in such a way that it's impossible that optimizations would allow the copy to share the same underlying storage
  Path independentCopy() {
    return copy(using: AffineTransform.translation(translationX: 1, y: 0))
        .copy(using: AffineTransform.translation(translationX: -1, y: 0));
  }
}

void main() {
  // points on the first square
  final p0 = Point(x: 0.0, y: 0.0);
  final p1 = Point(x: 1.0, y: 0.0); // intersection 1
  final p2 = Point(x: 2.0, y: 0.0);
  final p3 = Point(x: 2.0, y: 1.0); // intersection 2
  final p4 = Point(x: 2.0, y: 2.0);
  final p5 = Point(x: 0.0, y: 2.0);

  // points on the second square
  final p6 = Point(x: 1.0, y: -1.0);
  final p7 = Point(x: 3.0, y: -1.0);
  final p8 = Point(x: 3.0, y: 1.0);
  final p9 = Point(x: 1.0, y: 1.0);

  Path createSquare1() {
    return Path(components: [
      PathComponent(curves: [
        LineSegment(p0: p0, p1: p2),
        LineSegment(p0: p2, p1: p4),
        LineSegment(p0: p4, p1: p5),
        LineSegment(p0: p5, p1: p0),
      ])
    ]);
  }

  Path createSquare2() {
    return Path(components: [
      PathComponent(curves: [
        LineSegment(p0: p6, p1: p7),
        LineSegment(p0: p7, p1: p8),
        LineSegment(p0: p8, p1: p9),
        LineSegment(p0: p9, p1: p6),
      ])
    ]);
  }

  bool componentsEqualAsideFromElementOrdering(
      PathComponent component1, PathComponent component2) {
    final curves1 = component1.curves;
    final curves2 = component2.curves;
    if (curves1.length != curves2.length) return false;
    if (curves1.isEmpty) return true;

    final offset = curves2.indexWhere(($0) => $0 == curves1.first);
    if (offset == -1) return false;

    final count = curves1.length;
    for (var i = 0; i < count; i++) {
      if (curves1[i] != curves2[(i + offset) % count]) {
        return false;
      }
    }
    return true;
  }

  test("Subtracting", () {
    final expectedResult = Path(components: [
      PathComponent(curves: [
        LineSegment(p0: p1, p1: p9),
        LineSegment(p0: p9, p1: p3),
        LineSegment(p0: p3, p1: p4),
        LineSegment(p0: p4, p1: p5),
        LineSegment(p0: p5, p1: p0),
        LineSegment(p0: p0, p1: p1),
      ])
    ]);
    final square1 = createSquare1();
    final square2 = createSquare2();
    final subtracted = square1.subtract(square2);
    expect(subtracted.components.length, 1);
    expect(
        componentsEqualAsideFromElementOrdering(
            subtracted.components[0], expectedResult.components[0]),
        isTrue);
  });

  test("SubtractingWinding", () {
    // subtracting should use .evenOdd fill, if it doesn't this test can *add* an inner square instead of doing nothing
    final path = Path()
      ..addRect(Rectangle(0, 0, 5, 5))
      ..addRect(Rectangle(1, 1, 3, 3));

    final subtractionPath = Path()..addRect(Rectangle(2, 2, 1, 1));
    // subtractionPath exists in the path's hole, path doesn't contain it
    expect(path.containsPath(subtractionPath, using: PathFillRule.evenOdd),
        isFalse);
    // but it *does* contain it using .winding rule
    expect(path.containsPath(subtractionPath, using: PathFillRule.winding),
        isTrue);
    // since `subtract` uses .evenOdd rule it does nothing
    final result = path.subtract(subtractionPath);
    expect(result, path);
  });

  test("Union", () {
    final expectedResult = Path(components: [
      PathComponent(curves: [
        LineSegment(p0: p0, p1: p1),
        LineSegment(p0: p1, p1: p6),
        LineSegment(p0: p6, p1: p7),
        LineSegment(p0: p7, p1: p8),
        LineSegment(p0: p8, p1: p3),
        LineSegment(p0: p3, p1: p4),
        LineSegment(p0: p4, p1: p5),
        LineSegment(p0: p5, p1: p0),
      ])
    ]);
    final square1 = createSquare1();
    final square2 = createSquare2();
    final unioned = square1.union(square2);
    expect(unioned.components.length, 1);
    expect(
        componentsEqualAsideFromElementOrdering(
            unioned.components[0], expectedResult.components[0]),
        isTrue);
  });

  test("UnionSelf", () {
    final square = createSquare1();
    final copy = square.independentCopy();
    expect(square.union(square), square);
    expect(square.union(copy), square);
  });

  test("UnionCoincidentEdges1", () {
    // a simple test of union'ing two squares where the max/min x edge are coincident
    final square1 = Path.fromRect(Rectangle(0, 0, 1, 1));
    final square2 = Path.fromRect(Rectangle(1, 0, 1, 1));
    final expectedUnion = Path(components: [
      PathComponent.raw(points: [
        Point(x: 0.0, y: 0.0),
        Point(x: 1.0, y: 0.0),
        Point(x: 2.0, y: 0.0),
        Point(x: 2.0, y: 1.0),
        Point(x: 1.0, y: 1.0),
        Point(x: 0.0, y: 1.0),
        Point(x: 0.0, y: 0.0),
      ], orders: List.filled(6, 1))
    ]);

    final resultUnion1 = square1.union(square2);
    expect(resultUnion1.components.length, 1);
    expect(
        componentsEqualAsideFromElementOrdering(
            resultUnion1.components[0], expectedUnion.components[0]),
        isTrue);
    // check that it also works if the path is reversed
    final resultUnion2 = square1.union(square2.reversed());
    expect(resultUnion2.components.length, 1);
    expect(
        componentsEqualAsideFromElementOrdering(
            resultUnion2.components[0], expectedUnion.components[0]),
        isTrue);
  });

  test("UnionCoincidentEdges2", () {
    // square 2 falls inside square 1 except its maximum x edge which is coincident
    final square1 = Path.fromRect(Rectangle(0, 0, 3, 3));
    final square2 = Path.fromRect(Rectangle(2, 1, 1, 1));
    final expectedUnion = Path(components: [
      PathComponent.raw(points: [
        Point(x: 0.0, y: 0.0),
        Point(x: 3.0, y: 0.0),
        Point(x: 3.0, y: 1.0),
        Point(x: 3.0, y: 2.0),
        Point(x: 3.0, y: 3.0),
        Point(x: 0.0, y: 3.0),
        Point(x: 0.0, y: 0.0),
      ], orders: List.filled(6, 1))
    ]);
    final result1 = square1.union(square2);
    final result2 = square2.union(square1);
    expect(result1.components.length, 1);
    expect(result2.components.length, 1);
    expect(
        componentsEqualAsideFromElementOrdering(
            result1.components[0], expectedUnion.components[0]),
        isTrue);
    expect(
        componentsEqualAsideFromElementOrdering(
            result2.components[0], expectedUnion.components[0]),
        isTrue);
  });

  test("UnionCoincidentEdges3", () {
    // square 2 and 3 have a partially overlapping edge
    final square1 = Path.fromRect(Rectangle(0, 0, 3, 3));
    final square2 = Path.fromRect(Rectangle(1, 2, 2, 2));
    final expectedUnion = Path(components: [
      PathComponent.raw(points: [
        Point(x: 0.0, y: 0.0),
        Point(x: 3.0, y: 0.0),
        Point(x: 3.0, y: 2.0),
        Point(x: 3.0, y: 3.0),
        Point(x: 3.0, y: 4.0),
        Point(x: 1.0, y: 4.0),
        Point(x: 1.0, y: 3.0),
        Point(x: 0.0, y: 3.0),
        Point(x: 0.0, y: 0.0),
      ], orders: List.filled(8, 1))
    ]);

    final result1 = square1.union(square2);
    final result2 = square1.union(square2.reversed());
    expect(result1.components.length, 1);
    expect(result2.components.length, 1);
    expect(
        componentsEqualAsideFromElementOrdering(
            result1.components[0], expectedUnion.components[0]),
        isTrue);
    expect(
        componentsEqualAsideFromElementOrdering(
            result2.components[0], expectedUnion.components[0]),
        isTrue);
  });

  test("UnionCoincidentEdgesRealWorldTestCase1", () {
    final polygon1 = Path(components: [
      PathComponent.raw(points: [
        Point(x: 111.2, y: 90.0),
        Point(x: 144.72135954999578, y: 137.02282018339787),
        Point(x: 179.15338649848962, y: 123.08999319271176),
        Point(x: 171.33627533401454, y: 102.89462632327792),
        Point(x: 111.2, y: 90.0),
      ], orders: [
        1,
        1,
        1,
        1
      ])
    ]);
    final polygon2 = Path(components: [
      PathComponent.raw(points: [
        Point(x: 144.72135954999578, y: 137.02282018339787),
        Point(x: 89.64133022449836, y: 119.6729633084088),
        Point(x: 160.7501485041311, y: 111.6759272531885),
        Point(x: 179.15338649848962, y: 123.08999319271176),
        Point(x: 144.72135954999578, y: 137.02282018339787),
      ], orders: [
        1,
        1,
        1,
        1
      ])
    ]);

    // polygon 1 & 2 share two points in common
    // polygon 1's [1] point is polygon 2's [0] point
    // polygon 1's [2] point is polygon 2's [3] point
    final unionResult1 = polygon1.union(polygon2);
    expect(unionResult1.components.length, 1);
    expect(unionResult1.components.first.points.length, 7);

    final unionResult2 = polygon1.union(polygon2.reversed());
    expect(unionResult2.components.length, 1);
    expect(unionResult2.components.first.points.length, 7);
  });

  test("UnionCoincidentEdgesRealWorldTestCase2", () {
    final star = Path(components: [
      PathComponent.raw(points: [
        Point(x: 111.2, y: 90.0),
        Point(x: 144.72135954999578, y: 137.02282018339787),
        Point(x: 89.64133022449836, y: 119.6729633084088),
        Point(x: 55.27864045000421, y: 166.0845213036123),
        Point(x: 54.758669775501644, y: 108.33889987152517),
        Point(x: 0.0, y: 90.00000000000001),
        Point(x: 54.75866977550164, y: 71.66110012847484),
        Point(x: 55.2786404500042, y: 13.915478696387723),
        Point(x: 89.64133022449835, y: 60.3270366915912),
        Point(x: 144.72135954999578, y: 42.97717981660214),
        Point(x: 111.2, y: 90.0),
      ], orders: List.filled(10, 1))
    ]);

    final polygon = Path(components: [
      PathComponent.raw(points: [
        Point(x: 89.64133022449836, y: 119.6729633084088),
        // this is marked as an exit if the polygon isn't reversed and it's correct BUT it's unlinked to the other path(!!!)
        Point(x: 55.27864045000421, y: 166.0845213036123),
        Point(x: 143.9588334407257, y: 125.35115333505796),
        Point(x: 160.7501485041311, y: 111.6759272531885),
        Point(x: 89.64133022449836, y: 119.6729633084088),
      ], orders: [
        1,
        1,
        1,
        1
      ])
    ]);

    // ugh, yeah see reversing the polygon causes the correct vertext to be recognized as an exit;
    final unionResult1 = star.union(polygon);
    expect(unionResult1.components.length, 1);

    final unionResult2 = star.union(polygon.reversed());
    expect(unionResult2.components.length, 1);
  });

  test("UnionRealWorldEdgeCase", () {
    final a = Path(components: [
      PathComponent.raw(points: [
        Point(x: 310.198127403852, y: 190.08736919846973),
        Point(x: 310.390629965343, y: 191.78584973769978),
        Point(x: 310.0800866088565, y: 193.5583513843498),
        Point(x: 309.1982933716744, y: 195.17240727745877),
        Point(x: 306.9208206199371, y: 199.34114906559483),
        Point(x: 301.6951312337138, y: 200.87432554752368),
        Point(x: 297.52638944557776, y: 198.59685279578636),
        Point(x: 294.8541298755864, y: 197.13694026929096),
        Point(x: 293.26485189217163, y: 194.46557442730858),
        Point(x: 293.06807628308206, y: 191.637728075906),
        Point(x: 293.05884562618036, y: 191.50820426365925),
        Point(x: 293.0524676850055, y: 191.37785711483136),
        Point(x: 293.0490061981148, y: 191.24674708897507),
        Point(x: 292.9236355289621, y: 186.49810808117778),
        Point(x: 296.67153503455194, y: 182.546942559205),
        Point(x: 301.42017404234923, y: 182.42157189005232),
        Point(x: 305.9310607601042, y: 182.30247821176928),
        Point(x: 309.72232986751203, y: 185.6785144367646),
        Point(x: 310.198127403852, y: 190.08736919846973),
      ], orders: List.filled(6, 3))
    ]);
    final b = Path(components: [
      PathComponent.raw(points: [
        Point(x: 309.5688043100249, y: 187.66446326122298),
        Point(x: 311.37643918302956, y: 192.05738329201742),
        Point(x: 309.28065147291585, y: 197.0839261954614),
        Point(x: 304.8877314421214, y: 198.89156106846605),
        Point(x: 300.4948114113269, y: 200.6991959414707),
        Point(x: 295.46826850788295, y: 198.60340823135695),
        Point(x: 293.6606336348783, y: 194.21048820056248),
        Point(x: 291.85299876187366, y: 189.81756816976807),
        Point(x: 293.9487864719874, y: 184.79102526632408),
        Point(x: 298.3417065027818, y: 182.98339039331944),
        Point(x: 302.7346265335763, y: 181.1757555203148),
        Point(x: 307.76116943702027, y: 183.2715432304285),
        Point(x: 309.5688043100249, y: 187.66446326122298),
      ], orders: List.filled(4, 3))
    ]);
    final result = a.union(b, accuracy: 1.0e-4);
    final point = Point(x: 302, y: 191);
    final rule = PathFillRule.evenOdd;
    expect(a.contains(point, using: rule), isTrue);
    expect(b.contains(point, using: rule), isTrue);
    expect(result.contains(point, using: rule), isTrue,
        reason: "a union b should contain point that is in both a and b");
    expect(
        result.boundingBox.rect
            .insetBy(dx: -1, dy: -1)
            .containsRectangle(a.boundingBox.rect),
        isTrue,
        reason: "resulting bounding box should contain a.boundingBox");
    expect(
        result.boundingBox.rect
            .insetBy(dx: -1, dy: -1)
            .containsRectangle(b.boundingBox.rect),
        isTrue,
        reason: "resulting bounding box should contain b.boundingBox");
  });

  test("Intersecting", () {
    final expectedResult = Path(components: [
      PathComponent(curves: [
        LineSegment(p0: p1, p1: p2),
        LineSegment(p0: p2, p1: p3),
        LineSegment(p0: p3, p1: p9),
        LineSegment(p0: p9, p1: p1),
      ])
    ]);
    final square1 = createSquare1();
    final square2 = createSquare2();
    final intersected = square1.intersect(square2);
    expect(intersected.components.length, 1);
    expect(
        componentsEqualAsideFromElementOrdering(
            intersected.components[0], expectedResult.components[0]),
        isTrue);
  });

  test("IntersectingSelf", () {
    final square = createSquare1();
    expect(square.intersect(square), square);
    expect(square.intersect(square.independentCopy()), square);
  });

  test("SubtractingSelf", () {
    final square = createSquare1();
    final expectedResult = Path();
    expect(square.subtract(square), expectedResult);
    expect(square.subtract(square.independentCopy()), expectedResult);
  });

  test("SubtractingWindingDirection", () {
    // this is a specific test of `subtracting` to ensure that when a component creates a "hole"
    // the order of the hole is reversed so that it is not contained in the shape when using .winding fill rule
    final circle = Path(ellipseIn: Rectangle(0, 0, 3, 3));
    final hole = Path(ellipseIn: Rectangle(1, 1, 1, 1));
    final donut = circle.subtract(hole);
    // inside the donut (but not the hole)
    expect(donut.contains(Point(x: 0.5, y: 0.5), using: PathFillRule.winding),
        isTrue);
    // center of donut hole
    expect(donut.contains(Point(x: 1.5, y: 1.5), using: PathFillRule.winding),
        isFalse);
  });

  test("SubtractingEntirelyErased", () {
    // this is a specific test of `subtracting` to ensure that if a path component is entirely contained in the subtracting path that it gets removed
    final circle = Path(ellipseIn: Rectangle(-1, -1, 2, 2));
    final biggerCircle = Path(ellipseIn: Rectangle(-2, -2, 4, 4));
    expect(circle.subtract(biggerCircle).isEmpty, isTrue);
  });

  test("SubtractingEdgeCase1", () {
    // this is a specific edge case test of `subtracting`. There was an issue where if a path element intersected at the exact border between
    // two elements on the other path it would count as two intersections. The winding count would then be incremented twice on the way in
    // but only once on the way out. So the entrance would be recognized but the exit not recognized.

    final rectangle = Path.fromRect(Rectangle(-1, -1, 4, 3));
    final circle = Path(ellipseIn: Rectangle(0, 0, 4, 4));

    // the circle intersects the rect at (0,2) and (3, 0.26792) ... the last number being exactly 2 - sqrt(3)
    final difference = rectangle.subtract(circle);
    expect(difference.components.length, 1);
    expect(difference.contains(Point(x: 2.0, y: 2.0)), isFalse);
  });

  test("SubtractingEdgeCase2", () {
    // this unit test demosntrates an issue that came up in development where the logic for the winding direction
    // when corners intersect was not quite correct.

    final square1 = Path.fromRect(Rectangle(0.0, 0.0, 2.0, 2.0));
    final square2 = Path(components: [
      PathComponent.raw(points: [
        Point.zero,
        Point(x: 1.0, y: -1.0),
        Point(x: 2.0, y: 0.0),
        Point(x: 1.0, y: 1.0),
        Point.zero,
      ], orders: List.filled(4, 1))
    ]);

    final result = square1.subtract(square2);

    final expectedResult = Path(components: [
      PathComponent.raw(points: [
        Point.zero,
        Point(x: 1.0, y: 1.0),
        Point(x: 2.0, y: 0.0),
        Point(x: 2.0, y: 2.0),
        Point(x: 0.0, y: 2.0),
        Point.zero,
      ], orders: List.filled(5, 1))
    ]);

    expect(result.components.length, expectedResult.components.length);
    expect(
        componentsEqualAsideFromElementOrdering(
            result.components[0], expectedResult.components[0]),
        isTrue);
  });

  test("CrossingsRemoved", () {
    final points = [
      Point.zero,
      Point(x: 3, y: 0),
      Point(x: 3, y: 3),
      Point(x: 1, y: 1),
      Point(x: 2, y: 1),
      Point(x: 0, y: 3),
      Point(x: 0, y: 0),
    ];
    final path = Path(components: [
      PathComponent.raw(points: points, orders: List.filled(6, 1))
    ]);
    final intersection = Point(x: 1.5, y: 1.5);

    final expectedResult = Path(components: [
      PathComponent.raw(points: [
        points[0],
        points[1],
        points[2],
        intersection,
        points[5],
        Point.zero,
      ], orders: List.filled(5, 1))
    ]);

    expect(path.contains(Point(x: 1.5, y: 1.25), using: PathFillRule.winding),
        isTrue);
    expect(path.contains(Point(x: 1.5, y: 1.25), using: PathFillRule.evenOdd),
        isFalse);

    final result = path.crossingsRemoved();
    expect(result.components.length, 1);
    expect(
        componentsEqualAsideFromElementOrdering(
            result.components[0], expectedResult.components[0]),
        isTrue);

    // check also that the algorithm works when the first point falls *inside* the path
    final pathAlt = Path(components: [
      PathComponent.raw(points: [
        for (var i = 3; i < points.length; i++) points[i],
        for (var i = 1; i <= 3; i++) points[i],
      ], orders: List.filled(6, 1))
    ]);

    final resultAlt = pathAlt.crossingsRemoved();
    expect(resultAlt.components.length, 1);
    expect(
        componentsEqualAsideFromElementOrdering(
            resultAlt.components[0], expectedResult.components[0]),
        isTrue);
  });

  test("CrossingsRemovedNoCrossings", () {
    // a test which ensures that if a path has no crossings then crossingsRemoved does not modify it
    final square = Path(ellipseIn: Rectangle(0, 0, 1, 1));
    final result = square.crossingsRemoved();
    expect(result.components.length, 1);
    expect(
        componentsEqualAsideFromElementOrdering(
            result.components[0], square.components[0]),
        isTrue);
  });

  test("CrossingsRemovedEdgeCase", () {
    // this is an edge cases which caused difficulty in practice
    // the contour, which intersects at (1,1) creates two squares, one with -1 winding count
    // the other with +1 winding count
    // incorrect implementation of this algorithm previously interpretted
    // the crossing as an entry / exit, which would completely cull off the square with +1 count

    final points = [
      Point(x: 0, y: 1),
      Point(x: 1, y: 1),
      Point(x: 2, y: 1),
      Point(x: 2, y: 2),
      Point(x: 1, y: 2),
      Point(x: 1, y: 1),
      Point(x: 1, y: 0),
      Point(x: 0, y: 0),
    ];

    final contour = Path(components: [
      PathComponent.raw(points: [
        ...points,
        Point(x: 0, y: 1),
      ], orders: List.filled(8, 1))
    ]);
    // winding count at center of one square region
    expect(contour.windingCount(Point(x: 0.5, y: 0.5)), -1);
    // winding count at center of other square region
    expect(contour.windingCount(Point(x: 1.5, y: 1.5)), 1);

    final crossingsRemoved = contour.crossingsRemoved();

    expect(crossingsRemoved.components.length, 1);
    expect(
        componentsEqualAsideFromElementOrdering(
            crossingsRemoved.components[0], contour.components[0]),
        isTrue);
  });

  test("CrossingsRemovedEdgeCaseInnerLoop", () {
    // the path is a box with a loop that begins at (2,0), touches the top of the box at (2,2) exactly tangent
    // this tests an edge case of crossingsRemoved() when vertices of the path are exactly equal
    // the path does a complete loop in the middle

    final path = Path(components: [
      PathComponent.raw(points: [
        Point(x: 0, y: 0),
        Point(x: 2, y: 0),
        // loop in a complete circle back to 2, 0
        Point(x: 1.9999999999999998, y: 0),
        Point(x: 2.5522847497999996, y: 3.3817687553023339E-17),
        Point(x: 3, y: 0.44771525020000003),
        Point(x: 3, y: 1),
        Point(x: 3, y: 0.99999999999999988),
        Point(x: 3, y: 1.5522847497999999),
        Point(x: 2.5522847498000001, y: 2),
        Point(x: 2, y: 2),
        Point(x: 2, y: 2),
        Point(x: 1.4477152501999999, y: 2),
        Point(x: 1, y: 1.5522847498000001),
        Point(x: 1, y: 1),
        Point(x: 1, y: 1),
        Point(x: 1, y: 0.44771525020000003),
        Point(x: 1.4477152501999999, y: 1.5440922981898462E-16),
        Point(x: 2, y: 2.2204460492503131E-16),
        // proceed around to close the shape (grazing the loop at (2,2)
        Point(x: 4, y: 0),
        Point(x: 4, y: 2),
        Point(x: 2, y: 2),
        Point(x: 0, y: 2),
        Point(x: 0, y: 0),
      ], orders: [
        1,
        1,
        3,
        1,
        3,
        1,
        3,
        1,
        3,
        1,
        1,
        1,
        1,
        1,
      ])
    ]);

    // Quartz 'addArc' function creates some terrible near-zero length line segments
    // final's eliminate those;
    final curves2 = path.components[0].curves
        .map(($0) {
          return $0.copyWith(
              points: $0.points.map((point) {
            final rounded = Point(
                x: point.x.round().toDouble(), y: point.y.round().toDouble());
            return distance(point, rounded) < 1.0e-3 ? rounded : point;
          }).toList());
        })
        .where(($0) => $0.length() > 0.0)
        .toList();
    final cleanPath = Path(components: [PathComponent(curves: curves2)]);

    final result = cleanPath.crossingsRemoved(accuracy: 1.0e-4);

    // check that the inner loop was eliminated by checking the winding count in the middle
    expect(result.windingCount(Point(x: 0.5, y: 1)), 1);
    // if the inner loop wasn't eliminated we'd have a winding count of 2 here
    expect(result.windingCount(Point(x: 2.0, y: 1)), 1);
    expect(result.windingCount(Point(x: 3.5, y: 1)), 1);
  });

  test("CrossingsRemovedRealWorldEdgeCaseMagicNumbers", () {
    // in practice this data was failing because 'smallNumber', a magic number in augmented graph was too large
    // it was fixed by decreasing the value by 10x
    final path = Path(components: [
      PathComponent.raw(points: [
        Point(x: 79.595592909566051, y: 697.90080119125719),
        Point(x: 85.91646553575535, y: 708.7944954952286),
        Point(x: 82.209461287320394, y: 722.74965868366621),
        Point(x: 71.315767448818974, y: 729.07053103977489),
        Point(x: 60.422073504252602, y: 735.39140345742589),
        Point(x: 46.466910315814872, y: 731.68439920899084),
        Point(x: 40.14603795970622, y: 720.79070537048938),
        Point(x: 39.075491053398579, y: 718.70748128540106),
        Point(x: 37.211106249606829, y: 711.94746495233801),
        Point(x: 37.211442270991327, y: 706.7177736592248),
        Point(x: 38.653959655396257, y: 694.20597483369818),
        Point(x: 49.966168031209349, y: 685.2325492391592),
        Point(x: 62.477966856736003, y: 686.67506662356413),
        Point(x: 74.989767853626233, y: 688.11758425831113),
        Point(x: 83.963193448165171, y: 699.42979263412428),
        Point(x: 82.520676063760234, y: 711.94159145965091),
        Point(x: 82.519999600760272, y: 706.72068203708511),
        Point(x: 80.658894823573874, y: 699.97153890998186),
        Point(x: 79.595592909566051, y: 697.90080119125719),
      ], orders: List.filled(6, 3))
    ]);
    final result = path.crossingsRemoved(accuracy: 0.01);
    // in practice .crossingsRemoved was cutting off most of the shape
    expect(path.boundingBox.size.x, closeTo(result.boundingBox.size.x, 1.0e-3));
    expect(path.boundingBox.size.y, closeTo(result.boundingBox.size.y, 1.0e-3));
    expect(result.components[0].numberOfElements,
        5); // with crossings removed we should have 1 fewer curve (the last one)
  });

  test("CrossingsRemovedAnotherRealWorldCase", () {
    final path = Path(components: [
      PathComponent.raw(points: [
        Point(x: 503.3060153966664, y: 766.91406123670458),
        Point(x: 506.00197729763778, y: 761.53305226027192),
        Point(x: 512.54965602940433, y: 759.35639149268457),
        Point(x: 517.93066511499887, y: 762.05235344834762),
        Point(x: 523.31167440859258, y: 764.74831550822125),
        Point(x: 525.48833517617982, y: 771.29599423998775),
        Point(x: 522.79237322051688, y: 776.67700332558229),
        Point(x: 522.66193989935687, y: 776.95503037331412),
        Point(x: 522.7228057838222, y: 776.85328521612985),
        Point(x: 520.75883693519904, y: 764.31667477487201),
        Point(x: 524.98765809133533, y: 768.62380743389974),
        Point(x: 524.92417407494906, y: 775.54356522000523),
        Point(x: 520.61704141592134, y: 779.77238637614164),
        Point(x: 516.30990838641276, y: 784.00120789602295),
        Point(x: 509.39015060030721, y: 783.93772387963656),
        Point(x: 505.16132944417086, y: 779.63059122060884),
        Point(x: 503.19076843492786, y: 767.08726654168265),
        Point(x: 503.37614603814308, y: 766.75639540793588),
        Point(x: 503.3060153966664, y: 766.91406123670458),
      ], orders: List.filled(6, 3))
    ]);
    final result = path.crossingsRemoved(accuracy: 1.0e-5);
    // in practice .crossingsRemoved was cutting off most of the shape
    expect(path.boundingBox.size.x, closeTo(result.boundingBox.size.x, 1.0e-3));
    expect(path.boundingBox.size.y, closeTo(result.boundingBox.size.y, 1.0e-3));
  });

  test("CrossingsRemovedThirdRealWorldCase", () {
    final p = Path(components: [
      PathComponent.raw(points: [
        Point(x: 115.23034681147224, y: 59.327037989273855),
        Point(x: 130.4334714935808, y: 59.32703798927386),
        Point(x: 130.4334714935808, y: 215.00646454457666),
        Point(x: 115.23034681147224, y: 215.00646454457666),
        Point(x: 115.23034681147222, y: 82.92265451611944),
        Point(x: 115.23034681147224, y: 59.327037989273855),
      ], orders: List.filled(5, 1)),
      PathComponent.raw(points: [
        Point(x: 130.43347149358081, y: 59.327037989273869),
        Point(x: 130.43347149358078, y: 82.922654516119451),
        Point(x: 130.43347149358081, y: 215.00646454457666),
        Point(x: 130.43347149358081, y: 225.1418809993157),
        Point(x: 115.23034681147224, y: 225.1418809993157),
        Point(x: 115.23034681147224, y: 215.00646454457666),
        Point(x: 115.23034681147224, y: 59.327037989273862),
        Point(x: 115.23034681147224, y: 49.191621534534818),
        Point(x: 130.43347149358081, y: 49.191621534534832),
        Point(x: 130.43347149358081, y: 59.327037989273869),
      ], orders: [
        1,
        1,
        3,
        1,
        3
      ]),
    ]);
    p.crossingsRemoved(accuracy: 0.0001);
  });

  test("CrosingsRemovedFourthRealWorldCase", () {
    // this case was cauesd by a curve that this-intersected which caused us to make the wrong determination
    // classifying which parts of the path should be included in the final result;
    final path = Path(components: [
      PathComponent.raw(points: [
        Point(x: 128.65039465906003, y: 123.73954643229627),
        Point(x: 125.4190121591063, y: 126.96936863167058),
        Point(x: 120.18117084764445, y: 126.96810375813484),
        Point(x: 116.95134864827014, y: 123.73672125818112),
        Point(x: 113.72152644889583, y: 120.5053387582274),
        Point(x: 113.72279132243156, y: 115.26749744676555),
        Point(x: 116.95417382238529, y: 112.03767524739123),
        Point(x: 119.3560792543184, y: 110.34087389676174),
        Point(x: 120.25529993069892, y: 109.98254275757822),
        Point(x: 117.06818455296886, y: 111.94933998303057),
        Point(x: 120.31240285203181, y: 108.71058333093575),
        Point(x: 125.56789243958164, y: 108.71501087060513),
        Point(x: 128.80664909167646, y: 111.95922916966808),
        Point(x: 132.04540574377128, y: 115.20344746873103),
        Point(x: 132.04097820410189, y: 120.45893705628086),
        Point(x: 128.79675990503895, y: 123.69769370837568),
        Point(x: 125.59151708590264, y: 125.68258785765616),
        Point(x: 126.31169113142379, y: 125.37317639620701),
        Point(x: 128.65039465906003, y: 123.73954643229627),
      ], orders: List.filled(6, 3))
    ]);
    final result = path.crossingsRemoved(accuracy: 1.0e-4);
    final point1 = Point(x: 128.50258215906004, y: 123.86146049479626);
    final point2 = Point(x: 128.64870715906002, y: 123.77228080729627);
    final point3 = Point(x: 127.29466809656003, y: 124.65276518229626);
    expect(result.components.length, 2,
        reason: "result should be a path with a hole");
    expect(result.contains(point1, using: PathFillRule.evenOdd), isTrue);
    expect(result.contains(point2, using: PathFillRule.evenOdd), isTrue);
    expect(result.contains(point3, using: PathFillRule.evenOdd), isFalse);
  });

  test("CrossingsRemovedMulticomponent", () {
    // this path is a square with a self-intersecting inner region that should form a square shaped hole when crossings
    // this is similar to what happens if you use CoreGraphics to stroke shape, albeit simplified here for the sake of testing
    final rect = Path.fromRect(Rectangle(0, 0, 5, 5));
    final path = Path(components: [
      PathComponent.raw(
        points: rect.components[0].points,
        orders: rect.components[0].orders,
      ),
      PathComponent.raw(points: [
        Point(x: 1, y: 2),
        Point(x: 2, y: 1),
        Point(x: 2, y: 4),
        Point(x: 1, y: 3),
        Point(x: 4, y: 3),
        Point(x: 3, y: 4),
        Point(x: 3, y: 1),
        Point(x: 4, y: 2),
        Point(x: 1, y: 2),
      ], orders: List.filled(8, 1))
    ]);
    final result = path.crossingsRemoved();

    final expectedResult = Path(components: [
      rect.components[0],
      PathComponent.raw(points: [
        Point(x: 2, y: 2),
        Point(x: 2, y: 3),
        Point(x: 3, y: 3),
        Point(x: 3, y: 2),
        Point(x: 2, y: 2),
      ], orders: List.filled(4, 1)),
    ]);

    expect(result.components.length, 2);
    expect(
        componentsEqualAsideFromElementOrdering(
            result.components[0], expectedResult.components[0]),
        isTrue);
    expect(
        componentsEqualAsideFromElementOrdering(
            result.components[1], expectedResult.components[1]),
        isTrue);
  });

  test("CrossingsRemovedMulticomponentCoincidentEdgeRealWorldIssue", () {
    final path = Path(components: [
      PathComponent.raw(points: [
        Point(x: 306.7644175272825, y: 37.62048178369263),
        Point(x: 306.7644175272825, y: 39.90095048600892),
        Point(x: 304.4839488249662, y: 39.90095048600892),
        Point(x: 304.4010007151713, y: 37.61425955635238),
        Point(x: 306.7644175272825, y: 37.62048178369263)
      ], orders: List.filled(4, 1)),
      PathComponent.raw(points: [
        Point(x: 304.5969784942766, y: 37.514703918908296),
        Point(x: 306.87744719659287, y: 37.514703918908296),
        Point(x: 306.87744719659287, y: 39.79517262122458),
        Point(x: 306.7644175272825, y: 39.90095048600892),
        Point(x: 304.4839488249662, y: 39.90095048600892),
        Point(x: 304.4839488249662, y: 37.62048178369263),
        Point(x: 304.5969784942766, y: 37.514703918908296)
      ], orders: List.filled(6, 1)),
    ]);

    final result = path.crossingsRemoved(accuracy: 0.0001);
    expect(result.components.length, 1);
    // in practice we had an issue where this came out to be 9 instead of 7
    // where the coincident line shared between the component was followed a 2nd time (+1)
    // and then to recover from the error we jumped back (+1 again)
    // this was because although a `union` between two paths would exclude coincident edges
    // doing crossings removed would not.
    expect(result.components.first.numberOfElements, 7);
  });

  test("CrossingsRemovedRealWorldInfiniteLoop", () {
    // in testing this data previously caused an infinite loop in AgumentedGraph.booleanOperation(_:)

    final path = Path(components: [
      PathComponent.raw(points: [
        Point(x: 431.23946949288751, y: 109.81690300533613),
        Point(x: 431.23946949288751, y: 110.13177002702506),
        Point(x: 430.98421933899738, y: 110.3870201809152),
        Point(x: 430.66935231730844, y: 110.3870201809152),
        Point(x: 382.89122776801867, y: 110.3870201809152),
        Point(x: 383.46134494359774, y: 109.81690300533613),
        Point(x: 383.46134494359774, y: 125.44498541142156),
        Point(x: 382.89122776801867, y: 124.87486823584248),
        Point(x: 430.66935231730844, y: 124.87486823584248),
        Point(x: 430.09923514172937, y: 125.44498541142156),
        Point(x: 430.09923514172937, y: 99.923961447548834),
        Point(x: 431.23946949288751, y: 99.923961447548834),
        Point(x: 431.23946949288751, y: 109.81690300533613),
      ], orders: [
        3,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
      ]),
      PathComponent.raw(points: [
        Point(x: 430.09923514172937, y: 109.81690300533613),
        Point(x: 430.09923514172937, y: 99.923961447548834),
        Point(x: 430.09923514172937, y: 99.16380521344341),
        Point(x: 431.23946949288751, y: 99.16380521344341),
        Point(x: 431.23946949288751, y: 99.923961447548834),
        Point(x: 431.23946949288751, y: 125.44498541142156),
        Point(x: 431.23946949288751, y: 125.75985243311048),
        Point(x: 430.98421933899738, y: 126.01510258700063),
        Point(x: 430.66935231730844, y: 126.01510258700063),
        Point(x: 382.89122776801867, y: 126.01510258700063),
        Point(x: 382.57636074632973, y: 126.01510258700063),
        Point(x: 382.3211105924396, y: 125.75985243311048),
        Point(x: 382.3211105924396, y: 125.44498541142156),
        Point(x: 382.3211105924396, y: 109.81690300533613),
        Point(x: 382.3211105924396, y: 109.5020359836472),
        Point(x: 382.57636074632973, y: 109.24678582975706),
        Point(x: 382.89122776801867, y: 109.24678582975706),
        Point(x: 430.66935231730844, y: 109.24678582975706),
        Point(x: 430.09923514172937, y: 109.81690300533613),
      ], orders: [
        1,
        3,
        1,
        3,
        1,
        3,
        1,
        3,
        1,
        1,
      ])
    ]);
    path.crossingsRemoved(accuracy: 0.01);

    // for now the test's only expectation is that we do not go into an infinite loop
    // TODO: make test stricter
  });

//    test("IntersectingOpenPath", () {
//        // an open path intersecting a closed path should remove the region outside the closed path
//    }
//
//    test("UnionOpenPath", () {
//        // union'ing with an open path simply appends the open components (for now)
//    }
//
//    test("SubtractingOpenPath", () {
//        // an open path minus a closed path should remove the region inside the closed path
//
//        final openPath = Path(curve: CubicCurve(p0: Point(x: 1, y: 1),;
//                                              p1: Point(x: 2, y: 2),
//                                              p2: Point(x: 4, y: 0),
//                                              p3: Point(x: 5, y: 1)))
//        final closedPath = Path(cgPath: CGPath(rect: Rectangle(x: 0, y: 0, width: 2, height: 2), transform: nil));
//
//        //final subtractionResult = openPath.subtract(closedPath, accuracy: 1.0e-5);
//
//        // intersects at t = 0.27254795438823776
//
//        final intersections = openPath.intersections(with: closedPath, accuracy: 1.0e-10).map { openPath.point(at: $0.indexedPathLocation1)};
//        print(intersections)
//        #warning("this test just prints stuff?")
//    });
}
