/// Gets the attribute, trims it, and returns the attribute or default if the attribute
/// is null or ''.
///
/// Will look to the style first if it can.
String? getAttribute(
  final String? Function(String) el,
  final String name, {
  required final String? def,
  final bool checkStyle = true,
}) {
  String raw = '';
  if (checkStyle) {
    final String style = el('style') ?? '';
    if (style != '') {
      // Probably possible to slightly optimize this (e.g. use indexOf instead of split),
      // but handling potential whitespace will get complicated and this just works.
      // I also don't feel like writing benchmarks for what is likely a micro-optimization.
      final List<String> styles = style.split(';');
      raw = styles.firstWhere(
        (final String str) => str.trimLeft().startsWith(name + ':'),
        orElse: () => '',
      );
      if (raw != '') {
        raw = raw.substring(raw.indexOf(':') + 1).trim();
      }
    }
    if (raw == '') {
      raw = el(name) ?? '';
    }
  } else {
    raw = el(name) ?? '';
  }
  if (raw == '') {
    return def;
  } else {
    return raw;
  }
}



extension MapTypedGet<K, V> on Map<K, V> {
  V? typedGet(K key) => this[key];
}
