// ignore_for_file: sort_constructors_first

import 'package:meta/meta.dart';

@immutable
class DsvgRect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const DsvgRect.fromLTRB(
    final this.left,
    final this.top,
    final this.right,
    final this.bottom,
  );

  const DsvgRect.fromLTWH(
    final double left,
    final double top,
    final double width,
    final double height,
  ) : this.fromLTRB(
          left,
          top,
          left + width,
          top + height,
        );

  double get width => right - left;

  double get height => bottom - top;

  @override
  bool operator ==(
    final Object other,
  ) =>
      identical(this, other) ||
      other is DsvgRect &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          top == other.top &&
          right == other.right &&
          bottom == other.bottom;

  @override
  int get hashCode => left.hashCode ^ top.hashCode ^ right.hashCode ^ bottom.hashCode;
}
