// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:bezier_kit/src/mutable_path.dart';
import 'package:test/test.dart';

void main() {
  test("Empty", () {
    final emptyPath = MutablePath().toPath();
    expect(Path(), emptyPath);
    expect(MutablePath().toPath(), emptyPath);
  });

  test("Rectangle", () {
    final rect = Rectangle(1, 1, 2, 3);
    final rectPath = (MutablePath()..addRect(rect)).toPath();
    expect(rectPath.components.length, 1);
    expect(rectPath.components[0].points, [
      Point(x: 1, y: 1),
      Point(x: 3, y: 1),
      Point(x: 3, y: 4),
      Point(x: 1, y: 4),
      Point(x: 1, y: 1),
    ]);
  });

  test("SingleOpenPath", () {
    final mPath = MutablePath();
    mPath.move(to: Point(x: 3, y: 4));
    mPath.addCurve(
        to: Point(x: 4, y: 5),
        control1: Point(x: 5, y: 5),
        control2: Point(x: 6, y: 4));
    final path = mPath.toPath();
    expect(path.components.length, 1);
    expect(path.components[0].points, [
      Point(x: 3, y: 4),
      Point(x: 5, y: 5),
      Point(x: 6, y: 4),
      Point(x: 4, y: 5),
    ]);
  });

  test("Quadratic", () {
    final mPath = MutablePath();
    mPath.move(to: Point(x: 3, y: 4));
    mPath.addQuadCurve(to: Point(x: 4, y: 5), control: Point(x: 3.5, y: 7));
    final path = mPath.toPath();
    expect(path.components.length, 1);
    expect(path.components[0].points, [
      Point(x: 3, y: 4),
      Point(x: 3.5, y: 7),
      Point(x: 4, y: 5),
    ]);
  });

  test("SingleClosedPathClosePath", () {
    final mPath = MutablePath();
    mPath.move(to: Point(x: 3, y: 4));
    mPath.addLine(to: Point(x: 4, y: 4));
    mPath.addLine(to: Point(x: 4, y: 5));
    mPath.addLine(to: Point(x: 3, y: 5));
    mPath.closeSubpath();
    final path = mPath.toPath();
    expect(path.components.length, 1);
    expect(path.components[0].points, [
      Point(x: 3, y: 4),
      Point(x: 4, y: 4),
      Point(x: 4, y: 5),
      Point(x: 3, y: 5),
      Point(x: 3, y: 4),
    ]);
  });

  test("MultipleOpenPaths", () {
    final mPath = MutablePath();
    mPath.move(to: Point(x: 3, y: 4));
    mPath.addLine(to: Point(x: 4, y: 5));
    mPath.move(to: Point(x: 6, y: 4));
    mPath.addLine(to: Point(x: 7, y: 5));
    mPath.move(to: Point(x: 9, y: 4));
    mPath.addLine(to: Point(x: 10, y: 5));

    final path = mPath.toPath();
    expect(path.components.length, 3);
    expect(path.components[0].points, [
      Point(x: 3, y: 4),
      Point(x: 4, y: 5),
    ]);
    expect(path.components[1].points, [
      Point(x: 6, y: 4),
      Point(x: 7, y: 5),
    ]);
    expect(path.components[2].points, [
      Point(x: 9, y: 4),
      Point(x: 10, y: 5),
    ]);
  });

  test("SinglePointMoveTo", () {
    final mPath = MutablePath();
    mPath.move(to: Point(x: 3, y: 4));
    final path = mPath.toPath();
    expect(path.components.length, 1);
    expect(path.components[0].points, [Point(x: 3, y: 4)]);
  });

  test("SinglePointMoveToCloseSubpath", () {
    final mPath = MutablePath();
    mPath.move(to: Point(x: 3, y: 4));
    final beforeClosing = mPath.toPath();
    mPath.closeSubpath();
    expect(beforeClosing.components.length, 1);
    expect(mPath.toPath(), beforeClosing);
  });

  test("MultipleSinglePoints", () {
    final mPath = MutablePath();
    mPath.move(to: Point(x: 1, y: 2));
    mPath.move(to: Point(x: 2, y: 3));
    mPath.move(to: Point(x: 3, y: 4));
    var path = mPath.toPath();
    expect(path.components.length, 1);
    expect(path.components[0].points, [Point(x: 3, y: 4)]);
    mPath.addLine(to: Point(x: 4, y: 5));
    path = mPath.toPath();
    expect(path.components.length, 1);
    expect(path.components[0].points, [
      Point(x: 3, y: 4),
      Point(x: 4, y: 5),
    ]);
  });

  test("MultipleComponentsNoMoveto", () {
    // ensure that if the mPath starts a new component without a move(to:) command that we still work properly
    final mPath = MutablePath();
    final firstComponentPoints = [
      Point(x: 0, y: 0),
      Point(x: 1, y: 0),
      Point(x: 1, y: 1),
      Point(x: 0, y: 1),
      Point(x: 0, y: 0)
    ];
    final secondComponentPoint = Point(x: -1, y: 0);
    mPath.addLines(between: firstComponentPoints);
    mPath.closeSubpath();
    mPath.addLine(to: secondComponentPoint);

    final path = mPath.toPath();
    expect(path.components.length, 2);
    expect(path.components[0].points, firstComponentPoints);
    expect(path.components[1].points,
        [firstComponentPoints.last, secondComponentPoint]);
  });

  test("MultipleClosedPaths", () {
    final mPath = MutablePath();
    mPath.addRect(Rectangle(1, 1, 2, 3));
    mPath.addRect(Rectangle(4, 2, 2, 3));
    final path = mPath.toPath();
    expect(path.components.length, 2);
    expect(path.components[0].points, [
      Point(x: 1, y: 1),
      Point(x: 3, y: 1),
      Point(x: 3, y: 4),
      Point(x: 1, y: 4),
      Point(x: 1, y: 1)
    ]);
    expect(path.components[1].points, [
      Point(x: 4, y: 2),
      Point(x: 6, y: 2),
      Point(x: 6, y: 5),
      Point(x: 4, y: 5),
      Point(x: 4, y: 2)
    ]);
  });

  test("EmptyData", () {
    final path = Path.fromData(Uint8List(0));
    expect(path, null);
  });

  final simpleRectangle = Path.fromRect(Rectangle(1, 2, 3, 4));

  final expectedSimpleRectangleData = base64.decode(
      "JbPlSAUAAAAAAQEBAQAAAAAAAPA/AAAAAAAAAEAAAAAAAAAQQAAAAAAAAABAAAAAAAAAEEAAAAAAAAAYQAAAAAAAAPA/AAAAAAAAGEAAAAAAAADwPwAAAAAAAABA");

  test("SimpleRectangle", () {
    expect(simpleRectangle.data, expectedSimpleRectangleData);
  });

  test("WrongMagicNumber", () {
    var data = simpleRectangle.data;
    expect(Path.fromData(data), isNotNull);
    data[0] = ~data[0];
    expect(Path.fromData(data), isNull);
  });

  test("CorruptedData", () {
    final data = simpleRectangle.data;
    expect(Path.fromData(data), isNotNull);
    // missing last y coordinate
    final corruptData1 = data.sublist(0, data.length - 1);
    expect(Path.fromData(corruptData1), null);
    // missing last x coordinate
    final corruptData2 = data.sublist(0, data.length - 9);
    expect(Path.fromData(corruptData2), null);
    // magic number cut off
    final corruptData3 = data.sublist(0, 3);
    expect(Path.fromData(corruptData3), null);
    // only magic number
    final corruptData4 = data.sublist(0, 4);
    expect(Path.fromData(corruptData4), null);
    // command count cut off
    final corruptData5 = data.sublist(0, 5);
    expect(Path.fromData(corruptData5), null);
    // commands cut off
    final corruptData6 = data.sublist(0, 10);
    expect(Path.fromData(corruptData6), null);
  });
}
