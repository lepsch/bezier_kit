import 'package:bezier_kit/src/bezier_curve.dart';
import 'package:bezier_kit/src/utils.dart';

class Subcurve<CurveType extends BezierCurve> {
  final double t1;
  final double t2;
  final CurveType curve;

  bool get canSplit {
    final mid = 0.5 * (this.t1 + this.t2);
    return mid > this.t1 && mid < this.t2;
  }

  Subcurve.fromCurve(this.curve)
      : t1 = 0.0,
        t2 = 1.0;

  Subcurve({required this.t1, required this.t2, required this.curve});

  Subcurve<CurveType> split({required double from, required double to}) {
    final curve = this.curve.split(from: from, to: to);
    return Subcurve<CurveType>(
      t1: Utils.map(from, 0, 1, this.t1, this.t2),
      t2: Utils.map(to, 0, 1, this.t1, this.t2),
      curve: curve as CurveType,
    );
  }

  ({Subcurve<CurveType> left, Subcurve<CurveType> right}) splitAt(double at) {
    final curveSplit = curve.splitAt(at);
    final tSplit = Utils.map(at, 0, 1, t1, t2);
    final subcurveLeft = Subcurve<CurveType>(
        t1: t1, t2: tSplit, curve: curveSplit.left as CurveType);
    final subcurveRight = Subcurve<CurveType>(
        t1: tSplit, t2: t2, curve: curveSplit.right as CurveType);
    return (left: subcurveLeft, right: subcurveRight);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Subcurve) return false;
    return t1 == other.t1 && t2 == other.t2 && curve == other.curve;
  }

  @override
  int get hashCode => Object.hash(t1, t2, curve);
}
