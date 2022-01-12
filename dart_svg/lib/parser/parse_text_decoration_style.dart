import '../dsl/dsvg_text_decoration_style.dart';

/// Parses a `text-decoration-style` attribute value into a [DsvgTextDecorationStyle].
DsvgTextDecorationStyle? parseTextDecorationStyle(
  final String? textDecorationStyle,
) {
  switch (textDecorationStyle) {
    case null:
      return null;
    case 'solid':
      return DsvgTextDecorationStyle.solid;
    case 'dashed':
      return DsvgTextDecorationStyle.dashed;
    case 'dotted':
      return DsvgTextDecorationStyle.dotted;
    case 'double':
      return DsvgTextDecorationStyle.double;
    case 'wavy':
      return DsvgTextDecorationStyle.wavy;
    default:
      throw UnsupportedError(
        'Attribute value for text-decoration-style="$textDecorationStyle" is not supported',
      );
  }
}
