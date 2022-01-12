import '../parser/parse_double.dart';
import '../parser/parse_percentage.dart';

/// Parses strings in the form of '1.0' or '100%'.
double parseDecimalOrPercentage(
  final String val, {
  final double multiplier = 1.0,
}) {
  if (isPercentage(val)) {
    return parsePercentage(
      val,
      multiplier: multiplier,
    );
  } else {
    return parseDouble(val)!;
  }
}
