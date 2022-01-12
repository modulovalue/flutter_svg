import '../dsl/dsvg_dash_offset.dart';
import '../parser/parse_attribute.dart';

import 'parse_double_with_units.dart';
import 'parse_percentage.dart';

/// Parses a @stroke-dashoffset into a [DsvgDashOffset].
DsvgDashOffset? parseDashOffset(
  final Map<String, String> attributes, {
  required double fontSize,
  required double xHeight,
}) {
  final String? rawDashOffset = getAttribute(
    attributes,
    'stroke-dashoffset',
    def: '',
  );
  if (rawDashOffset == '') {
    return null;
  } else if (rawDashOffset!.endsWith('%')) {
    return DsvgDashOffsetPercentage(
      value: parsePercentage(
        rawDashOffset,
      ),
    );
  } else {
    return DsvgDashOffsetAbsolute(
      value: parseDoubleWithUnits(
        rawDashOffset,
        fontSize: fontSize,
        xHeight: xHeight,
      )!,
    );
  }
}
