import 'parser/parser_state.dart';

class SvgErrorDelegateThrowsImpl implements SvgErrorDelegate {
  const SvgErrorDelegateThrowsImpl({
    required final this.key,
  });

  final String? key;

  @override
  void reportUnsupportedNestedSvg() => throw UnsupportedError(
        'Unsupported nested <svg> element.',
      );

  @override
  void reportMissingDef(
    final String? href,
    final String methodName,
  ) =>
      throw Exception(
        'Failed to find definition for ' + href.toString(),
      );

  @override
  void reportUnhandledElement(
    final String name,
  ) =>
      throw UnimplementedError(
        'Unhandled element ' + name + '; Picture key: ' + key.toString(),
      );

  @override
  void reportUnsupportedClipPathChild(
    final String name,
  ) =>
      throw UnsupportedError(
        'Unsupported clipPath child $name',
      );

  @override
  void reportUnsupportedUnits(
    final String raw,
  ) =>
      throw Exception(
        'Warning: Flutter SVG only supports the following formats for `width` and `height` on the SVG root:\n'
        '  width="100%"\n'
        '  width="100em"\n'
        '  width="100ex"\n'
        '  width="100px"\n'
        '  width="100" (where the number will be treated as pixels).\n'
        'The supplied value ($raw) will be discarded and treated as if it had not been specified.',
      );
}
