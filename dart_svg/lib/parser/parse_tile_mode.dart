import '../dsl/dsvg.dart';
import '../parser/parse_attribute.dart';

/// Parses a `spreadMethod` attribute into a [DsvgTileMode].
DsvgTileMode parseTileMode(
  final String? Function(String) attributes,
) {
  final String? spreadMethod = getAttribute(
    attributes,
    'spreadMethod',
    def: 'pad',
  );
  switch (spreadMethod) {
    case 'pad':
      return DsvgTileMode.clamp;
    case 'repeat':
      return DsvgTileMode.repeated;
    case 'reflect':
      return DsvgTileMode.mirror;
    default:
      return DsvgTileMode.clamp;
  }
}
