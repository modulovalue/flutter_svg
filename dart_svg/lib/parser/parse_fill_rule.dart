import '../dsl/dsvg.dart';
import 'parse_attribute.dart';
import 'parse_raw_fill_rule.dart';

/// Parses a `fill-rule` attribute into a [DsvgPathFillType].
DsvgPathFillType? parseFillRule(
  final String? Function(String) attributes, [
  final String attr = 'fill-rule',
  final String? def = 'nonzero',
]) {
  final String? rawFillRule = getAttribute(
    attributes,
    attr,
    def: def,
  );
  return parseRawFillRule(rawFillRule);
}
