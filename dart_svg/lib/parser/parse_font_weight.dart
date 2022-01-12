import '../dsl/dsvg.dart';

/// Parses a `font-weight` attribute value into a [DsvgFontWeight].
DsvgFontWeight? parseFontWeight(
  final String? fontWeight,
) {
  if (fontWeight == null) {
    return null;
  } else {
    switch (fontWeight) {
      case '100':
        return DsvgFontWeight.w100;
      case '200':
        return DsvgFontWeight.w200;
      case '300':
        return DsvgFontWeight.w300;
      case 'normal':
      case '400':
        return DsvgFontWeight.w400;
      case '500':
        return DsvgFontWeight.w500;
      case '600':
        return DsvgFontWeight.w600;
      case 'bold':
      case '700':
        return DsvgFontWeight.w700;
      case '800':
        return DsvgFontWeight.w800;
      case '900':
        return DsvgFontWeight.w900;
    }
    throw UnsupportedError(
      'Attribute value for font-weight="$fontWeight" is not supported',
    );
  }
}
