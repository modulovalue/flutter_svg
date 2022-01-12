import 'package:meta/meta.dart';

import 'dsvg_color.dart';

@immutable
class DsvgThemeImpl implements DsvgTheme {
  const DsvgThemeImpl({
    final this.currentColor,
    final this.fontSize = 14,
    final double? xHeight,
  }) : xHeight = xHeight ?? fontSize / 2;

  @override
  final DsvgColor? currentColor;
  @override
  final double fontSize;
  @override
  final double xHeight;

  @override
  bool operator ==(
    final dynamic other,
  ) {
    if (other.runtimeType != runtimeType) {
      return false;
    } else {
      return other is DsvgTheme &&
          currentColor == other.currentColor &&
          fontSize == other.fontSize &&
          xHeight == other.xHeight;
    }
  }

  @override
  int get hashCode => Object.hash(
        currentColor,
        fontSize,
        xHeight,
      );
}

/// A theme used when decoding an SVG picture.
abstract class DsvgTheme {
  /// The default color applied to SVG elements that inherit the color property.
  /// See: https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#currentcolor_keyword
  DsvgColor? get currentColor;

  /// The font size used when calculating em units of SVG elements.
  /// See: https://www.w3.org/TR/SVG11/coords.html#Units
  double get fontSize;

  /// The x-height (corpus size) of the font used when calculating ex units of SVG elements.
  /// Defaults to [fontSize] / 2 if not provided.
  /// See: https://www.w3.org/TR/SVG11/coords.html#Units, https://en.wikipedia.org/wiki/X-height
  double get xHeight;
}
