import 'package:meta/meta.dart';

import 'dsvg.dart';
import 'dsvg_affine_matrix.dart';

/// Basic information describing a gradient.
abstract class DsvgGradient {
  /// Specifies where `colors[i]` begins in the gradient.
  ///
  /// Number of elements must equal the number of elements in [colors].
  List<double>? get offsets;

  /// The colors to use for the gradient.
  List<DsvgColor>? get colors;

  /// The [DsvgTileMode] to use for this gradient.
  DsvgTileMode get spreadMethod;

  /// The [DsvgGradientUnitMode] for any vectors specified by this gradient.
  DsvgGradientUnitMode get unitMode;

  /// The transform to apply to this gradient.
  DsvgAffineMatrix? get transform;

  R match<R>({
    required final R Function(DsvgGradientRadial) radialGradient,
    required final R Function(DsvgGradientLinear) linearGradient,
  });
}

/// Represents the data needed to create a linear gradient.
@immutable
class DsvgGradientLinear implements DsvgGradient {
  const DsvgGradientLinear({
    required final this.gradientStartOffset,
    required final this.gradientEndOffset,
    required final this.offsets,
    required final this.colors,
    required final this.spreadMethod,
    required final this.unitMode,
    this.transform,
  });

  @override
  final List<double>? offsets;
  @override
  final List<DsvgColor>? colors;
  @override
  final DsvgTileMode spreadMethod;
  @override
  final DsvgGradientUnitMode unitMode;
  @override
  final DsvgAffineMatrix? transform;
  final DsvgOffset gradientStartOffset;
  final DsvgOffset gradientEndOffset;

  @override
  R match<R>({
    required final R Function(DsvgGradientRadial p1) radialGradient,
    required final R Function(DsvgGradientLinear p1) linearGradient,
  }) =>
      linearGradient(this);
}

@immutable
class DsvgGradientRadial implements DsvgGradient {
  const DsvgGradientRadial({
    required final this.centerX,
    required final this.centerY,
    required final this.radius,
    required final this.focalX,
    required final this.focalY,
    required final this.offsets,
    required final this.colors,
    required final this.spreadMethod,
    required final this.unitMode,
    final this.focalRadius = 0.0,
    final this.transform,
  });

  @override
  final List<double>? offsets;
  @override
  final List<DsvgColor>? colors;
  @override
  final DsvgTileMode spreadMethod;
  @override
  final DsvgGradientUnitMode unitMode;
  @override
  final DsvgAffineMatrix? transform;
  final double centerX;
  final double centerY;
  final double? radius;
  final double focalX;
  final double focalY;
  final double focalRadius;

  @override
  R match<R>({
    required final R Function(DsvgGradientRadial p1) radialGradient,
    required final R Function(DsvgGradientLinear p1) linearGradient,
  }) =>
      radialGradient(this);
}
