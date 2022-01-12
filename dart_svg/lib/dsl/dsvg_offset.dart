// ignore_for_file: sort_constructors_first

import 'package:meta/meta.dart';

@immutable
class DsvgOffset {
  final double x;
  final double y;

  const DsvgOffset({
    required final this.x,
    required final this.y,
  });

  @override
  bool operator ==(
    final Object other,
  ) =>
      identical(this, other) ||
      other is DsvgOffset && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  DsvgOffset translate(
    final double translateX,
    final double translateY,
  ) =>
      DsvgOffset(
        x: x + translateX,
        y: y + translateY,
      );
}
