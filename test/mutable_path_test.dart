// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'dart:math';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

void main() {
  test("Empty", () {
    final mPath = MutablePath();
    final path = mPath.toPath();
    expect(path.components.length, 0);
  });

  test("AddLine", () {
    final temp = MutablePath();
    temp.move(to: Point.zero);
    temp.addLine(to: Point(x: 1.0, y: 0.0));
    temp.addLine(to: Point(x: 2.0, y: 0.0));
    temp.addLine(to: Point(x: 2.0, y: 1.0));
    temp.addLine(to: Point(x: 1.0, y: 1.0));
    temp.addLine(to: Point(x: 0.0, y: 1.0));
    temp.closeSubpath();
    final path = temp.toPath();
    expect(path.components.length, 1);
    pointsMatch(path.components[0].points, [
      Point(x: 0.0, y: 0.0),
      Point(x: 1.0, y: 0.0),
      Point(x: 2.0, y: 0.0),
      Point(x: 2.0, y: 1.0),
      Point(x: 1.0, y: 1.0),
      Point(x: 0.0, y: 1.0),
      Point(x: 0.0, y: 0.0),
    ]);
  });

  test("AddLines", () {
    final mPath = MutablePath();
    mPath.addLines(between: [
      Point(x: 0, y: 2),
      Point(x: 2, y: 4),
      Point(x: 0, y: 4),
    ]);
    mPath.closeSubpath();
    final triangle = mPath.toPath();
    expect(triangle.components.length, 1);
    pointsMatch(triangle.components[0].points, [
      Point(x: 0, y: 2),
      Point(x: 2, y: 4),
      Point(x: 0, y: 4),
      Point(x: 0, y: 2),
    ]);
  });

  test("AddLines with origin at extremes", () {
    final points = [
      Point(x: 0, y: 0),
      Point(x: 3, y: 0),
      Point(x: 3, y: 3),
      Point(x: 1, y: 1),
      Point(x: 2, y: 1),
      Point(x: 0, y: 3),
      Point(x: 0, y: 0),
    ];
    final mPath = MutablePath();
    mPath.addLines(between: points);
    mPath.closeSubpath();
    final path = mPath.toPath();
    expect(path.components.length, 1);
    pointsMatch(path.components[0].points, points);
  });

  test("AddRect", () {
    final mPath = MutablePath();
    mPath.addRect(Rectangle(0, 0, 5, 5));
    mPath.addRect(Rectangle(1, 1, 3, 3));
    final path = mPath.toPath();
    expect(path.components.length, 2);
    pointsMatch(path.components[0].points, [
      Point(x: 0, y: 0),
      Point(x: 5, y: 0),
      Point(x: 5, y: 5),
      Point(x: 0, y: 5),
      Point(x: 0, y: 0),
    ]);
    pointsMatch(path.components[1].points, [
      Point(x: 1, y: 1),
      Point(x: 4, y: 1),
      Point(x: 4, y: 4),
      Point(x: 1, y: 4),
      Point(x: 1, y: 1),
    ]);
  });

  test("AddQuadCurve", () {
    final mPath = MutablePath();

    final p1 = Point(x: 0.0, y: 1.0);
    final p2 = Point(x: 2.0, y: 1.0);
    final p3 = Point(x: 3.0, y: 0.5);
    final p4 = Point(x: 2.0, y: 0.0);
    final p5 = Point(x: 0.0, y: 0.0);
    final p6 = Point(x: -1.0, y: 0.5);

    mPath.move(to: p1);
    mPath.addLine(to: p2);
    mPath.addQuadCurve(to: p4, control: p3);
    mPath.addLine(to: p5);
    mPath.addQuadCurve(to: p1, control: p6);
    mPath.closeSubpath();

    final path = mPath.toPath();
    expect(path.components.length, 1);
    pointsMatch(path.components[0].points, [
      Point(x: 0.0, y: 1.0),
      Point(x: 2.0, y: 1.0),
      Point(x: 3.0, y: 0.5),
      Point(x: 2.0, y: 0.0),
      Point(x: 0.0, y: 0.0),
      Point(x: -1.0, y: 0.5),
      Point(x: 0.0, y: 1.0),
    ]);
  });

  test("Close quad curve", () {
    final temp = MutablePath();
    temp.move(to: Point(x: 2, y: 1));
    temp.addQuadCurve(to: Point(x: 0, y: 0), control: Point(x: 3, y: 4));
    temp.closeSubpath();
    final path = temp.toPath();
    expect(path.components.length, 1);
    pointsMatch(path.components[0].points, [
      Point(x: 2, y: 1),
      Point(x: 3, y: 4),
      Point(x: 0, y: 0),
      Point(x: 2, y: 1),
    ]);
  });

  test("AddCurve", () {
    final mPath = MutablePath();
    mPath.move(to: Point(x: 309.5688043100249, y: 187.66446326122298));
    mPath.addCurve(
        to: Point(x: 304.8877314421214, y: 198.89156106846605),
        control1: Point(x: 311.37643918302956, y: 192.05738329201742),
        control2: Point(x: 309.28065147291585, y: 197.0839261954614));
    mPath.addCurve(
        to: Point(x: 293.6606336348783, y: 194.21048820056248),
        control1: Point(x: 300.4948114113269, y: 200.6991959414707),
        control2: Point(x: 295.46826850788295, y: 198.60340823135695));
    mPath.addCurve(
        to: Point(x: 298.3417065027818, y: 182.98339039331944),
        control1: Point(x: 291.85299876187366, y: 189.81756816976807),
        control2: Point(x: 293.9487864719874, y: 184.79102526632408));
    mPath.addCurve(
        to: Point(x: 309.5688043100249, y: 187.66446326122298),
        control1: Point(x: 302.7346265335763, y: 181.1757555203148),
        control2: Point(x: 307.76116943702027, y: 183.2715432304285));
    final path = mPath.toPath();
    expect(path.components.length, 1);
    expect(path.components[0].points.length, 13);
    pointsMatch(path.components[0].points, [
      Point(x: 309.56880431002492, y: 187.66446326122298),
      Point(x: 311.37643918302956, y: 192.05738329201742),
      Point(x: 309.28065147291585, y: 197.0839261954614),
      Point(x: 304.88773144212138, y: 198.89156106846605),
      Point(x: 300.49481141132691, y: 200.69919594147069),
      Point(x: 295.46826850788295, y: 198.60340823135695),
      Point(x: 293.66063363487831, y: 194.21048820056248),
      Point(x: 291.85299876187366, y: 189.81756816976807),
      Point(x: 293.94878647198738, y: 184.79102526632408),
      Point(x: 298.34170650278179, y: 182.98339039331944),
      Point(x: 302.73462653357632, y: 181.17575552031479),
      Point(x: 307.76116943702027, y: 183.27154323042851),
      Point(x: 309.56880431002492, y: 187.66446326122298),
    ]);
  });

  test("Close curve", () {
    final temp = MutablePath();
    temp.move(to: Point(x: 0, y: 0));
    temp.addCurve(
        to: Point(x: 1, y: -1),
        control1: Point(x: 2, y: 2),
        control2: Point(x: -1, y: 1));
    temp.closeSubpath();
    final path = temp.toPath();
    expect(path.components.length, 1);
    pointsMatch(path.components[0].points, [
      Point(x: 0, y: 0),
      Point(x: 2, y: 2),
      Point(x: -1, y: 1),
      Point(x: 1, y: -1),
      Point(x: 0, y: 0),
    ]);
  });

  test("AddArc", () {
    final mPath = MutablePath();

    mPath.move(to: Point.zero);
    mPath.addLine(to: Point(x: 2.0, y: 0.0));

    // loop in a complete circle back to 2, 0
    mPath.addArc(
        tangent1End: Point(x: 3.0, y: 0.0),
        tangent2End: Point(x: 3.0, y: 1.0),
        radius: 1);
    mPath.addArc(
        tangent1End: Point(x: 3.0, y: 2.0),
        tangent2End: Point(x: 2.0, y: 2.0),
        radius: 1);
    mPath.addArc(
        tangent1End: Point(x: 1.0, y: 2.0),
        tangent2End: Point(x: 1.0, y: 1.0),
        radius: 1);
    mPath.addArc(
        tangent1End: Point(x: 1.0, y: 0.0),
        tangent2End: Point(x: 2.0, y: 0.0),
        radius: 1);

    // proceed around to close the shape (grazing the loop at (2,2)
    mPath.addLine(to: Point(x: 4.0, y: 0.0));
    mPath.addLine(to: Point(x: 4.0, y: 2.0));
    mPath.addLine(to: Point(x: 2.0, y: 2.0));
    mPath.addLine(to: Point(x: 0.0, y: 2.0));
    mPath.closeSubpath();

    final path = mPath.toPath();
    expect(path.components.length, 1);
    expect(path.components[0].points.length, 23);
    pointsMatch(path.components[0].points, [
      Point(x: 0, y: 0),
      Point(x: 2, y: 0),
      Point(x: 2, y: 0),
      Point(x: 2.5522847497999996, y: 0),
      Point(x: 3, y: 0.44771525020000003),
      Point(x: 3, y: 1),
      Point(x: 3, y: 1),
      Point(x: 3, y: 1.5522847497999999),
      Point(x: 2.5522847498000001, y: 2),
      Point(x: 2, y: 2),
      Point(x: 2, y: 2),
      Point(x: 1.4477152501999999, y: 2),
      Point(x: 1, y: 1.5522847498000001),
      Point(x: 1, y: 1),
      Point(x: 1, y: 1),
      Point(x: 1, y: 0.44771525020000003),
      Point(x: 1.4477152501999999, y: 0),
      Point(x: 2, y: 0),
      Point(x: 4, y: 0),
      Point(x: 4, y: 2),
      Point(x: 2, y: 2),
      Point(x: 0, y: 2),
      Point(x: 0, y: 0),
    ]);
  });

  test("AddEllipse", () {
    final circleMPath = MutablePath();
    // a circle centered at origin with radius 1
    circleMPath.addEllipse(rect: Rectangle(-1.0, -1.0, 2.0, 2.0));
    final circlePath = circleMPath.toPath();
    expect(circlePath.components.length, 1);
    expect(circlePath.components[0].points.length, 13);
    pointsMatch(circlePath.components[0].points, [
      Point(x: 1, y: 0),
      Point(x: 1, y: MutablePath.kappa),
      Point(x: MutablePath.kappa, y: 1),
      Point(x: 0, y: 1),
      Point(x: -MutablePath.kappa, y: 1),
      Point(x: -1, y: MutablePath.kappa),
      Point(x: -1, y: 0),
      Point(x: -1, y: -MutablePath.kappa),
      Point(x: -MutablePath.kappa, y: -1),
      Point(x: 0, y: -1),
      Point(x: MutablePath.kappa, y: -1),
      Point(x: 1, y: -MutablePath.kappa),
      Point(x: 1, y: 0),
    ]);
  });

  test("Add mix", () {
    final mPath = MutablePath();
    mPath.move(to: Point(x: 2, y: 1));
    mPath.addLine(to: Point(x: 3, y: 1));
    mPath.addQuadCurve(to: Point(x: 4, y: 2), control: Point(x: 4, y: 1));
    mPath.addCurve(
        to: Point(x: 2, y: 1),
        control1: Point(x: 4, y: 3),
        control2: Point(x: 2, y: 3));
    mPath.move(to: Point(x: 1, y: 1));
    final path = mPath.toPath();
    expect(path.components.length, 2);
    pointsMatch(path.components[0].points, [
      Point(x: 2, y: 1),
      Point(x: 3, y: 1),
      Point(x: 4, y: 1),
      Point(x: 4, y: 2),
      Point(x: 4, y: 3),
      Point(x: 2, y: 3),
      Point(x: 2, y: 1),
    ]);
    pointsMatch(path.components[1].points, [
      Point(x: 1, y: 1),
    ]);
  });

  test("Open path", () {
    final mPath = MutablePath();
    mPath.addLines(between: [
      Point(x: 0, y: 0),
      Point(x: 1, y: 0),
      Point(x: 0, y: 1),
      Point(x: 0, y: -1)
    ]);
    final openPath = mPath.toPath();
    expect(openPath.components.length, 1);
    pointsMatch(openPath.components[0].points, [
      Point(x: 0, y: 0),
      Point(x: 1, y: 0),
      Point(x: 0, y: 1),
      Point(x: 0, y: -1),
    ]);
  });
}

void pointsMatch(List<Point> points, List<Point> expectedPoints) {
  expect(points.length, expectedPoints.length);
  for (var i = 0; i < points.length; i++) {
    expect(points[i], PointMatcher(expectedPoints[i]));
  }
}

class PointMatcher extends Matcher {
  final Point point;
  final double epsilon;

  PointMatcher(this.point, {this.epsilon = 0.0001});

  @override
  Description describe(Description description) {
    return description.add('is close to $point');
  }

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Point) {
      return (item.x - point.x).abs() < epsilon &&
          (item.y - point.y).abs() < epsilon;
    }
    return false;
  }
}
