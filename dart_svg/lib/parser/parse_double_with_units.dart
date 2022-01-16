import 'parse_double.dart';

double? tryParseDoubleWithUnits(
  final String? rawDouble, {
  required double fontSize,
  required double xHeight,
}) {
  final value = tryParseDouble(
    rawDouble,
  );
  if (value != null) {
    return value *
        getMultiplier(
          rawDouble: rawDouble!,
          fontSize: fontSize,
          xHeight: xHeight,
        );
  } else {
    return null;
  }
}

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
double parseDoubleWithUnits(
  final String rawDouble, {
  required double fontSize,
  required double xHeight,
}) {
  final value = parseDouble(
    rawDouble,
  );
  // TODO refactor that and share in both.
  return value *
      getMultiplier(
        rawDouble: rawDouble,
        fontSize: fontSize,
        xHeight: xHeight,
      );
}

double getMultiplier({
  required final String rawDouble,
  required final double fontSize,
  required final double xHeight,
}) {
  if (rawDouble.contains('em')) {
    // 1 em unit is equal to the current font size.
    return fontSize;
  } else if (rawDouble.contains('ex')) {
    // 1 ex unit is equal to the current x-height.
    return xHeight;
  } else if (rawDouble.contains('pt')) {
    // 1 pt unit is equal to about 1.33333 pixel at 96 dpi
    return 1.3333333333;
  } else {
    return 1.0;
  }
}
