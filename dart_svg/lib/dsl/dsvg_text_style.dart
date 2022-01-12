import 'package:meta/meta.dart';

import 'dsvg_color.dart';
import 'dsvg_drawable_text_anchor_position.dart';
import 'dsvg_font_style.dart';
import 'dsvg_font_weight.dart';
import 'dsvg_text_decoration.dart';
import 'dsvg_text_decoration_style.dart';

/// A wrapper class for Flutter's TextStyle class.
///
/// Provides non-opaque access to text styling properties.
@immutable
class DsvgTextStyle {
  /// Creates a new [DsvgTextStyle].
  const DsvgTextStyle({
    final this.decoration,
    final this.decorationColor,
    final this.decorationStyle,
    final this.fontWeight,
    final this.fontFamily,
    final this.fontSize,
    final this.fontStyle,
    final this.height,
    final this.anchor,
  });

  final DsvgTextDecoration? decoration;
  final DsvgColor? decorationColor;
  final DsvgTextDecorationStyle? decorationStyle;
  final DsvgFontWeight? fontWeight;
  final DsvgFontStyle? fontStyle;
  final String? fontFamily;
  final double? fontSize;
  final double? height;
  final DsvgDrawableTextAnchorPosition? anchor;
}

/// Merges two drawable text styles together,
/// preferring set properties from [b].
DsvgTextStyle? mergeDrawableTextStyle(
  final DsvgTextStyle? a,
  final DsvgTextStyle? b,
) {
  if (b == null) {
    return a;
  } else if (a == null) {
    return b;
  } else {
    return DsvgTextStyle(
      decoration: a.decoration ?? b.decoration,
      decorationColor: a.decorationColor ?? b.decorationColor,
      decorationStyle: a.decorationStyle ?? b.decorationStyle,
      fontWeight: a.fontWeight ?? b.fontWeight,
      fontStyle: a.fontStyle ?? b.fontStyle,
      fontFamily: a.fontFamily ?? b.fontFamily,
      fontSize: a.fontSize ?? b.fontSize,
      height: a.height ?? b.height,
      anchor: a.anchor ?? b.anchor,
    );
  }
}
