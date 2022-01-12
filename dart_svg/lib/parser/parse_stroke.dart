import '../dsl/dsvg.dart';
import '../parser/parse_attribute.dart';
import '../parser/parse_color.dart';
import '../parser/parse_double.dart';
import '../parser/parse_fill.dart';
import '../parser/parser_state.dart';

import 'parse_double_with_units.dart';

/// Parses a @stroke attribute into a Paint.
DsvgPaint? parseStroke(
  final Map<String, String> attributes,
  final DsvgDrawableDefinitionRegistry? definitions,
  final DsvgPaint? parentStroke,
  final DsvgColor? currentColor,
  final double fontSize,
  final double xHeight,
  final SvgErrorDelegate errorDelegate,
) {
  final String rawStroke = getAttribute(attributes, 'stroke', def: '')!;
  final String? rawStrokeOpacity = getAttribute(
    attributes,
    'stroke-opacity',
    def: '1.0',
  );
  final String? rawOpacity = getAttribute(attributes, 'opacity', def: '');
  double opacity = parseDouble(rawStrokeOpacity)!.clamp(0.0, 1.0).toDouble();
  if (rawOpacity != '') {
    opacity *= parseDouble(rawOpacity)!.clamp(0.0, 1.0);
  }
  if (rawStroke.startsWith('url')) {
    return getDefinitionPaint(
      errorDelegate,
      DsvgPaintingStyle.stroke,
      rawStroke,
      definitions,
      opacity: opacity,
    );
  } else if (rawStroke == '' && drawablePaintIsEmpty(parentStroke)) {
    return null;
  } else if (rawStroke == 'none') {
    return emptyDrawablePaint;
  } else {
    final String? rawStrokeCap = getAttribute(attributes, 'stroke-linecap', def: '');
    final String? rawLineJoin = getAttribute(attributes, 'stroke-linejoin', def: '');
    final String? rawMiterLimit = getAttribute(attributes, 'stroke-miterlimit', def: '');
    final String? rawStrokeWidth = getAttribute(attributes, 'stroke-width', def: '');
    final DsvgPaint paint = DsvgPaint(
      DsvgPaintingStyle.stroke,
      color: () {
        if (rawStroke == '') {
          return (parentStroke?.color ?? const DsvgColor(0xFF000000)).withOpacity(opacity);
        } else {
          return (svgColorStringToColor(rawStroke) ??
                  currentColor ??
                  parentStroke?.color ??
                  const DsvgColor(0xFF000000))
              .withOpacity(opacity);
        }
      }(),
      strokeCap: () {
        if (rawStrokeCap == 'null') {
          return parentStroke?.strokeCap ?? DsvgStrokeCap.butt;
        } else {
          return DsvgStrokeCap.values.firstWhere(
            (DsvgStrokeCap sc) => sc.toString() == 'DsvgStrokeCap.$rawStrokeCap',
            orElse: () => DsvgStrokeCap.butt,
          );
        }
      }(),
      strokeJoin: () {
        if (rawLineJoin == '') {
          return parentStroke?.strokeJoin ?? DsvgStrokeJoin.miter;
        } else {
          return DsvgStrokeJoin.values.firstWhere(
            (DsvgStrokeJoin sj) => sj.toString() == 'DsvgStrokeJoin.$rawLineJoin',
            orElse: () => DsvgStrokeJoin.miter,
          );
        }
      }(),
      strokeMiterLimit: () {
        if (rawMiterLimit == '') {
          return parentStroke?.strokeMiterLimit ?? 4.0;
        } else {
          return parseDouble(rawMiterLimit);
        }
      }(),
      strokeWidth: () {
        if (rawStrokeWidth == '') {
          return parentStroke?.strokeWidth ?? 1.0;
        } else {
          return parseDoubleWithUnits(
            rawStrokeWidth,
            fontSize: fontSize,
            xHeight: xHeight,
          );
        }
      }(),
    );
    return paint;
  }
}
