/// Parses a [rawDouble] `String` to a `double`.
///
/// The [rawDouble] might include a unit (`px`, `em` or `ex`)
/// which is stripped off when parsed to a `double`.
///
/// Passing `null` will return `null`.
double? parseDouble(
  String? rawDouble, {
  final bool tryParse = false,
}) {
  if (rawDouble == null) {
    return null;
  } else {
    // ignore: parameter_assignments
    rawDouble = rawDouble
        .replaceFirst(
          'em',
          '',
        )
        .replaceFirst(
          'ex',
          '',
        )
        .replaceFirst(
          'px',
          '',
        )
        .trim();
    if (tryParse) {
      return double.tryParse(rawDouble);
    } else {
      return double.parse(rawDouble);
    }
  }
}
