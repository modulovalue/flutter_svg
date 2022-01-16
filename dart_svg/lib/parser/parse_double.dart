/// Parses a [rawDouble] `String` to a `double`.
///
/// The [rawDouble] might include a unit (`px`, `em` or `ex`)
/// which is stripped off when parsed to a `double`.
///
/// Passing `null` will return `null`.
double parseDouble(
  final String rawDouble,
) {
  final _rawDouble = _trimUnits(rawDouble);
  return double.parse(_rawDouble);
}

double? tryParseDouble(
  final String? rawDouble,
) {
  if (rawDouble == null) {
    return null;
  } else {
    final _rawDouble = _trimUnits(rawDouble);
    return double.tryParse(_rawDouble);
  }
}

String _trimUnits(
  final String value,
) =>
    value //
        .replaceFirst('em', '')
        .replaceFirst('ex', '')
        .replaceFirst('px', '')
        .trim();
