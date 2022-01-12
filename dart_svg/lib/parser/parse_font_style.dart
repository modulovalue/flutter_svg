import '../dsl/dsvg_font_style.dart';

DsvgFontStyle? parseFontStyle(
  final String? fontStyle,
) {
  if (fontStyle == null) {
    return null;
  } else {
    switch (fontStyle) {
      case 'normal':
        return DsvgFontStyle.normal;
      case 'italic':
      case 'oblique':
        return DsvgFontStyle.italic;
    }
    throw UnsupportedError('Attribute value for font-style="$fontStyle" is not supported');
  }
}
