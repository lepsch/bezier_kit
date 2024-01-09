import 'dart:math';

class AffineTransform {
  final double a, b, c, d;
  final double tx, ty;

  const AffineTransform({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.tx,
    required this.ty,
  });

  static const identity = AffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0);

  bool get isIdentity => this == AffineTransform.identity;

  static AffineTransform translation({
    required double translationX,
    required double y,
  }) {
    return AffineTransform(a: 1, b: 0, c: 0, d: 1, tx: translationX, ty: y);
  }

  static AffineTransform scale({required double scaleX, required double y}) {
    return AffineTransform(a: scaleX, b: 0, c: 0, d: y, tx: 0, ty: 0);
  }

  static AffineTransform rotation({required double rotationAngle}) {
    final cosAngle = cos(rotationAngle);
    final sinAngle = sin(rotationAngle);
    return AffineTransform(
        a: cosAngle, b: sinAngle, c: -sinAngle, d: cosAngle, tx: 0, ty: 0);
  }

  AffineTransform translatedBy({
    required double x,
    required double y,
  }) {
    final translate = AffineTransform.translation(translationX: x, y: y);
    return concatenating(translate);
  }

  AffineTransform scaledBy({
    required double x,
    required double y,
  }) {
    final scale = AffineTransform.scale(scaleX: x, y: y);
    return concatenating(scale);
  }

  AffineTransform rotatedBy(double angle) {
    final rotate = AffineTransform.rotation(rotationAngle: angle);
    return concatenating(rotate);
  }

  AffineTransform inverted() {
    final determinant = a * d - b * c;
    if (determinant == 0) return this;

    return AffineTransform(
      a: d / determinant,
      b: -b / determinant,
      c: -c / determinant,
      d: a / determinant,
      tx: (c * ty - d * tx) / determinant,
      ty: (b * tx - a * ty) / determinant,
    );
  }

  AffineTransform concatenating(AffineTransform other) {
    return AffineTransform(
      a: a * other.a + b * other.c,
      b: a * other.b + b * other.d,
      c: c * other.a + d * other.c,
      d: c * other.b + d * other.d,
      tx: tx * other.a + ty * other.c + other.tx,
      ty: tx * other.b + ty * other.d + other.ty,
    );
  }

  AffineTransform copy() {
    return AffineTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty);
  }

  @override
  bool operator ==(Object other) {
    if (other is AffineTransform) {
      return a == other.a &&
          b == other.b &&
          c == other.c &&
          d == other.d &&
          tx == other.tx &&
          ty == other.ty;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(a, b, c, d, tx, ty);

  @override
  String toString() {
    return 'AffineTransform(a: $a, b: $b, c: $c, d: $d, tx: $tx, ty: $ty)';
  }

  List<double> toList() {
    return [a, b, c, d, tx, ty];
  }
}
/*
CG_INLINE CGPoint
__CGPointApplyAffineTransform(CGPoint point, AffineTransform t)
{
  CGPoint p;
  p.x = (CGFloat)((double)t.a * point.x + (double)t.c * point.y + t.tx);
  p.y = (CGFloat)((double)t.b * point.x + (double)t.d * point.y + t.ty);
  return p;
}
#define CGPointApplyAffineTransform __CGPointApplyAffineTransform

CG_INLINE CGSize
__CGSizeApplyAffineTransform(CGSize size, AffineTransform t)
{
  CGSize s;
  s.width  = (CGFloat)((double)t.a * size.width + (double)t.c * size.height);
  s.height = (CGFloat)((double)t.b * size.width + (double)t.d * size.height);
  return s;
}
#define CGSizeApplyAffineTransform __CGSizeApplyAffineTransform
*/
