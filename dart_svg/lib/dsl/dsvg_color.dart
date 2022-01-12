// ignore_for_file: sort_constructors_first

import 'package:meta/meta.dart';

@immutable
class DsvgColor {
  final int value;

  const DsvgColor(
    final int value,
  ) : value = value & 0xFFFFFFFF;

  const DsvgColor.fromARGB(
    final int a,
    final int r,
    final int g,
    final int b,
  ) : value = (((a & 0xff) << 24) | ((r & 0xff) << 16) | ((g & 0xff) << 8) | ((b & 0xff) << 0)) & 0xFFFFFFFF;

  const DsvgColor.fromRGBO(
    final int r,
    final int g,
    final int b,
    final double opacity,
  ) : value = ((((opacity * 0xff ~/ 1) & 0xff) << 24) |
                ((r & 0xff) << 16) |
                ((g & 0xff) << 8) |
                ((b & 0xff) << 0)) &
            0xFFFFFFFF;

  DsvgColor withOpacity(
    final double opacity,
  ) {
    assert(
      opacity >= 0.0 && opacity <= 1.0,
      "Opacity must be a normalized value.",
    );
    return withAlpha((255.0 * opacity).round());
  }

  DsvgColor withAlpha(
    final int a,
  ) =>
      DsvgColor.fromARGB(
        a,
        red,
        green,
        blue,
      );

  int get red => (0x00ff0000 & value) >> 16;

  int get green => (0x0000ff00 & value) >> 8;

  int get blue => (0x000000ff & value) >> 0;

  @override
  bool operator ==(
    final Object other,
  ) =>
      identical(this, other) ||
      other is DsvgColor && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
