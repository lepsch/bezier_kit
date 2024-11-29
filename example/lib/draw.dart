// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'package:bezier_kit/bezier_kit.dart' hide Path;
import 'package:example/demos.dart';
import 'package:flutter/material.dart';

extension OffsetPointExtension on Offset {
  Point toPoint() => Point(x: dx, y: dy);
}

class Draw {
  final Canvas canvas;
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  Paint? fill;
  Draw(this.canvas);

  // some useful hard-coded colors
  static const lightGrey = Color.fromRGBO(211, 211, 211, 1.0);
  static const black = Color.fromRGBO(0, 0, 0, 1.0);
  static const red = Color.fromRGBO(255, 0, 0, 1.0);
  static const pinkish = Color.fromRGBO(255, 100, 100, 1.0);
  static const transparentBlue = Color.fromRGBO(0, 0, 255, 0.3);
  static const transparentBlack = Color.fromRGBO(0, 0, 0, 0.2);
  static const blue = Color.fromRGBO(0, 0, 255, 1.0);
  static const green = Color.fromRGBO(0, 255, 0, 1.0);

  static var randomIndex = 0;
  static final randomColors = () {
    var temp = <Color>[];
    for (var i = 0; i < 360; i++) {
      final j = (i * 47) % 360;
      temp.add(HSLColor.fromAHSL(1, j.toDouble(), 0.5, 0.5).toColor());
    }
    return temp;
  }();

  void reset() {
    stroke.color = black;
    randomIndex = 0;
  }

  // setting colors

  void setRandomColor() {
    randomIndex = (randomIndex + 1) % randomColors.length;
    final c = randomColors[randomIndex];
    stroke.color = c;
  }

  void setRandomFill({double alpha = 1.0}) {
    randomIndex = (randomIndex + 1) % randomColors.length;
    final c = randomColors[randomIndex];
    final c2 = c.withOpacity(alpha);
    fill = Paint()
      ..color = c2
      ..style = PaintingStyle.fill;
  }

  void setColor(Color color) {
    stroke.color = color;
  }

  // drawing various geometry

  void drawCurve({required BezierCurve curve, Point offset = Point.zero}) {
    if (curve case QuadraticCurve(:final p0, :final p1, :final p2)) {
      final from = p0 + offset;
      final to = p2 + offset;
      final control = p1 + offset;
      final path = Path()
        ..moveTo(from.x, from.y)
        ..quadraticBezierTo(control.x, control.y, to.x, to.y);
      canvas.drawPath(path, stroke);
    } else if (curve
        case CubicCurve(:final p0, :final p1, :final p2, :final p3)) {
      final from = p0 + offset;
      final to = p3 + offset;
      final control1 = p1 + offset;
      final control2 = p2 + offset;
      final path = Path()
        ..moveTo(from.x, from.y)
        ..cubicTo(control1.x, control1.y, control2.x, control2.y, to.x, to.y);
      canvas.drawPath(path, stroke);
    } else if (curve case LineSegment(:final p0, :final p1)) {
      canvas.drawLine(
          (p0 + offset).toOffset(), (p1 + offset).toOffset(), stroke);
    } else {
      throw UnsupportedError("unsupported curve type");
    }
  }

  void drawCircle({
    required Point center,
    required double radius,
    Point offset = Point.zero,
  }) {
    final c = Point(x: center.x + offset.x, y: center.y + offset.y).toOffset();
    canvas.drawOval(
        Rect.fromCenter(center: c, width: 2 * radius, height: 2 * radius),
        stroke);
  }

  void drawPoint({required Point origin, Point offset = Point.zero}) {
    drawCircle(center: origin, radius: 5.0, offset: offset);
  }

  void drawPoints(List<Point> points, {Point offset = Point.zero}) {
    for (final p in points) {
      drawCircle(center: p, radius: 3.0, offset: offset);
    }
  }

  void drawLine(
      {required Point from, required Point to, Point offset = Point.zero}) {
    final p1 = (from + offset).toOffset();
    final p2 = (to + offset).toOffset();
    canvas.drawLine(p1, p2, stroke);
  }

