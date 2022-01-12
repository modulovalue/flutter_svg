import '../dsl/dsvg.dart';

/// Parses a `fill-rule` attribute.
DsvgPathFillType? parseRawFillRule(
  final String? rawFillRule,
) {
  if (rawFillRule == 'inherit' || rawFillRule == null) {
    return null;
  } else {
    if (rawFillRule != 'evenodd') {
      return DsvgPathFillType.nonZero;
    } else {
      return DsvgPathFillType.evenOdd;
    }
  }
}
