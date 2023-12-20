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

  // Point transformPoint(Point point) {
  //   return Point(
  //       x: a * point.x + c * point.y + tx, y: b * point.x + d * point.y + ty);
  // }

  // Point transformPointInverse(Point point) {
  //   final determinant = a * d - b * c;
  //   return Point(
  //       x: (d * point.x - c * point.y + c * ty - d * tx) / determinant,
  //       y: (-b * point.x + a * point.y - a * ty + b * tx) / determinant);
  // }

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

  // static AffineTransform fromList(List<double> list) {
  //   return AffineTransform(
  //     a: list[0],
  //     b: list[1],
  //     c: list[2],
  //     d: list[3],
  //     tx: list[4],
  //     ty: list[5],
  //   );
  // }

  List<double> toList() {
    return [a, b, c, d, tx, ty];
  }
}
/*










/* functions */
CG_EXTERN CGAffineTransform CGAffineTransformMake (
	CGFloat a, CGFloat b,
	CGFloat c, CGFloat d, CGFloat tx, CGFloat ty);

CG_EXTERN CGAffineTransform CGAffineTransformMakeRotation(CGFloat angle);

CG_EXTERN CGAffineTransform CGAffineTransformMakeScale(CGFloat sx, CGFloat sy);

CG_EXTERN CGAffineTransform CGAffineTransformMakeTranslation(CGFloat tx, CGFloat ty);

/* Modifying Affine Transformations */
CG_EXTERN CGAffineTransform CGAffineTransformTranslate(CGAffineTransform t,
CGFloat tx, CGFloat ty);

CG_EXTERN CGAffineTransform CGAffineTransformScale(CGAffineTransform t,
  CGFloat sx, CGFloat sy);

CG_EXTERN CGAffineTransform CGAffineTransformRotate(CGAffineTransform t,
  CGFloat angle);

CG_EXTERN CGAffineTransform CGAffineTransformInvert(CGAffineTransform t);

CG_EXTERN CGAffineTransform CGAffineTransformConcat(CGAffineTransform t1,
  CGAffineTransform t2);

/* Applying Affine Transformations */

CG_EXTERN bool CGAffineTransformEqualToTransform(CGAffineTransform t1,
  CGAffineTransform t2);


CG_EXTERN CGPoint CGPointApplyAffineTransform(CGPoint point,
  CGAffineTransform t);


CG_EXTERN CGSize CGSizeApplyAffineTransform(CGSize size, CGAffineTransform t);


CG_EXTERN CGRect CGRectApplyAffineTransform(CGRect rect, CGAffineTransform t);

/* Evaluating Affine Transforms */

CG_EXTERN bool CGAffineTransformIsIdentity(CGAffineTransform t);

/* inline functions */
CG_INLINE CGAffineTransform __CGAffineTransformMake(CGFloat a, CGFloat b,
 CGFloat c, CGFloat d, CGFloat tx, CGFloat ty)
{
  CGAffineTransform at;
  at.a = a; at.b = b; at.c = c; at.d = d;
  at.tx = tx; at.ty = ty;
  return at;
}
#define CGAffineTransformMake __CGAffineTransformMake

CG_INLINE CGPoint
__CGPointApplyAffineTransform(CGPoint point, CGAffineTransform t)
{
  CGPoint p;
  p.x = (CGFloat)((double)t.a * point.x + (double)t.c * point.y + t.tx);
  p.y = (CGFloat)((double)t.b * point.x + (double)t.d * point.y + t.ty);
  return p;
}
#define CGPointApplyAffineTransform __CGPointApplyAffineTransform

CG_INLINE CGSize
__CGSizeApplyAffineTransform(CGSize size, CGAffineTransform t)
{
  CGSize s;
  s.width  = (CGFloat)((double)t.a * size.width + (double)t.c * size.height);
  s.height = (CGFloat)((double)t.b * size.width + (double)t.d * size.height);
  return s;
}
#define CGSizeApplyAffineTransform __CGSizeApplyAffineTransform
*/
