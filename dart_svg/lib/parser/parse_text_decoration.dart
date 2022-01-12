import '../dsl/dsvg_text_decoration.dart';

/// Parses a `text-decoration` attribute value into a [DsvgTextDecoration].
DsvgTextDecoration? parseTextDecoration(
  final String? textDecoration,
) {
  switch (textDecoration) {
    case null:
      return null;
    case 'none':
      return DsvgTextDecoration.none;
    case 'underline':
      return DsvgTextDecoration.underline;
    case 'overline':
      return DsvgTextDecoration.overline;
    case 'line-through':
      return DsvgTextDecoration.linethrough;
    default:
      throw UnsupportedError(
        'Attribute value for text-decoration="$textDecoration" is not supported',
      );
  }
}
