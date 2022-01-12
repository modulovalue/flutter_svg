import '../parser/parse_attribute.dart';
import '../parser/parse_double_with_units.dart';

/// Parses an @stroke-dasharray attribute.
///
/// Does not currently support percentages.
List<double>? parseDashArray(
  final Map<String, String> attributes, {
  required double fontSize,
  required double xHeight,
}) {
  final String? rawDashArray = getAttribute(
    attributes,
    'stroke-dasharray',
    def: '',
  );
  if (rawDashArray == '') {
    return null;
  } else if (rawDashArray == 'none') {
    return <double>[];
  } else {
    final List<String> parts = rawDashArray!.split(RegExp(r'[ ,]+'));
    return parts
        .map(
          (final String part) => parseDoubleWithUnits(
            part,
            fontSize: fontSize,
            xHeight: xHeight,
          )!,
        )
        .toList();
  }
}
