import '../dsl/dsvg.dart';
import '../parser/parse_attribute.dart';
import '../parser/parse_color.dart';
import '../parser/parse_fill.dart';
import '../parser/parser_state.dart';

import 'parse_dash_array.dart';
import 'parse_dash_offset.dart';
import 'parse_double.dart';
import 'parse_fill_rule.dart';
import 'parse_font_size.dart';
import 'parse_font_style.dart';
import 'parse_font_weight.dart';
import 'parse_stroke.dart';
import 'parse_text_anchor.dart';
import 'parse_text_decoration.dart';
import 'parse_text_decoration_style.dart';

/// Parses style attributes or @style attribute.
///
/// Remember that @style attribute takes precedence.
DsvgDrawableStyle parseStyle(
  final SvgErrorDelegate errorDelegate,
  final Map<String, String> attributes,
  final DsvgDrawableDefinitionRegistry? definitions,
  final DsvgDrawableStyle? parentStyle, {
  required final double fontSize,
  required final double xHeight,
  final DsvgColor? defaultFillColor,
  final DsvgColor? currentColor,
}) =>
    mergeAndBlendDrawableStyle(
      parentStyle,
      stroke: parseStroke(
        attributes,
        definitions,
        parentStyle?.stroke,
        currentColor,
        fontSize,
        xHeight,
        errorDelegate,
      ),
      dashArray: parseDashArray(
        attributes,
        fontSize: fontSize,
        xHeight: xHeight,
      ),
      dashOffset: parseDashOffset(
        attributes,
        fontSize: fontSize,
        xHeight: xHeight,
      ),
      fill: parseFill(
        errorDelegate,
        attributes,
        definitions,
        parentStyle?.fill,
        defaultFillColor,
        currentColor,
      ),
      pathFillType: parseFillRule(
        attributes,
        'fill-rule',
        () {
          if (parentStyle != null) {
            return null;
          } else {
            return 'nonzero';
          }
        }(),
      ),
      groupOpacity: () {
        final String? rawOpacity = getAttribute(
          attributes,
          'opacity',
          def: null,
        );
        if (rawOpacity != null) {
          return parseDouble(rawOpacity)!.clamp(0.0, 1.0).toDouble();
        } else {
          return null;
        }
      }(),
      mask: () {
        final String? rawMaskAttribute = getAttribute(
          attributes,
          'mask',
          def: '',
        );
        if (rawMaskAttribute != '') {
          return definitions?.getDrawable(rawMaskAttribute!);
        } else {
          return null;
        }
      }(),
      clipPath: () {
        final String? rawClipAttribute = getAttribute(
          attributes,
          'clip-path',
          def: '',
        );
        if (rawClipAttribute != '') {
          return definitions?.getClipPath(rawClipAttribute!);
        } else {
          return null;
        }
      }(),
      textStyle: DsvgTextStyle(
        fontFamily: getAttribute(
          attributes,
          'font-family',
          def: '',
        ),
        fontSize: parseFontSize(
          getAttribute(
            attributes,
            'font-size',
            def: '',
          ),
          parentValue: parentStyle?.textStyle?.fontSize,
          fontSize: fontSize,
          xHeight: xHeight,
        ),
        fontWeight: parseFontWeight(
          getAttribute(attributes, 'font-weight', def: null),
        ),
        fontStyle: parseFontStyle(
          getAttribute(attributes, 'font-style', def: null),
        ),
        anchor: parseTextAnchor(
          getAttribute(attributes, 'text-anchor', def: 'inherit'),
        ),
        decoration: parseTextDecoration(
          getAttribute(attributes, 'text-decoration', def: null),
        ),
        decorationColor: svgColorStringToColor(
          getAttribute(attributes, 'text-decoration-color', def: null),
        ),
        decorationStyle: parseTextDecorationStyle(
          getAttribute(attributes, 'text-decoration-style', def: null),
        ),
      ),
      blendMode: () {
        final String blendMode = getAttribute(
          attributes,
          'mix-blend-mode',
          def: '',
        )!;
        switch (blendMode) {
          case 'multiply':
            return DsvgBlendMode.multiply;
          case 'screen':
            return DsvgBlendMode.screen;
          case 'overlay':
            return DsvgBlendMode.overlay;
          case 'darken':
            return DsvgBlendMode.darken;
          case 'lighten':
            return DsvgBlendMode.lighten;
          case 'color-dodge':
            return DsvgBlendMode.colorDodge;
          case 'color-burn':
            return DsvgBlendMode.colorBurn;
          case 'hard-light':
            return DsvgBlendMode.hardLight;
          case 'soft-light':
            return DsvgBlendMode.softLight;
          case 'difference':
            return DsvgBlendMode.difference;
          case 'exclusion':
            return DsvgBlendMode.exclusion;
          case 'hue':
            return DsvgBlendMode.hue;
          case 'saturation':
            return DsvgBlendMode.saturation;
          case 'color':
            return DsvgBlendMode.color;
          case 'luminosity':
            return DsvgBlendMode.luminosity;
        }
      }(),
    );