  void drawText({required String text, Point offset = Point.zero}) {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: TextStyle(fontSize: 12)),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: 100 - 12.0 - 12.0);
    textPainter.paint(canvas, offset.toOffset());
  }

  void drawSkeleton({
    required BezierCurve curve,
    Point offset = Point.zero,
    bool coords = true,
  }) {
    stroke.color = lightGrey;

    switch (curve) {
      case CubicCurve(:final p0, :final p1, :final p2, :final p3):
        drawLine(from: p0, to: p1, offset: offset);
        drawLine(from: p2, to: p3, offset: offset);
        break;
      case QuadraticCurve(:final p0, :final p1, :final p2):
        drawLine(from: p0, to: p1, offset: offset);
        drawLine(from: p1, to: p2, offset: offset);
        break;
      case ImplicitizeableBezierCurve():
        break;
      case BezierCurveIntersectionMixin():
        break;
    }

    if (coords) {
      stroke.color = black;
      drawPoints(curve.points, offset: offset);
    }
  }

  void drawHull({required List<Point> hull, Point offset = Point.zero}) {
    final path = Path();
    if (hull.length == 6) {
      path.moveTo(hull[0].x, hull[0].y);
      path.lineTo(hull[1].x, hull[1].y);
      path.lineTo(hull[2].x, hull[2].y);
      path.moveTo(hull[3].x, hull[3].y);
      path.lineTo(hull[4].x, hull[4].y);
    } else {
      path.moveTo(hull[0].x, hull[0].y);
      path.lineTo(hull[1].x, hull[1].y);
      path.lineTo(hull[2].x, hull[2].y);
      path.lineTo(hull[3].x, hull[3].y);
      path.moveTo(hull[4].x, hull[4].y);
      path.lineTo(hull[5].x, hull[5].y);
      path.lineTo(hull[6].x, hull[6].y);
      path.moveTo(hull[7].x, hull[7].y);
      path.lineTo(hull[8].x, hull[8].y);
    }
    canvas.drawPath(path, stroke);
  }

  void drawBoundingBox(
      {required BoundingBox boundingBox, Point offset = Point.zero}) {
    canvas.drawRect(
      Rect.fromLTRB(
        boundingBox.min.x + offset.x,
        boundingBox.min.y + offset.y,
        boundingBox.max.x + offset.x,
        boundingBox.max.y + offset.y,
      ),
      stroke,
    );
  }

  void drawShape({required Shape shape, Point offset = Point.zero}) {
    final order = shape.forward.points.length - 1;
    final path = Path();
    path.moveTo(offset.x + shape.startcap.curve.startingPoint.x,
        offset.y + shape.startcap.curve.startingPoint.y);
    path.lineTo(offset.x + shape.startcap.curve.endingPoint.x,
        offset.y + shape.startcap.curve.endingPoint.y);
    if (order == 3) {
      final control1 = offset + shape.forward.points[1];
      final control2 = offset + shape.forward.points[2];
      final to = offset + shape.forward.points[3];
      path.cubicTo(
        control1.x,
        control1.y,
        control2.x,
        control2.y,
        to.x,
        to.y,
      );
    } else {
      final control = offset + shape.forward.points[1];
      final to = offset + shape.forward.points[2];
      path.quadraticBezierTo(
        control.x,
        control.y,
        to.x,
        to.y,
      );
    }
    path.lineTo(offset.x + shape.endcap.curve.endingPoint.x,
        offset.y + shape.endcap.curve.endingPoint.y);
    if (order == 3) {
      final control1 = offset + shape.back.points[1];
      final control2 = offset + shape.back.points[2];
      final to = offset + shape.back.points[3];
      path.cubicTo(
        control1.x,
        control1.y,
        control2.x,
        control2.y,
        to.x,
        to.y,
      );
    } else {
      final to = offset + shape.back.points[2];
      final control = offset + shape.back.points[1];
      path.quadraticBezierTo(
        to.x,
        to.y,
        control.x,
        control.y,
      );
    }
    if (fill != null) canvas.drawPath(path, fill!);
    canvas.drawPath(path, stroke);
  }

  void drawPathComponent({
    required PathComponent pathComponent,
    Point offset = Point.zero,
    bool includeBoundingVolumeHierarchy = false,
  }) {
    if (includeBoundingVolumeHierarchy) {
      pathComponent.bvh.visit((node, depth) {
        setColor(randomColors[depth]);
        stroke.strokeWidth = 5 / (depth + 1);
        stroke.color = stroke.color.withOpacity(1 / (depth + 1));
        drawBoundingBox(boundingBox: node.boundingBox, offset: offset);
        return true; // always visit children
      });
    }
    setRandomFill(alpha: 0.2);
    stroke.color = fill!.color;
    stroke.style = fill!.style;
    for (var i = 0; i < pathComponent.numberOfElements; i++) {
      final curve = pathComponent.element(at: i);
      drawCurve(curve: curve, offset: offset);
    }
  }

//     void drawPath( _ path: Path, offset: Point = .zero) {
//         Draw.setRandomFill(context, alpha: 0.2)
//         context.addPath(path.cgPath)
//         context.drawPath(using: .fillStroke)
//     }
}
