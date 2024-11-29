// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'dart:math';
import 'dart:ui';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:example/draw.dart';

class Demo {
  final String title;
  final List<Point> quadraticControlPoints;
  final List<Point> cubicControlPoints;
  final void Function(Canvas canvas, DemoState state) drawFunction;

  const Demo({
    required this.title,
    required this.quadraticControlPoints,
    required this.cubicControlPoints,
    required this.drawFunction,
  });
}

class DemoState {
  // whether the demo is set to quadratic (or if false: cubic) mode
  final bool quadratic;
  // location of mouse / touch input if applicable
  final Point? lastInputLocation;
  // a user-draggable Bezier curve if applicable
  final BezierCurve? curve;

  const DemoState({
    required this.quadratic,
    required this.lastInputLocation,
    required this.curve,
  });

  DemoState copyWith(
      {bool? quadratic, Point? lastInputLocation, BezierCurve? curve}) {
    return DemoState(
      quadratic: quadratic ?? this.quadratic,
      lastInputLocation: lastInputLocation ?? this.lastInputLocation,
      curve: curve ?? this.curve,
    );
  }
}

const _cubicControlPoints = [
  Point(x: 100, y: 25),
  Point(x: 10, y: 90),
  Point(x: 110, y: 100),
  Point(x: 150, y: 195)
];

const _quadraticControlPoints = [
  Point(x: 150, y: 40),
  Point(x: 80, y: 30),
  Point(x: 105, y: 150)
];

extension PointExtension on Point {
  Offset toOffset() => Offset(x, y);
}

final demo1 = Demo(
    title: "new Bezier(...)",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: _cubicControlPoints,
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      draw.drawSkeleton(curve: curve);
      draw.drawCurve(curve: curve);
    });

final demo2 = Demo(
    title: "Bezier.quadraticFromPoints",
    quadraticControlPoints: [],
    cubicControlPoints: [],
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      if (demoState.quadratic) {
        final B = Point(x: 100, y: 50);
        final tvalues = [0.2, 0.3, 0.4, 0.5];
        final curves = tvalues
            .map((t) => QuadraticCurve.from3Points(
                start: Point(x: 150, y: 40),
                end: Point(x: 35, y: 160),
                mid: B,
                t: t))
            .toList();
        final offset = Point(x: 45, y: 30);
        for (final (i, b) in curves.indexed) {
          draw.drawSkeleton(curve: b, offset: offset, coords: true);
          draw.setColor(Draw.transparentBlack);
          draw.drawCircle(center: b.points[1], radius: 3, offset: offset);
          draw.drawText(
              text: "t=${tvalues[i]}",
              offset: Point(
                  x: b.points[1].x + offset.x - 15,
                  y: b.points[1].y + offset.y - 20));
          draw.setRandomColor();
          draw.drawCurve(curve: b, offset: offset);
        }
        draw.setColor(Draw.black);
        draw.drawCircle(center: curves[0].points[0], radius: 3, offset: offset);
        draw.drawCircle(center: curves[0].points[2], radius: 3, offset: offset);
        draw.drawCircle(center: B, radius: 3, offset: offset);
      } else {
        final p1 = Point(x: 110, y: 50);
        final B = Point(x: 50, y: 80);
        final p3 = Point(x: 135, y: 100);
        final tvalues = [0.2, 0.3, 0.4, 0.5];
        final curves = tvalues
            .map(($0) =>
                CubicCurve.fromPoints3(start: p1, end: p3, mid: B, t: $0))
            .toList();
        final offset = Point(x: 0.0, y: 0.0);
        for (final curve in curves) {
          draw.setRandomColor();
          draw.drawCurve(curve: curve, offset: offset);
        }
        draw.setColor(Draw.black);
        draw.drawCircle(center: curves[0].points[0], radius: 3, offset: offset);
        draw.drawCircle(center: curves[0].points[3], radius: 3, offset: offset);
        draw.drawCircle(center: B, radius: 3, offset: offset);
      }
    });

final demo3 = Demo(
    title: ".getLUT(steps)",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: _cubicControlPoints,
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);

      final curve = demoState.curve!;
      // final points = <Point>[];
      // for (var at = 0.0; at <= 1; at += 1 / 7) {
      //   points.add(curve.point(at: at));
      // }

      draw.drawSkeleton(curve: curve);
      final lut = curve.lookupTable(steps: 16);
      for (final p in lut) {
        draw.drawCircle(center: p, radius: 2);
      }
    });

