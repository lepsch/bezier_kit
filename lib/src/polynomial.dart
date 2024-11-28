//
//  Polynomial.swift
//  BezierKit
//
//  Created by Holmes Futrell on 5/15/20.
//  Copyright © 2020 Holmes Futrell. All rights reserved.
//

import 'package:bezier_kit/src/utils.dart';
import 'package:collection/collection.dart';

abstract class BernsteinPolynomial<NextLowerOrderPolynomial> {
  const BernsteinPolynomial();

  double value({required double at}) {
    final oneMinusX = 1.0 - at;
    return reduce(a1: oneMinusX, a2: at);
  }

  int get order;
  List<double> get coefficients;

  /// a polynomial of the next lower order where each coefficient `b[i]` is defined by `a1 * b[i] + a2 * b[i+1]`
  NextLowerOrderPolynomial difference({required double a1, required double a2});

  /// reduces the polynomial by repeatedly applying `difference` until left with a constant value
  double reduce({required double a1, required double a2}) {
    return (difference(a1: a1, a2: a2) as BernsteinPolynomial)
        .reduce(a1: a1, a2: a2);
  }

  NextLowerOrderPolynomial get derivative {
    final order = this.order.toDouble();
    return difference(a1: -order, a2: order);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is BernsteinPolynomial) {
      return order == other.order &&
          ListEquality().equals(coefficients, other.coefficients);
    }
    return false;
  }

  @override
  int get hashCode {
    return Object.hashAll([order, ...coefficients]);
  }
}

abstract interface class AnalyticalRoots {
  List<double> distinctAnalyticalRoots({
    required double between,
    required double and,
  });
}

