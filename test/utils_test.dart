//
//  UtilsTests.swift
//  BezierKit
//
//  Created by Holmes Futrell on 5/12/19.
//  Copyright © 2019 Holmes Futrell. All rights reserved.
//

import 'package:bezier_kit/src/point.dart';
import 'package:bezier_kit/src/utils.dart';
import 'package:test/test.dart';

void main() {
  test("testClamp", () {
    expect(1.0, Utils.clamp(1.0, -1.0, 1.0));
    expect(0.0, Utils.clamp(0.0, -1.0, 1.0));
    expect(-1.0, Utils.clamp(-1.0, -1.0, 1.0));
    expect(1.0, Utils.clamp(2.0, -1.0, 1.0));
    expect(-1.0, Utils.clamp(-2.0, -1.0, 1.0));
    expect(-1.0, Utils.clamp(-double.infinity, -1.0, 1.0));
    expect(1.0, Utils.clamp(double.infinity, -1.0, 1.0));
    expect(-20.0, Utils.clamp(-20.0, -double.infinity, 0.0));
    expect(20.0, Utils.clamp(20.0, 0.0, double.infinity));
    expect(Utils.clamp(double.nan, -1.0, 1.0), isNaN);
  });

  List<double> drootsQuadraticTestHelper(double a, double b, double c) {
    final roots = <double>[];
    Utils.droots3(a, b, c, callback: roots.add);
    return roots;
  }

  List<double> drootsCubicTestHelper(double a, double b, double c, double d) {
    final roots = <double>[];
    Utils.droots4(a, b, c, d, callback: roots.add);
    return roots;
  }

  test("testDrootsCubicWorldIssue1", () {
    var points = [
      Point(x: 523.4257521858988, y: 691.8949684622992),
      Point(x: 523.1393916834338, y: 691.8714265856051),
      Point(x: 522.8595588275791, y: 691.7501129962762),
      Point(x: 522.6404735257349, y: 691.531027694432),
    ];
    const y = 691.87778055040201;
    points = points.map(($0) => $0 - Point(x: 0, y: y)).toList();
    final r = drootsCubicTestHelper(
      points[0].y,
      points[1].y,
      points[2].y,
      points[3].y,
    );
    final filtered = r.where(($0) => $0 >= 0 && $0 <= 1);
    expect(filtered.length, 1);
    expect(filtered.first, closeTo(0.1499651773565319, 1.0e-3));
  });

  test("testDrootsCubicWorldIssue2", () {
    // this data is actually very close to a quadratic. It may get the wrong
    // answer is if is recognized as a cubic
    final points = [
      0.0000010000090924222604,
      0.0000013261883395898622,
      -0.1484297874302456,
      -0.44529201466082213
    ];
    final r = drootsCubicTestHelper(points[0], points[1], points[2], points[3]);
    final filtered = r.where(($0) => $0 >= 0 && $0 <= 1);
    expect(filtered.length, 1);
    expect(filtered.first, closeTo(0.0014849, 1.0e-4));
  }, skip: "Skiped also on the original source");

  test("testDrootsCubicWorldIssue3", () {
    // this data causes issue #81 on GitHub
    // discriminant is positive but very close to zero (8.46e-10)
    // https://github.com/hfutrell/BezierKit/issues/81
    final firstValue = -14.999127297400882;
    final otherValues = 0.00087270259911775838;
    final roots = drootsCubicTestHelper(
        firstValue, otherValues, otherValues, otherValues);
    expect(roots.length, 1);
    expect(roots[0], closeTo(0.961251, 1.0e-4));
  });

  test("testDrootsQuadratic", () {
    const a = 0.36159566118413977;
    const b = -3.2979288390483816;
    const c = 3.5401259561374445;
    final roots = drootsQuadraticTestHelper(a, b, c);
    const accuracy = 1.0e-5;
    expect(roots, hasLength(2));
    expect(roots[0], closeTo(0.053511820486391165, accuracy));
    expect(roots[1], closeTo(0.64370120305889711, accuracy));
  });

  test("testDrootsQuadraticEdgeCases", () {
    const oneThird = 1.0 / 3.0;
    const twoThirds = 2.0 / 3.0;
    expect(drootsQuadraticTestHelper(3, 6, 12), [-1]);
    expect(drootsQuadraticTestHelper(12, 6, 3), [2]);
    expect(drootsQuadraticTestHelper(12, 6, 4), []);
    expect(drootsQuadraticTestHelper(2, 1, 0), [1]);
    expect(drootsQuadraticTestHelper(1, 1, 1), []);
    expect(drootsQuadraticTestHelper(4, -5, 4), [oneThird, twoThirds]);
    expect(drootsQuadraticTestHelper(-4, 5, -4), [oneThird, twoThirds]);
    expect(drootsQuadraticTestHelper(double.nan, double.nan, double.nan), []);
  });

  test("testLinesIntersection", () {
    final p0 = Point(x: 1, y: 2);
    final p1 = Point(x: 3, y: 4);
    final p2 = Point(x: 1, y: 4);
    final p3 = Point(x: 3, y: 2);
    final p4 = Point(x: 1, y: 3);
    final p5 = Point(x: 3, y: 5);
    final nanPoint = Point(x: double.nan, y: double.nan);
    // basic cases
    expect(
      Point(x: 2, y: 3),
      Utils.linesIntersection(p0, p1, p2, p3),
      reason: "these lines should intersect.",
    );
    expect(
      Utils.linesIntersection(p0, p1, p4, p5),
      isNull,
      reason: "these lines should NOT intersect.",
    );
    // degenerate case
    expect(
      Utils.linesIntersection(nanPoint, nanPoint, p0, p1),
      isNull,
      reason: "nothing should intersect a line that includes NaN values.",
    );
  });

  test("testSortedAndUniqued", () {
    expect(<int>[].sortedAndUniqued(), []);
    expect([1].sortedAndUniqued(), [1]);
    expect([1, 1].sortedAndUniqued(), [1]);
    expect([1, 3, 1].sortedAndUniqued(), [1, 3]);
    expect([1, 2, 4, 5, 5, 6].sortedAndUniqued(), [1, 2, 4, 5, 6]);
  });

  test("testMap", () {
    expect(
      Utils.map(5, 4, 6, 8, 12),
      10,
      reason:
          "midpoint of [4, 6] should map to midpoint of [8, 12] (which is 10)",
    );
    expect(
      Utils.map(0.75, 0, 1, 4, 8),
      7,
      reason:
          "75% the way between 0 and 1 should map to 75% between 4 and 8 (which is 7)",
    );
    // might fail for precision reasons
    const tStart = 0.16559884114811005;
    const tEnd = 0.45268493225341283;
    expect(
      Utils.map(0, 0, 1, tStart, tEnd),
      tStart,
      reason:
          "start of first interval (0) should map to start of second interval exactly (tStart)",
    );
    expect(
      Utils.map(1, 0, 1, tStart, tEnd),
      tEnd,
      reason:
          "end of first interval (1) should map to end of second interval exactly (tEnd)",
    );
  });
}
