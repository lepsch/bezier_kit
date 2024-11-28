// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'dart:math';

import 'package:bezier_kit/bezier_kit.dart';
import 'package:bezier_kit/src/utils.dart';
import 'package:collection/collection.dart';

abstract interface class Implicitizeable {
  ImplicitPolynomial get implicitPolynomial;
}

/// represents an implicit polynomial, otherwise known as an algebraic curve.
/// The values on the polynomial are the zero set of the polynomial f(x, y) = 0
class ImplicitPolynomial {
  final List<double> _coefficients;

  final int _order;

  ImplicitPolynomial._fromLineProduct(_ImplicitLineProduct lineProduct)
      : _coefficients = [
          lineProduct.a00,
          lineProduct.a01,
          lineProduct.a02,
          lineProduct.a10,
          lineProduct.a11,
          0,
          lineProduct.a20,
          0,
          0
        ],
        _order = 2;

  ImplicitPolynomial._fromLine(_ImplicitLine line)
      : _coefficients = [line.a00, line.a01, line.a10, 0],
        _order = 1;

  ImplicitPolynomial._({required List<double> coefficients, required int order})
      : assert(coefficients.length == (order + 1) * (order + 1)),
        _coefficients = coefficients,
        _order = order;

  /// get the coefficient aij for x^i y^j
  double _coefficient(int i, int j) {
    assert(i >= 0 && i <= _order && j >= 0 && j <= _order);
    return _coefficients[(_order + 1) * i + j];
  }

  /// composes the implicit polynomial with a parametric polynomial whose coordinates are x(t) and y(t)
  /// the roots of the resulting polynomial are the intersection between the implicit and parametric polynomials
  BernsteinPolynomialN value<P extends BernsteinPolynomial>(P xt, P yt) {
    assert(xt.order == yt.order,
        "x and y coordinate polynomials must have same degree");
    final polynomialOrder = xt.order;
    final x = BernsteinPolynomialN(coefficients: xt.coefficients);
    final y = BernsteinPolynomialN(coefficients: yt.coefficients);
    var xPowers = [
      BernsteinPolynomialN(coefficients: [1])
    ];
    var yPowers = [
      BernsteinPolynomialN(coefficients: [1])
    ];
    for (var i = 1; i <= _order; i++) {
      xPowers.add(xPowers[i - 1] * x);
      yPowers.add(yPowers[i - 1] * y);
    }

    final resultOrder = _order * polynomialOrder;
    var sum =
        BernsteinPolynomialN(coefficients: List.filled(resultOrder + 1, 0.0));
    for (var i = 0; i <= _order; i++) {
      final xPower = xPowers[i];
      for (var j = 0; j <= _order; j++) {
        final c = _coefficient(i, j);
        if (c == 0) continue;

        final yPower = yPowers[j];

        final k = resultOrder - xPower.order - yPower.order;

        var term = (xPower * yPower);

        if (k > 0) {
          // bring the term up to degree k
          term *= BernsteinPolynomialN(coefficients: List.filled(k + 1, 1.0));
        } else {
          assert(k == 0, "for k < 0 we should have c == 0");
        }
        sum += term.mul(c);
      }
    }
    return sum;
  }

  double valueAt(Point at) {
    final x = at.x;
    final y = at.y;
    var sum = 0.0;
    for (var i = 0; i <= _order; i++) {
      for (var j = 0; j <= _order; j++) {
        sum += _coefficient(i, j) * pow(x, i) * pow(y, j);
      }
    }
    return sum;
  }

  ImplicitPolynomial operator +(ImplicitPolynomial right) {
    assert(_order == right._order);
    return ImplicitPolynomial._(
        coefficients: IterableZip([_coefficients, right._coefficients])
            .map((e) => e.sum)
            .toList(),
        order: _order);
  }

  ImplicitPolynomial operator -(ImplicitPolynomial right) {
    assert(_order == right._order);
    return ImplicitPolynomial._(
        coefficients: IterableZip([_coefficients, right._coefficients])
            .map((e) => e[0] - e[1])
            .toList(),
        order: _order);
  }
}

class _ImplicitLineProduct {
  double a20, a11, a10, a02, a01, a00;

  _ImplicitLineProduct(
      {required this.a20,
      required this.a11,
      required this.a10,
      required this.a02,
      required this.a01,
      required this.a00});