class BernsteinPolynomial0 extends BernsteinPolynomial<BernsteinPolynomial>
    implements AnalyticalRoots {
  final double b0;

  const BernsteinPolynomial0({required this.b0});

  @override
  List<double> get coefficients => [b0];

  @override
  double value({required double at}) => b0;

  @override
  int get order => 0;

  @override
  double reduce({required double a1, required double a2}) => 0.0;

  @override
  BernsteinPolynomial0 difference({required double a1, required double a2}) {
    return BernsteinPolynomial0(b0: 0.0);
  }

  @override
  List<double> distinctAnalyticalRoots({
    required double between,
    required double and,
  }) {
    return [];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is BernsteinPolynomial0) {
      return b0 == other.b0 && super == other;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(b0, super.hashCode);
}

class BernsteinPolynomial1 extends BernsteinPolynomial<BernsteinPolynomial0>
    implements AnalyticalRoots {
  final double b0, b1;

  const BernsteinPolynomial1({required this.b0, required this.b1});

  @override
  List<double> get coefficients => [b0, b1];

  @override
  double reduce({required double a1, required double a2}) => a1 * b0 + a2 * b1;

  @override
  BernsteinPolynomial0 difference({required double a1, required double a2}) {
    return BernsteinPolynomial0(b0: reduce(a1: a1, a2: a2));
  }

  @override
  int get order => 1;

  @override
  List<double> distinctAnalyticalRoots({
    required double between,
    required double and,
  }) {
    final result = <double>[];
    Utils.droots(b0, b1, callback: ($0) {
      if ($0 < between || $0 > and) return;
      result.add($0);
    });
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is BernsteinPolynomial1) {
      return b0 == other.b0 && b1 == other.b1 && super == other;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(b0, b1, super.hashCode);
}

class BernsteinPolynomial2 extends BernsteinPolynomial<BernsteinPolynomial1>
    implements AnalyticalRoots {
  final double b0, b1, b2;

  const BernsteinPolynomial2({
    required this.b0,
    required this.b1,
    required this.b2,
  });

  @override
  List<double> get coefficients => [b0, b1, b2];

  @override
  BernsteinPolynomial1 difference({required double a1, required double a2}) {
    return BernsteinPolynomial1(b0: a1 * b0 + a2 * b1, b1: a1 * b1 + a2 * b2);
  }

  @override
  int get order => 2;

  @override
  List<double> distinctAnalyticalRoots(
      {required double between, required double and}) {
    final result = <double>[];
    Utils.droots3(b0, b1, b2, callback: ($0) {
      if ($0 < between || $0 > and) return;
      result.add($0);
    });
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is BernsteinPolynomial2) {
      return b0 == other.b0 &&
          b1 == other.b1 &&
          b2 == other.b2 &&
          super == other;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(b0, b1, b2, super.hashCode);
}

class BernsteinPolynomial3 extends BernsteinPolynomial<BernsteinPolynomial2>
    implements AnalyticalRoots {
  final double b0, b1, b2, b3;
  BernsteinPolynomial3(
      {required this.b0, required this.b1, required this.b2, required this.b3});

  @override
  List<double> get coefficients => [b0, b1, b2, b3];

  @override
  BernsteinPolynomial2 difference({required double a1, required double a2}) {
    return BernsteinPolynomial2(
      b0: a1 * b0 + a2 * b1,
      b1: a1 * b1 + a2 * b2,
      b2: a1 * b2 + a2 * b3,
    );
  }

  @override
  int get order => 3;

  @override
  List<double> distinctAnalyticalRoots(
      {required double between, required double and}) {
    final result = <double>[];
    Utils.droots4(b0, b1, b2, b3, callback: ($0) {
      if ($0 < between || $0 > and) return;
      result.add($0);
    });
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is BernsteinPolynomial3) {
      return b0 == other.b0 &&
          b1 == other.b1 &&
          b2 == other.b2 &&
          b3 == other.b3 &&
          super == other;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(b0, b1, b2, b3, super.hashCode);
}

class BernsteinPolynomial4 extends BernsteinPolynomial<BernsteinPolynomial3> {
  final double b0, b1, b2, b3, b4;
  BernsteinPolynomial4({
    required this.b0,
    required this.b1,
    required this.b2,
    required this.b3,
    required this.b4,
  });

  @override
  List<double> get coefficients => [b0, b1, b2, b3, b4];

  @override
  BernsteinPolynomial3 difference({required double a1, required double a2}) {
    return BernsteinPolynomial3(
      b0: a1 * b0 + a2 * b1,
      b1: a1 * b1 + a2 * b2,
      b2: a1 * b2 + a2 * b3,
      b3: a1 * b3 + a2 * b4,
    );
  }

  @override
  int get order => 4;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is BernsteinPolynomial4) {
      return b0 == other.b0 &&
          b1 == other.b1 &&
          b2 == other.b2 &&
          b3 == other.b3 &&
          b4 == other.b4 &&
          super == other;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(b0, b1, b2, b3, b4, super.hashCode);
}

class BernsteinPolynomial5 extends BernsteinPolynomial<BernsteinPolynomial4> {
  final double b0, b1, b2, b3, b4, b5;
  BernsteinPolynomial5({
    required this.b0,
    required this.b1,
    required this.b2,
    required this.b3,
    required this.b4,
    required this.b5,
  });

  @override
  List<double> get coefficients => [b0, b1, b2, b3, b4, b5];

  @override
  BernsteinPolynomial4 difference({required double a1, required double a2}) {
    return BernsteinPolynomial4(
      b0: a1 * b0 + a2 * b1,
      b1: a1 * b1 + a2 * b2,
      b2: a1 * b2 + a2 * b3,
      b3: a1 * b3 + a2 * b4,
      b4: a1 * b4 + a2 * b5,
    );
  }

  @override
  int get order => 5;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is BernsteinPolynomial5) {
      return b0 == other.b0 &&
          b1 == other.b1 &&
          b2 == other.b2 &&
          b3 == other.b3 &&
          b4 == other.b4 &&
          b5 == other.b5 &&
          super == other;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(b0, b1, b2, b3, b4, b5, super.hashCode);
}

double _newton<P extends BernsteinPolynomial>({
  required P polynomial,
  required P derivative,
  required double guess,
  double relaxation = 1,
}) {
  const maxIterations = 20;
  var x = guess;
  for (final _ in Iterable.generate(maxIterations)) {
    final f = polynomial.value(at: x);
    if (f == 0.0) break;
    final fPrime = derivative.value(at: x);
    final delta = relaxation * f / fPrime;
    final previous = x;
    x -= delta;
    if ((x - previous).abs() <= 1.0e-10) break;
  }
  return x;
}

double _findRootBisection<P extends BernsteinPolynomial>({
  required P of,
  required double between,
  required double and,
}) {
  var guess = (between + and) / 2;
  var low = between;
  var high = and;
  final lowSign = of.value(at: low).sign;
  final highSign = of.value(at: high).sign;
  assert(lowSign != highSign);
  final maxIterations = 20;
  var iterations = 0;
  while (high - low > 1.0e-5) {
    final midGuess = (low + high) / 2;
    guess = midGuess;
    final nextGuessF = of.value(at: guess);
    if (nextGuessF == 0) {
      return guess;
    } else if (nextGuessF.sign == lowSign) {
      low = guess;
    } else {
      assert(nextGuessF.sign == highSign);
      high = guess;
    }
    iterations += 1;
    if (iterations >= maxIterations) break;
  }
  return guess;
}

List<double> findDistinctRootsInUnitInterval<P extends BernsteinPolynomial>({
  required P of,
}) {
  return findDistinctRoots(of: of, between: 0, and: 1);
}

List<double> findDistinctRoots<P extends BernsteinPolynomial>({
  required P of,
  required double between,
  required double and,
}) {
  assert(between < and);
  if (of is AnalyticalRoots) {
    return (of as AnalyticalRoots)
        .distinctAnalyticalRoots(between: between, and: and);
  }
  final derivative = of.derivative as BernsteinPolynomial;
  final List<double> criticalPoints =
      findDistinctRoots(of: derivative, between: between, and: and);
  final List<double> intervals = [between] + criticalPoints + [and];
  double? lastFoundRoot;
  return Iterable<int>.generate(intervals.length - 1)
      .map((i) {
        final between = intervals[i];
        final and = intervals[i + 1];
        final fStart = of.value(at: between);
        final fEnd = of.value(at: and);
        final double root;
        if (fStart * fEnd < 0) {
          // TODO: if a critical point is a root we take this
          // codepath due to roundoff and  converge only linearly to one and of interval
          final guess = (between + and) / 2;
          final newtonRoot =
              _newton(polynomial: of, derivative: derivative, guess: guess);
          if (between < newtonRoot && newtonRoot < and) {
            root = newtonRoot;
          } else {
            // _newton's method failed / converged to the wrong root!
            // rare, but can happen roughly 5% of the time
            // see unit test: `testDegree4RealWorldIssue`
            root = _findRootBisection(of: of, between: between, and: and);
          }
        } else {
          final guess = and;
          final value =
              _newton(polynomial: of, derivative: derivative, guess: guess);
          if ((value - guess).abs() >= 1.0e-5) {
            return null; // did not converge near guess
          }
          if (of.value(at: value).abs() >= 1.0e-10) {
            return null; // not actually a root
          }
          root = value;
        }
        if (lastFoundRoot != null) {
          if (lastFoundRoot! + 1.0e-5 >= root) {
            return null; // ensures roots are unique and ordered
          }
        }
        lastFoundRoot = root;
        return root;
      })
      .nonNulls
      .toList();
}
