import 'parser/parser_state.dart';

class SvgErrorDelegatePrintsImpl implements SvgErrorDelegate {
  SvgErrorDelegatePrintsImpl();

  @override
  void reportUnsupportedNestedSvg() => print(
        'Unsupported nested <svg> element.',
      );

  @override
  void reportMissingDef(
    final String? href,
    final String methodName,
  ) =>
      print(
        'Failed to find definition for ' + href.toString(),
      );

  @override
  void reportUnhandledElement(
    final String name,
  ) {
    if (!_unhandledElementsSingleton.contains(name)) {
      print('unhandled element ' + name);
      // Ignore all other occurrences of that element.
      _unhandledElementsSingleton.add(name);
    }
  }

  @override
  void reportUnsupportedClipPathChild(
    final String name,
  ) =>
      print(
        'Unsupported clipPath child ' + name,
      );

  /// Keeps track of elements thar are ignored. New elements
  /// are added once they are encountered and so that next
  /// encounters do not cause a warning.
  final Set<String> _unhandledElementsSingleton = <String>{
    'title',
    'desc',
  };

  @override
  void reportUnsupportedUnits(
    final String raw,
  ) {
    print(
      'Warning: Flutter SVG only supports the following formats for `width` and `height` on the SVG root:\n'
      '  width="100%"\n'
      '  width="100em"\n'
      '  width="100ex"\n'
      '  width="100px"\n'
      '  width="100" (where the number will be treated as pixels).\n'
      'The supplied value ($raw) will be discarded and treated as if it had not been specified.',
    );
  }
}
