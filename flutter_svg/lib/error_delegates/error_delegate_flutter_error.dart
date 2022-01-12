import 'package:dart_svg/parser/parser_state.dart';
import 'package:flutter/foundation.dart';

class SvgErrorDelegateFlutterWarnImpl implements SvgErrorDelegate {
  const SvgErrorDelegateFlutterWarnImpl({
    required final this.key,
  });

  final String? key;

  @override
  void reportUnsupportedNestedSvg() => FlutterError.reportError(
        FlutterErrorDetails(
          exception: UnsupportedError(
            'Unsupported nested <svg> element.',
          ),
          informationCollector: () sync* {
            yield ErrorDescription(
              'The root <svg> element contained an unsupported nested SVG element.',
            );
            if (key != null) {
              yield ErrorDescription(
                '',
              );
              yield DiagnosticsProperty<String>(
                'Picture key',
                key,
              );
            }
          },
          library: 'SVG',
          context: ErrorDescription(
            'in _Element.svg',
          ),
        ),
      );

  @override
  void reportMissingDef(
    final String? href,
    final String methodName,
  ) =>
      FlutterError.onError!(
        FlutterErrorDetails(
          exception: FlutterError.fromParts(
            <DiagnosticsNode>[
              ErrorSummary(
                'Failed to find definition for $href',
              ),
              ErrorDescription(
                'This library only supports <defs> and xlink:href references that '
                'are defined ahead of their references.',
              ),
              ErrorHint(
                'This error can be caused when the desired definition is defined after the element '
                'referring to it (e.g. at the end of the file), or defined in another file.',
              ),
              ErrorDescription(
                'This error is treated as non-fatal, but your SVG file will likely not render as intended',
              ),
            ],
          ),
          context: ErrorDescription(
            'while parsing $key in $methodName',
          ),
          library: 'SVG',
        ),
      );

  @override
  void reportUnhandledElement(
    final String name,
  ) {
    if (name == 'style') {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: UnimplementedError(
            'The <style> element is not implemented in this library.',
          ),
          informationCollector: () => <DiagnosticsNode>[
            ErrorDescription(
              'Style elements are not supported by this library and the requested SVG may not render as intended.',
            ),
            ErrorHint(
              'If possible, ensure the SVG uses inline styles and/or attributes (which are supported), or use a preprocessing utility such as svgcleaner to inline the styles for you.',
            ),
            ErrorDescription(
              '',
            ),
            DiagnosticsProperty<String>(
              'Picture key',
              key,
            ),
          ],
          library: 'SVG',
          context: ErrorDescription(
            'in parseSvgElement',
          ),
        ),
      );
    } else {
      if (!_unhandledElementsSingleton.contains(name)) {
        print('unhandled element ' + name + '; Picture key: $key');
        // Ignore all other occurrences of that element.
        _unhandledElementsSingleton.add(name);
      }
    }
  }

  @override
  void reportUnsupportedClipPathChild(
    final String name,
  ) =>
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: UnsupportedError(
            'Unsupported clipPath child ' + name,
          ),
          informationCollector: () sync* {
            yield ErrorDescription(
              'The <clipPath> element contained an unsupported child ' + name,
            );
            if (key != null) {
              yield ErrorDescription(
                '',
              );
              yield DiagnosticsProperty<String>(
                'Picture key',
                key,
              );
            }
          },
          library: 'SVG',
          context: ErrorDescription(
            'in _Element.clipPath',
          ),
        ),
      );

  @override
  void reportUnsupportedUnits(
    final String raw,
  ) =>
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

/// Keeps track of elements thar are ignored. New elements
/// are added once they are encountered and so that next
/// encounters do not cause a warning.
final Set<String> _unhandledElementsSingleton = <String>{
  'title',
  'desc',
};
