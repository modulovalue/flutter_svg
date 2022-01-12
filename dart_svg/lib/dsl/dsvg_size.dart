// ignore_for_file: sort_constructors_first

import 'package:meta/meta.dart';

@immutable
class DsvgSize {
  final double w;
  final double h;

  const DsvgSize({
    required final this.w,
    required final this.h,
  });

  @override
  bool operator ==(
    final Object other,
  ) =>
      identical(this, other) ||
      other is DsvgSize && runtimeType == other.runtimeType && w == other.w && h == other.h;

  @override
  int get hashCode => w.hashCode ^ h.hashCode;

  bool get isEmpty => w <= 0.0 || h <= 0.0;
}
