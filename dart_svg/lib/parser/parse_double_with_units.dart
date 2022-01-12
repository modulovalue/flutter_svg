import 'parse_double.dart';

/// Parses a [rawDouble] `String` to a `double`
/// taking into account absolute and relative units
/// (`px`, `em` or `ex`).
///
/// Passing an `em` value will calculate the result
/// relative to the provided [fontSize]:
/// 1 em = 1 * [fontSize].
///
/// Passing an `ex` value will calculate the result
/// relative to the provided [xHeight]:
/// 1 ex = 1 * [xHeight].
///
/// The [rawDouble] might include a unit which is
/// stripped off when parsed to a `double`.
///
/// Passing `null` will return `null`.
double? parseDoubleWithUnits(
  String? rawDouble, {
  required double fontSize,
  required double xHeight,
  final bool tryParse = false,
}) {
  double unit = 1.0;
  // 1 em unit is equal to the current font size.
  if (rawDouble?.contains('em') ?? false) {
    unit = fontSize;
  }
  // 1 ex unit is equal to the current x-height.
  else if (rawDouble?.contains('ex') ?? false) {
    unit = xHeight;
  }
  final double? value = parseDouble(
    rawDouble,
    tryParse: tryParse,
  );
  if (value != null) {
    return value * unit;
  } else {
    return null;
  }
}