final demo4 = Demo(
    title: ".length()",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: [
      Point(x: 100, y: 25),
      Point(x: 10, y: 90),
      Point(x: 110, y: 100),
      Point(x: 132, y: 192)
    ],
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      draw.drawSkeleton(curve: curve);
      draw.drawCurve(curve: curve);
      draw.setColor(Draw.red);
      final arclength = curve.length();
      final offset = curve.offset(distance: -10);
      final last = offset.length - 1;
      for (var idx = 0; idx < offset.length; idx++) {
        final c = offset[idx];
        draw.drawCurve(curve: c);
        if (idx == last) {
          final p1 = curve.offsetAt(0.95, distance: -15);
          final p2 = c.point(at: 1);
          final p3 = curve.offsetAt(0.95, distance: -5);
          draw.drawLine(from: p1, to: p2);
          draw.drawLine(from: p2, to: p3);
          final label = arclength.toStringAsFixed(1);
          draw.drawText(text: label, offset: Point(x: p2.x + 7, y: p2.y - 3));
        }
      }
    });

final demo5 = Demo(
    title: ".get(t) and .compute(t)",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: _cubicControlPoints,
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      draw.drawSkeleton(curve: curve);
      draw.drawCurve(curve: curve);
      draw.setColor(Draw.red);
      draw.drawPoint(origin: curve.point(at: 0.5));
    });

final demo6 = Demo(
    title: ".derivative(t)",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: _cubicControlPoints,
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      draw.drawSkeleton(curve: curve);
      draw.drawCurve(curve: curve);
      draw.setColor(Draw.red);
      for (var t = 0.0; t <= 1; t += 0.1) {
        final pt = curve.point(at: t);
        final dv = curve.derivative(at: t);
        draw.drawLine(from: pt, to: pt + dv);
      }
    });

final demo7 = Demo(
    title: ".normal(t)",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: _cubicControlPoints,
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      draw.drawSkeleton(curve: curve);
      draw.drawCurve(curve: curve);
      draw.setColor(Draw.red);
      const d = 20.0;
      for (var t = 0.0; t <= 1; t += 0.1) {
        final pt = curve.point(at: t);
        final dv = curve.normal(at: t);
        draw.drawLine(from: pt, to: pt + dv * d);
      }
    });

final demo8 = Demo(
    title: ".split(t) and .split(t1,t2)",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: _cubicControlPoints,
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      draw.setColor(Draw.lightGrey);
      draw.drawSkeleton(curve: curve);
      draw.drawCurve(curve: curve);
      final c = curve.split(from: 0.25, to: 0.75);
      draw.setColor(Draw.red);
      draw.drawCurve(curve: c);
      draw.drawCircle(center: curve.point(at: 0.25), radius: 3);
      draw.drawCircle(center: curve.point(at: 0.75), radius: 3);
    });

final demo9 = Demo(
    title: ".extrema()",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: _cubicControlPoints,
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      draw.drawSkeleton(curve: curve);
      draw.drawCurve(curve: curve);
      draw.setColor(Draw.red);
      for (final t in curve.extrema().all) {
        draw.drawCircle(center: curve.point(at: t), radius: 3);
      }
    });

final demo10 = Demo(
    title: ".bbox()",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: _cubicControlPoints,
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      draw.drawSkeleton(curve: curve);
      draw.drawCurve(curve: curve);
      draw.setColor(Draw.pinkish);
      draw.drawBoundingBox(boundingBox: curve.boundingBox);
    });

final demo11 = Demo(
    title: ".hull(t)",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: [
      Point(x: 100, y: 25),
      Point(x: 10, y: 90),
      Point(x: 50, y: 185),
      Point(x: 170, y: 175)
    ],
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      draw.drawSkeleton(curve: curve);
      draw.drawCurve(curve: curve);
      draw.setColor(Draw.red);
      final hull = curve.hull(0.5);
      draw.drawHull(hull: hull);
      draw.drawCircle(center: hull.last, radius: 5);
    });

final demo12 = Demo(
    title: ".project(point)",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: [
      Point(x: 100, y: 25),
      Point(x: 10, y: 90),
      Point(x: 50, y: 185),
      Point(x: 170, y: 175)
    ],
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      draw.drawSkeleton(curve: curve);
      draw.drawCurve(curve: curve);
      draw.setColor(Draw.pinkish);
      if (demoState.lastInputLocation != null) {
        final p = curve.project(demoState.lastInputLocation!).point;
        draw.drawLine(from: demoState.lastInputLocation!, to: p);
      }
    });

final demo13 = Demo(
    title: ".offset(d) and .offset(t, d)",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: _cubicControlPoints,
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      draw.drawSkeleton(curve: curve);
      draw.drawCurve(curve: curve);
      draw.setColor(Draw.red);
      for (final c in curve.offset(distance: 25)) {
        draw.drawCurve(curve: c);
      }
      draw.drawPoint(origin: curve.offsetAt(0.5, distance: 25));
    });

