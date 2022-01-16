import 'parse_double.dart';

/// Parses values in the form of '100%'.
double parsePercentage(
  final String val, {
  final double multiplier = 1.0,
}) =>
    parseDouble(val.substring(0, val.length - 1)) / 100 * multiplier;

/// Whether a string should be treated as a percentage (i.e. if it ends with a `'%'`).
bool isPercentage(
  final String val,
) =>
    val.endsWith('%');
