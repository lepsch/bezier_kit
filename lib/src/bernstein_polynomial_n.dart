// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'dart:math';

import 'package:bezier_kit/src/polynomial.dart';
import 'package:bezier_kit/src/utils.dart';
import 'package:collection/collection.dart';

class BernsteinPolynomialN extends BernsteinPolynomial {
  @override
  final List<double> coefficients;

  @override
  BernsteinPolynomialN difference({required double a1, required double a2}) {
    throw Exception("unimplemented.");
  }

  @override
  int get order => coefficients.length - 1;

  BernsteinPolynomialN({required this.coefficients})
      : assert(coefficients.isNotEmpty,
            "Bezier curves require at least one point");

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BernsteinPolynomialN) return false;
    return ListEquality().equals(coefficients, other.coefficients);
  }

  @override
  int get hashCode {
    return Object.hashAll(coefficients);
  }

  BernsteinPolynomialN reversed() {
    return BernsteinPolynomialN(coefficients: coefficients.reversed.toList());
  }

  @override
  BernsteinPolynomialN get derivative {
    if (order <= 0) {
      return BernsteinPolynomialN(coefficients: [0.0]);
    }
    return _hodograph.mul(order.toDouble());
  }

  BernsteinPolynomialN mul(double scalar) {
    return BernsteinPolynomialN(
        coefficients: coefficients.map(($0) => scalar * $0).toList());
  }

  @override
  double value({required double at}) {
    return splitAt(at).left.coefficients.last;
  }

  BernsteinPolynomialN get _hodograph {
    assert(order > 0);
    final differences = Iterable.generate(order)
        .map(($0) => coefficients[$0 + 1] - coefficients[$0])
        .toList();
    return BernsteinPolynomialN(coefficients: differences);
  }

  ({BernsteinPolynomialN left, BernsteinPolynomialN right}) splitAt(double at) {
    if (order <= 0) {
      // splitting a point results in getting a point back
      return (left: this, right: this);
    }
    // apply de Casteljau Algorithm
    var leftPoints = List.filled(coefficients.length, 0.0);
    var rightPoints = List.filled(coefficients.length, 0.0);
    final n = order;
    var scratchPad = [...coefficients];
    leftPoints[0] = scratchPad[0];
    rightPoints[n] = scratchPad[n];
    for (var j = 1; j <= n; j++) {
      for (var i = 0; i <= n - j; i++) {
        scratchPad[i] =
            Utils.linearInterpolateF(scratchPad[i], scratchPad[i + 1], at);
      }
      leftPoints[j] = scratchPad[0];
      rightPoints[n - j] = scratchPad[n - j];
    }
    return (
      left: BernsteinPolynomialN(coefficients: leftPoints),
      right: BernsteinPolynomialN(coefficients: rightPoints),
    );
  }

  BernsteinPolynomialN split({required double from, required double to}) {
    if (from > to) {
      // simplifying to from <= to would infinite loop on NaN because NaN comparisons are always false
      return split(from: to, to: from).reversed();
    }
    if (from == 0) return splitAt(to).left;
    final right = splitAt(from).right;
    if (to == 1) return right;
    final t2MappedToRight = (to - from) / (1 - from);
    return right.splitAt(t2MappedToRight).left;
  }

  BernsteinPolynomialN operator +(BernsteinPolynomialN other) {
    assert(order == other.order,
        "curves must have equal degree (unless we support upgrading degrees, which we don't here)");
    return BernsteinPolynomialN(
        coefficients: IterableZip([coefficients, other.coefficients])
            .map((e) => e.sum)
            .toList());
  }

  BernsteinPolynomialN operator *(BernsteinPolynomialN other) {
    // the polynomials are multiplied in Bernstein form, which is a little different
    // from normal polynomial multiplication. For a discussion of how this works see
    // "Computer Aided Geometric Design" by T.W. Sederberg,
    // 9.3 Multiplication of Polynomials in Bernstein Form
    final m = order;
    final n = other.order;
    final points = Iterable<int>.generate(m + n + 1).map((k) {
      final start = max(k - n, 0);
      final end = min(m, k);
      var sum = 0.0;
      for (int i = start; i <= end; i++) {
        final j = k - i;
        sum += Utils.binomialCoefficient(m, choose: i) *
            Utils.binomialCoefficient(n, choose: j) *
            coefficients[i] *
            other.coefficients[j];
      }
      final divisor = Utils.binomialCoefficient(m + n, choose: k);
      return sum / divisor;
    });
    return BernsteinPolynomialN(coefficients: points.toList());
  }
}