final demo14 = Demo(
    title: ".reduce(t)",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: _cubicControlPoints,
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      draw.drawSkeleton(curve: demoState.curve!);
      final List<BezierCurve> reduced;
      if (demoState.quadratic) {
        final curve = demoState.curve! as QuadraticCurve;
        reduced = curve.reduce().map((s) => s.curve).toList();
      } else {
        final curve = demoState.curve! as CubicCurve;
        reduced = curve.reduce().map((s) => s.curve).toList();
      }
      if (reduced.isNotEmpty) {
        for (var i = 0; i < reduced.length; i++) {
          final c = reduced[i];
          draw.setColor(Draw.black);
          if (i > 0) {
            draw.drawCircle(center: c.points[0], radius: 3);
          }
          draw.setRandomColor();
          draw.drawCurve(curve: c);
        }
      }
    });

final demo15 = Demo(
    title: ".scale(d)",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: _cubicControlPoints,
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      draw.drawSkeleton(curve: curve);
      draw.setColor(Draw.black);
      final List<BezierCurve> reduced;
      if (demoState.quadratic) {
        final curve = demoState.curve! as QuadraticCurve;
        reduced = curve.reduce().map((s) => s.curve).toList();
      } else {
        final curve = demoState.curve! as CubicCurve;
        reduced = curve.reduce().map((s) => s.curve).toList();
      }
      if (reduced.isNotEmpty) {
        for (var i = 0; i < reduced.length; i++) {
          final c = reduced[i];
          if (i > 0) {
            draw.drawCircle(center: c.points[0], radius: 3);
          }
          draw.drawCurve(curve: c);
        }
        for (var i = -30; i <= 30; i += 10) {
          final scaled =
              reduced[reduced.length ~/ 2].scale(distance: i.toDouble());
          if (scaled == null) continue;
          draw.drawCurve(curve: scaled);
        }
      } else {
        draw.drawCurve(curve: curve);
      }
    });

final demo16 = Demo(
    title: ".outline(d)",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: [
      Point(x: 102, y: 33),
      Point(x: 16, y: 99),
      Point(x: 101, y: 129),
      Point(x: 132, y: 173)
    ],
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      draw.drawSkeleton(curve: curve);
      draw.drawCurve(curve: curve);
      draw.setColor(Draw.red);
      void doc(BezierCurve c) => draw.drawCurve(curve: c);
      final outline = curve.outline(distance: 25);
      outline.curves.forEach(doc);
      draw.setColor(Draw.transparentBlue);
      outline.offset(distance: 10)?.curves.forEach(doc);
      outline.offset(distance: -10)?.curves.forEach(doc);
    });

final demo17 = Demo(
    title: "outlineShapes",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: _cubicControlPoints,
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      draw.drawSkeleton(curve: curve);
      draw.drawCurve(curve: curve);
      draw.setColor(Draw.red);
      for (final shape in curve.outlineShapes(distance: 25)) {
        draw.setRandomFill(alpha: 0.2);
        draw.drawShape(shape: shape);
      }
    });

final demo18 = Demo(
    title: ".selfIntersections",
    quadraticControlPoints: _quadraticControlPoints,
    cubicControlPoints: [
      Point(x: 100, y: 25),
      Point(x: 10, y: 180),
      Point(x: 170, y: 165),
      Point(x: 65, y: 70)
    ],
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      draw.drawSkeleton(curve: curve);
      draw.drawCurve(curve: curve);
      for (final intersection in curve.selfIntersections) {
        draw.drawPoint(origin: curve.point(at: intersection.t1));
      }
      if (demoState.quadratic) {
        draw.drawText(
            text:
                "note: self-intersection not possible\nwith quadratic bezier curves",
            offset: Point(x: 15, y: 160));
      }
    });

// construct a line segment from start to end
final demo19 = Demo(
    title: ".intersections(with line: LineSegment)",
    quadraticControlPoints: [
      Point(x: 58, y: 173),
      Point(x: 26, y: 28),
      Point(x: 163, y: 104)
    ],
    cubicControlPoints: [
      Point(x: 53, y: 163),
      Point(x: 27, y: 19),
      Point(x: 182, y: 176),
      Point(x: 155, y: 36)
    ],
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      draw.drawSkeleton(curve: curve);
      draw.drawCurve(curve: curve);
      final line = LineSegment(
          p0: Point(x: 0.0, y: 175.0), p1: Point(x: 200.0, y: 25.0));
      draw.setColor(Draw.red);
      draw.drawLine(from: line.p0, to: line.p1);
      draw.setColor(Draw.black);
      for (final intersection in curve.intersectionsWithLine(line)) {
        draw.drawPoint(origin: curve.point(at: intersection.t1));
      }
    });

