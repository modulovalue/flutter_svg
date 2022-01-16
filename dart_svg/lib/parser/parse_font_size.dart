import 'parse_double_with_units.dart';

/// Parses a `font-size` attribute.
///
/// Uses [fontSize] and [xHeight] to calculate the font size
/// that includes em or ex units.
double? parseFontSize(
  String? raw, {
  required double fontSize,
  required double xHeight,
  final double? parentValue,
}) {
  if (raw == null || raw == '') {
    return null;
  } else {
    final ret = tryParseDoubleWithUnits(
      raw,
      fontSize: fontSize,
      xHeight: xHeight,
    );
    if (ret != null) {
      return ret;
    } else {
      const Map<String, double> _kTextSizeMap = <String, double>{
        'xx-small': 10,
        'x-small': 12,
        'small': 14,
        'medium': 18,
        'large': 22,
        'x-large': 26,
        'xx-large': 32,
      };
      // ignore: parameter_assignments
      raw = raw.toLowerCase().trim();
      final _ret = _kTextSizeMap[raw];
      if (_ret != null) {
        return _ret;
      } else {
        if (raw == 'larger') {
          if (parentValue == null) {
            return _kTextSizeMap['large'];
          } else {
            return parentValue * 1.2;
          }
        } else if (raw == 'smaller') {
          if (parentValue == null) {
            return _kTextSizeMap['small'];
          } else {
            return parentValue / 1.2;
          }
        } else {
          throw StateError('Could not parse font-size: $raw');
        }
      }
    }
  }
}
