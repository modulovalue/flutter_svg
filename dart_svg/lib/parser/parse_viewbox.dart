import '../dsl/dsvg.dart';
import '../parser/parse_attribute.dart';
import '../parser/parse_double.dart';
import '../parser/parse_double_with_units.dart';
import 'parser_state.dart';

/// Parses an SVG @viewBox attribute (e.g. 0 0 100 100) to a [DsvgRect].
DsvgViewport? parseViewBoxAndDimensions(
  final String? Function(String) attribute, {
  required final double fontSize,
  required final double xHeight,
  required final SvgErrorDelegate errorDelegate,
}) {
  final viewBox = getAttribute(attribute, 'viewBox', def: '');
  final rawWidth = getAttribute(attribute, 'width', def: '');
  final rawHeight = getAttribute(attribute, 'height', def: '');
  if (viewBox == '' && rawWidth == '' && rawHeight == '') {
    throw StateError(
      'SVG did not specify dimensions\n\n'
      'The SVG library looks for a `viewBox` or `width` and `height` attribute '
      'to determine the viewport boundary of the SVG.  Note that these attributes, '
      'as with all SVG attributes, are case sensitive.\n',
    );
  } else {
    final width = _parseRawWidthHeight(
      rawWidth,
      fontSize: fontSize,
      xHeight: xHeight,
      errorDelegate: errorDelegate,
    );
    final height = _parseRawWidthHeight(
      rawHeight,
      fontSize: fontSize,
      xHeight: xHeight,
      errorDelegate: errorDelegate,
    );
    if (viewBox == '') {
      return DsvgViewport(
        DsvgSize(
          w: width,
          h: height,
        ),
        DsvgSize(
          w: width,
          h: height,
        ),
        viewBoxOffset: const DsvgOffset(
          x: 0.0,
          y: 0.0,
        ),
      );
    } else {
      final parts = viewBox!.split(RegExp(r'[ ,]+'));
      if (parts.length < 4) {
        throw StateError('viewBox element must be 4 elements long');
      } else {
        return DsvgViewport(
          DsvgSize(
            w: width,
            h: height,
          ),
          DsvgSize(
            w: parseDouble(parts[2]),
            h: parseDouble(parts[3]),
          ),
          viewBoxOffset: DsvgOffset(
            x: -parseDouble(parts[0]),
            y: -parseDouble(parts[1]),
          ),
        );
      }
    }
  }
}

double _parseRawWidthHeight(
  final String? raw, {
  required final double fontSize,
  required final double xHeight,
  required final SvgErrorDelegate errorDelegate,
}) {
  if (raw == '100%' || raw == '') {
    return double.infinity;
  } else {
    assert(
      () {
        final notDigits = RegExp(r'[^\d\.]');
        if (!raw!.endsWith('px') &&
            !raw.endsWith('pt') &&
            !raw.endsWith('em') &&
            !raw.endsWith('ex') &&
            raw.contains(notDigits)) {
          errorDelegate.reportUnsupportedUnits(raw);
        }
        return true;
      }(),
      "",
    );
    return tryParseDoubleWithUnits(
          raw,
          fontSize: fontSize,
          xHeight: xHeight,
        ) ??
        double.infinity;
  }
}