final demo20 = Demo(
    title: ".intersections(with curve: BezierCurve)",
    quadraticControlPoints: [
      Point(x: 0, y: 0),
      Point(x: 100, y: 187),
      Point(x: 166, y: 37)
    ],
    cubicControlPoints: [
      Point(x: 48, y: 84),
      Point(x: 104, y: 176),
      Point(x: 190, y: 37),
      Point(x: 121, y: 75)
    ],
    drawFunction: (canvas, demoState) {
      final draw = Draw(canvas);
      final curve = demoState.curve!;
      final curve2 = demoState.quadratic
          ? QuadraticCurve.fromList(points: [
              Point(x: 68.0, y: 150.0),
              Point(x: 74.0, y: 6.0),
              Point(x: 143.0, y: 150.0)
            ])
          : CubicCurve.fromList([
              Point(x: 68.0, y: 145.0),
              Point(x: 74.0, y: 6.0),
              Point(x: 143.0, y: 197.0),
              Point(x: 138.0, y: 55.0)
            ]);
      draw.drawSkeleton(curve: curve);
      draw.drawCurve(curve: curve);
      draw.setColor(Draw.red);
      draw.drawCurve(curve: curve2);
      draw.setColor(Draw.black);
      for (final intersection in curve.intersectionsWithCurve(curve2)) {
        draw.drawPoint(origin: curve.point(at: intersection.t1));
      }
    });

// final demo21 = Demo(
//     title: "Path interoperability",
//     quadraticControlPoints: [],
//     cubicControlPoints: [],
//     drawFunction: (canvas, demoState) {
//       final draw = Draw(canvas);
//       draw.reset();

//       var flip = AffineTransform.scale(scaleX: 1, y: -1);
//       final font = CTFontCreateWithName("Times" as CFString, 350, &flip);
//       final height = CTFontGetXHeight(font);
//       var translate = AffineTransform.translation(translationX: 0, y: -height + 15);

//       var unichar1 = "B";
//       var glyph1 = 0;
//       CTFontGetGlyphsForCharacters(font, &unichar1, &glyph1, 1);

//       var unichar2 = "K";
//       var glyph2 = 0;
//       CTFontGetGlyphsForCharacters(font, &unichar2, &glyph2, 1);

//       assert(glyph1 != 0 && glyph2 != 0, "couldn't get glyphs");

//       final cgPath1: Path = CTFontCreatePathForGlyph(font, glyph1, null)!;
//       var path1 = Path(cgPath: cgPath1.copy(using: &translate)!);
//       final mouse = demoState.lastInputLocation;
//       if (mouse != null) {
//         var translation =
//             AffineTransform.translation(translationX: mouse.x, y: mouse.y);
//         // final cgPath2: Path = CTFontCreatePathForGlyph(font, glyph2, &translation)!;
//         final path2 = Path(cgPath: cgPath2);
//         final subtracted = path1.intersect(path2);
//         draw.drawPath(subtracted);
//       }
//     });

final demo22 = Demo(
    title: "BoundingBoxHierarchy",
    quadraticControlPoints: [],
    cubicControlPoints: [],
    drawFunction: (canvas, _) {
      final draw = Draw(canvas);
      Point location(double angle) => Point(x: cos(angle), y: sin(angle)) * 200;
      const numPoints = 1000;
      const radiansPerPoint = 2.0 * pi / numPoints;
      final startingAngle = 0.0;
      final mutablePath = MutablePath();
      mutablePath.move(to: location(0.0));
      for (var i = 1; i < numPoints; i++) {
        final angle = i * radiansPerPoint + startingAngle;
        mutablePath.addLine(to: location(angle));
      }
      mutablePath.closeSubpath();

      final path = mutablePath.toPath();
      for (final s in path.components) {
        draw.drawPathComponent(
          pathComponent: s,
          offset: Point(x: 100.0, y: 100.0),
          includeBoundingVolumeHierarchy: true,
        );
      }
    });

final all = [
  demo1,
  demo2,
  demo3,
  demo4,
  demo5,
  demo6,
  demo7,
  demo8,
  demo9,
  demo10,
  demo11,
  demo12,
  demo13,
  demo14,
  demo15,
  demo16,
  demo17,
  demo18,
  demo19,
  demo20,
  //demo21,
  demo22,
];
