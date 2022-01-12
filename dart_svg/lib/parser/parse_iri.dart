import 'parse_attribute.dart';

/// Builds an IRI in the form of `'url(#id)'`.
String parseUrlIri({
  required final Map<String, String> attributes,
}) =>
    'url(#' +
    getAttribute(
      attributes,
      'id',
      def: '',
    ).toString() +
    ')';
