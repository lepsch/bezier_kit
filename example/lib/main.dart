// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'package:bezier_kit/bezier_kit.dart';
import 'package:example/demos.dart';
import 'package:example/draw.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bezier_kit Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _demoIndex = 0;
  final _draggables = all[0].cubicControlPoints.toList();
  var _useQuadratic = false;
  var _isPanning = false;
  Point? _lastInputLocation;

  void resetDraggables() {
    _draggables.clear();
    final demo = all[_demoIndex];
    (_useQuadratic ? demo.quadraticControlPoints : demo.cubicControlPoints)
        .forEach(_draggables.add);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("bezier_kit Flutter Demo"),
      ),
      body: ConstrainedBox(
        constraints: BoxConstraints.expand(),
        child: LayoutBuilder(builder: (context, constraints) {
          final dx = (constraints.maxWidth - intrinsicContentSize.width) / 2;
          final dy = (constraints.maxHeight - intrinsicContentSize.height) / 2;
          return MouseRegion(
            onExit: (event) => setState(() => _lastInputLocation = null),
            onHover: (event) => setState(
                () => _lastInputLocation = event.localPosition.toPoint()),
            child: Stack(
              children: [
                Container(
                  color: Colors.white,
                ),
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: Painter(
                    _demoIndex,
                    _draggables,
                    _useQuadratic,
                    _lastInputLocation,
                  ),
                ),
                for (final (i, draggable) in _draggables.indexed)
                  Positioned(
                      left: draggable.x + dx - draggableWidth / 2,
                      top: draggable.y + dy - draggableWidth / 2,
                      child: MouseRegion(
                        cursor: _isPanning
                            ? SystemMouseCursors.grabbing
                            : SystemMouseCursors.grab,
                        child: GestureDetector(
                          onPanStart: (_) => setState(() => _isPanning = true),
                          onPanEnd: (_) => setState(() => _isPanning = false),
                          onPanUpdate: (details) => setState(
                              () => _draggables[i] += details.delta.toPoint()),
                          child: Container(
                            width: 20,
                            height: 20,
                            color: Colors.transparent,
                          ),
                        ),
                      ))
              ],
            ),
          );
        }),
      ),
      bottomNavigationBar: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: const Text('Quadratic'),
                    leading: Radio<bool>(
                      value: true,
                      groupValue: _useQuadratic,
                      onChanged: (value) => setState(() {
                        _useQuadratic = value!;
                        resetDraggables();
                      }),
                    ),
                  ),
                  ListTile(
                    title: const Text('Cubic'),
                    leading: Radio<bool>(
                      value: false,
                      groupValue: _useQuadratic,
                      onChanged: (value) => setState(() {
                        _useQuadratic = value!;
                        resetDraggables();
                      }),
                    ),
                  ),
                ],
              ),
            ),
            DropdownButton<int>(
              value: _demoIndex,
              icon: const Icon(Icons.arrow_downward),
              onChanged: (value) {
                setState(() {
                  _demoIndex = value!;
                  resetDraggables();
                });
              },
              items: all.indexed
                  .map<DropdownMenuItem<int>>((demo) => DropdownMenuItem<int>(
                      value: demo.$1, child: Text(demo.$2.title)))
                  .toList(),
            )
          ],
        ),
      ),
    );
  }
}

class Painter extends CustomPainter {
  final int demoIndex;
  final bool useQuadratic;
  final List<Point> draggables;
  final Point? lastInputLocation;
  const Painter(this.demoIndex, this.draggables, this.useQuadratic,
      this.lastInputLocation);

  @override
  void paint(Canvas canvas, Size size) {
    final demo = all[demoIndex];

    // Center the curve
    final dx = (size.width - intrinsicContentSize.width) / 2;
    final dy = (size.height - intrinsicContentSize.height) / 2;
    canvas.translate(dx, dy);

    final curve = draggables.isNotEmpty
        ? useQuadratic
            ? QuadraticCurve.fromList(points: draggables)
            : CubicCurve.fromList(draggables)
        : null;

    demo.drawFunction(
      canvas,
      DemoState(
        lastInputLocation: lastInputLocation != null
            ? Point(x: lastInputLocation!.x - dx, y: lastInputLocation!.y - dy)
            : null,
        quadratic: useQuadratic,
        curve: curve,
      ),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

const intrinsicContentSize = Size(200, 210);
const draggableWidth = 20;
