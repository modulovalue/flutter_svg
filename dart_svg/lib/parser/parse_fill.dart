import '../dsl/dsvg.dart';
import '../parser/parse_attribute.dart';
import '../parser/parse_color.dart';
import '../parser/parse_double.dart';
import '../parser/parser_state.dart';

/// Parses a `fill` attribute.
DsvgPaint? parseFill(
  final SvgErrorDelegate errorDelegate,
  final String? Function(String) el,
  final DsvgDrawableDefinitionRegistry? definitions,
  final DsvgPaint? parentFill,
  final DsvgColor? defaultFillColor,
  final DsvgColor? currentColor,
) {
  final rawFill = getAttribute(el, 'fill', def: '')!;
  final rawFillOpacity = getAttribute(el, 'fill-opacity', def: '1.0');
  final rawOpacity = getAttribute(el, 'opacity', def: '');
  double opacity = parseDouble(rawFillOpacity!).clamp(0.0, 1.0).toDouble();
  if (rawOpacity != '') {
    opacity *= parseDouble(rawOpacity!).clamp(0.0, 1.0);
  }
  if (rawFill.startsWith('url')) {
    return getDefinitionPaint(
      errorDelegate,
      DsvgPaintingStyle.fill,
      rawFill,
      definitions,
      opacity: opacity,
    );
  } else if (rawFill == '' && parentFill == emptyDrawablePaint) {
    return null;
  } else if (rawFill == 'none') {
    return emptyDrawablePaint;
  } else {
    return DsvgPaint(
      DsvgPaintingStyle.fill,
      color: _determineFillColor(
        parentFill?.color,
        rawFill,
        opacity,
        rawOpacity != '' || rawFillOpacity != '',
        defaultFillColor,
        currentColor,
      ),
    );
  }
}

DsvgPaint getDefinitionPaint(
  final SvgErrorDelegate errorDelegate,
  final DsvgPaintingStyle paintingStyle,
  final String iri,
  final DsvgDrawableDefinitionRegistry? definitions, {
  final double? opacity,
}) {
  final shader = definitions?.getShader(iri);
  if (shader == null) {
    errorDelegate.reportMissingDef(iri, '_getDefinitionPaint');
  }
  return DsvgPaint(
    paintingStyle,
    shader: shader,
    color: () {
      if (opacity != null) {
        return DsvgColor.fromRGBO(255, 255, 255, opacity);
      } else {
        return null;
      }
    }(),
  );
}

DsvgColor? _determineFillColor(
  final DsvgColor? parentFillColor,
  final String rawFill,
  final double opacity,
  final bool explicitOpacity,
  final DsvgColor? defaultFillColor,
  final DsvgColor? currentColor,
) {
  final DsvgColor? color =
      svgColorStringToColor(rawFill) ?? currentColor ?? parentFillColor ?? defaultFillColor;
  if (explicitOpacity && color != null) {
    return color.withOpacity(opacity);
  } else {
    return color;
  }
}
