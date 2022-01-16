import '../parser/parse_attribute.dart';
import '../parser/parse_double_with_units.dart';

/// Parses an @stroke-dasharray attribute.
///
/// Does not currently support percentages.
List<double>? parseDashArray(
  final String? Function(String) attributes, {
  required double fontSize,
  required double xHeight,
}) {
  final rawDashArray = getAttribute(
    attributes,
    'stroke-dasharray',
    def: '',
  );
  if (rawDashArray == '') {
    return null;
  } else if (rawDashArray == 'none') {
    return <double>[];
  } else {
    final parts = rawDashArray!.split(RegExp(r'[ ,]+'));
    return parts
        .map(
          (final part) => parseDoubleWithUnits(
            part,
            fontSize: fontSize,
            xHeight: xHeight,
          ),
        )
        .toList();
  }
}
