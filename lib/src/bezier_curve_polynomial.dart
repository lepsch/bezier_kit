//
//  BezierCurve+Polynomial.swift
//  BezierKit
//
//  Created by Holmes Futrell on 1/22/21.
//  Copyright © 2021 Holmes Futrell. All rights reserved.
//

import 'package:bezier_kit/bezier_kit.dart';

/// a parametric function whose x and y coordinates can be considered as separate polynomial functions
/// eg `f(t) = (xPolynomial(t), yPolynomial(t))`
abstract interface class ComponentPolynomials<
    Polynomial extends BernsteinPolynomial> {
  Polynomial get xPolynomial;
  Polynomial get yPolynomial;
}

mixin LineSegmentPolynomialMixin on LineSegmentBase
    implements ComponentPolynomials {
  @override
  BernsteinPolynomial1 get xPolynomial {
    return BernsteinPolynomial1(b0: p0.x, b1: p1.x);
  }

  @override
  BernsteinPolynomial1 get yPolynomial {
    return BernsteinPolynomial1(b0: p0.y, b1: p1.y);
  }
}

mixin QuadraticCurvePolynomialMixin on QuadraticCurveBase
    implements ComponentPolynomials {
  @override
  BernsteinPolynomial2 get xPolynomial {
    return BernsteinPolynomial2(b0: p0.x, b1: p1.x, b2: p2.x);
  }

  @override
  BernsteinPolynomial2 get yPolynomial {
    return BernsteinPolynomial2(b0: p0.y, b1: p1.y, b2: p2.y);
  }
}

mixin CubicCurvePolynomialMixin on CubicCurveBase
    implements ComponentPolynomials {
  @override
  BernsteinPolynomial3 get xPolynomial {
    return BernsteinPolynomial3(b0: p0.x, b1: p1.x, b2: p2.x, b3: p3.x);
  }

  @override
  BernsteinPolynomial3 get yPolynomial {
    return BernsteinPolynomial3(b0: p0.y, b1: p1.y, b2: p2.y, b3: p3.y);
  }
}

//  where Self: ComponentPolynomials
// extension on BezierCurve {
// }
