import 'parse_attribute.dart';

/// Get the `xlink:href` or `href` attribute, preferring `xlink`.
///
/// SVG 1.1 specifies that these attributes should be in the xlink namespace.
/// SVG 2 deprecates that namespace.
String? getHrefAttribute(
  final Map<String, String> attributes,
) =>
    getAttribute(
      attributes,
      'href',
      def: getAttribute(
        attributes,
        'href',
        def: '',
      ),
    );
