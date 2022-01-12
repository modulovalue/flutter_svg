// ignore_for_file: sort_constructors_first

import 'package:meta/meta.dart';

abstract class DsvgDashOffset {
  R match<R>({
    required final R Function(double) absolute,
    required final R Function(double) percentage,
  });
}

@immutable
class DsvgDashOffsetAbsolute implements DsvgDashOffset {
  final double value;

  const DsvgDashOffsetAbsolute({
    required final this.value,
  });

  @override
  R match<R>({
    required final R Function(double p1) absolute,
    required final R Function(double p1) percentage,
  }) =>
      absolute(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DsvgDashOffsetAbsolute && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

@immutable
class DsvgDashOffsetPercentage implements DsvgDashOffset {
  final double value;

  const DsvgDashOffsetPercentage({
    required final this.value,
  });

  @override
  R match<R>({
    required final R Function(double p1) absolute,
    required final R Function(double p1) percentage,
  }) =>
      percentage(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DsvgDashOffsetPercentage && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