  ImplicitPolynomial operator *(_ImplicitLine left) {
    final a00 = left.a00 * this.a00;
    final a10 = left.a00 * this.a10 + left.a10 * this.a00;
    final a20 = left.a10 * this.a10 + left.a00 * this.a20;
    final a30 = left.a10 * this.a20;

    final a01 = left.a01 * this.a00 + left.a00 * this.a01;
    final a11 = left.a10 * this.a01 + left.a00 * this.a11 + left.a01 * this.a10;
    final a21 = left.a01 * this.a20 + left.a10 * this.a11;
    final a31 = 0.0;

    final a02 = left.a01 * this.a01 + left.a00 * this.a02;
    final a12 = left.a10 * this.a02 + left.a01 * this.a11;
    final a22 = 0.0;
    final a32 = 0.0;

    final a03 = left.a01 * this.a02;
    final a13 = 0.0;
    final a23 = 0.0;
    final a33 = 0.0;

    return ImplicitPolynomial._(coefficients: [
      a00,
      a01,
      a02,
      a03,
      a10,
      a11,
      a12,
      a13,
      a20,
      a21,
      a22,
      a23,
      a30,
      a31,
      a32,
      a33
    ], order: 3);
  }

  _ImplicitLineProduct operator -(_ImplicitLineProduct other) {
    return _ImplicitLineProduct(
        a20: a20 - other.a20,
        a11: a11 - other.a11,
        a10: a10 - other.a10,
        a02: a02 - other.a02,
        a01: a01 - other.a01,
        a00: a00 - other.a00);
  }
}

class _ImplicitLine {
  double a10, a01, a00;

  _ImplicitLine({required this.a10, required this.a01, required this.a00});

  _ImplicitLineProduct operator *(_ImplicitLine other) {
    return _ImplicitLineProduct(
        a20: a10 * other.a10,
        a11: a01 * other.a10 + a10 * other.a01,
        a10: a10 * other.a00 + a00 * other.a10,
        a02: a01 * other.a01,
        a01: a01 * other.a00 + a00 * other.a01,
        a00: a00 * other.a00);
  }

  _ImplicitLine mul(double other) {
    return _ImplicitLine(a10: other * a10, a01: other * a01, a00: other * a00);
  }

  _ImplicitLine operator +(_ImplicitLine right) {
    return _ImplicitLine(
        a10: a10 + right.a10, a01: a01 + right.a01, a00: a00 + right.a00);
  }
}

extension on BezierCurve {
  _ImplicitLine l(int i, int j) {
    final n = order;
    final pi = points[i];
    final pj = points[j];
    final b = Utils.binomialCoefficient(n, choose: i) *
        Utils.binomialCoefficient(n, choose: j);
    return _ImplicitLine(
            a10: pi.y - pj.y, a01: pj.x - pi.x, a00: pi.x * pj.y - pj.x * pi.y)
        .mul(b);
  }
}

mixin LineSegmentImplicitizationMixin on LineSegmentBase
    implements Implicitizeable {
  @override
  ImplicitPolynomial get implicitPolynomial {
    return ImplicitPolynomial._fromLine(l(0, 1));
  }
}

mixin QuadraticCurveImplicitizationMixin on QuadraticCurveBase
    implements Implicitizeable {
  @override
  ImplicitPolynomial get implicitPolynomial {
    final l20 = l(2, 0);
    final l21 = l(2, 1);
    final l10 = l(1, 0);
    final lineProduct = l21 * l10 - l20 * l20;
    return ImplicitPolynomial._fromLineProduct(lineProduct);
  }
}

mixin CubicCurveImplicitizationMixin on CubicCurveBase
    implements Implicitizeable {
  @override
  ImplicitPolynomial get implicitPolynomial {
    final l32 = l(3, 2);
    final l31 = l(3, 1);
    final l30 = l(3, 0);
    final l21 = l(2, 1);
    final l20 = l(2, 0);
    final l10 = l(1, 0);
    final m00 = l32;
    final m01 = l31;
    final m02 = l30;
    final m10 = l31;
    final m11 = l30 + l21;
    final m12 = l20;
    final m20 = l30;
    final m21 = l20;
    final m22 = l10;
    return (m11 * m22 - m12 * m21) * m00 -
        (m10 * m22 - m12 * m20) * m01 +
        (m10 * m21 - m11 * m20) * m02;
  }
}
