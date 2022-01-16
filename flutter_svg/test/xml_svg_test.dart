import 'package:dart_svg/dsl/dsvg.dart';
import 'package:dart_svg/error_delegate_throw.dart';
import 'package:dart_svg/parser/parse_attribute.dart';
import 'package:dart_svg/parser/parse_dash_offset.dart';
import 'package:dart_svg/parser/parse_font_style.dart';
import 'package:dart_svg/parser/parse_font_weight.dart';
import 'package:dart_svg/parser/parse_href.dart';
import 'package:dart_svg/parser/parse_style.dart';
import 'package:dart_svg/parser/parse_text_decoration.dart';
import 'package:dart_svg/parser/parse_text_decoration_style.dart';
import 'package:dart_svg/parser/parse_tile_mode.dart';
import 'package:dart_svg/parser/parse_viewbox.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:test/test.dart';
import 'package:xml/xml_events.dart';

void main() {
  const errorDelegate = SvgErrorDelegateThrowsImpl(key: null,);
  test('Xlink href tests', () {
    /// The namespace for xlink from the SVG 1.1 spec.
    const String kXlinkNamespace = 'http://www.w3.org/1999/xlink';
    final XmlStartElementEvent el =
        parseEvents('<test href="http://localhost" />').first as XmlStartElementEvent;
    final XmlStartElementEvent elXlink = parseEvents('<test xmlns:xlink="$kXlinkNamespace" '
            'xlink:href="http://localhost" />')
        .first as XmlStartElementEvent;
    expect(getHrefAttribute(el.attributes.toAttributeMap().typedGet), 'http://localhost');
    expect(getHrefAttribute(elXlink.attributes.toAttributeMap().typedGet), 'http://localhost');
  });
  test('Attribute and style tests', () {
    final XmlStartElementEvent el = parseEvents('<test stroke="#fff" fill="#eee" stroke-dashpattern="1 2" '
            'style="stroke-opacity:1;fill-opacity:.23" />')
        .first as XmlStartElementEvent;
    final attributes = el.attributes.toAttributeMap().typedGet;
    expect(getAttribute(attributes, 'stroke', def: ''), '#fff');
    expect(getAttribute(attributes, 'fill', def: ''), '#eee');
    expect(getAttribute(attributes, 'stroke-dashpattern', def: ''), '1 2');
    expect(getAttribute(attributes, 'stroke-opacity', def: ''), '1');
    expect(getAttribute(attributes, 'stroke-another', def: ''), '');
    expect(getAttribute(attributes, 'fill-opacity', def: ''), '.23');
    expect(getAttribute(attributes, 'fill-opacity', checkStyle: false, def: ''), '');
    expect(getAttribute(attributes, 'fill', checkStyle: false, def: ''), '#eee');
  });
  // if the parsing logic changes, we can simplify some methods.  for now assert that whitespace in attributes is preserved
  test('Attribute WhiteSpace test', () {
    final XmlStartElementEvent xd =
        parseEvents('<test attr="  asdf" attr2="asdf  " attr3="asdf" />').first as XmlStartElementEvent;
    expect(
      xd.attributes[0].value,
      '  asdf',
      reason: 'XML Parsing implementation no longer preserves leading whitespace in attributes!',
    );
    expect(
      xd.attributes[1].value,
      'asdf  ',
      reason: 'XML Parsing implementation no longer preserves trailing whitespace in attributes!',
    );
  });
  test('viewBox tests', () {
    const DsvgRect rect = DsvgRect.fromLTWH(0.0, 0.0, 100.0, 100.0);
    final XmlStartElementEvent svgWithViewBox =
        parseEvents('<svg viewBox="0 0 100 100" />').first as XmlStartElementEvent;
    final XmlStartElementEvent svgWithViewBoxAndWidthHeight =
        parseEvents('<svg width="50px" height="50px" viewBox="0 0 100 100" />').first as XmlStartElementEvent;
    final XmlStartElementEvent svgWithWidthHeight =
        parseEvents('<svg width="100" height="100" />').first as XmlStartElementEvent;
    final XmlStartElementEvent svgWithViewBoxMinXMinY =
        parseEvents('<svg viewBox="42 56 100 100" />').first as XmlStartElementEvent;
    final XmlStartElementEvent svgWithNoSizeInfo = parseEvents('<svg />').first as XmlStartElementEvent;
    expect(
        parseViewBoxAndDimensions(
          svgWithViewBoxAndWidthHeight.attributes.toAttributeMap().typedGet,
          fontSize: 14.0,
          xHeight: 7.0,
          errorDelegate: errorDelegate,
        )!
            .size,
        const DsvgSize(w: 50, h: 50));
    expect(
      parseViewBoxAndDimensions(
        svgWithViewBox.attributes.toAttributeMap().typedGet,
        fontSize: 14.0,
        xHeight: 7.0,
        errorDelegate: errorDelegate,
      )!
          .viewBoxRect,
      rect,
    );
    expect(
      parseViewBoxAndDimensions(
        svgWithViewBox.attributes.toAttributeMap().typedGet,
        fontSize: 14.0,
        xHeight: 7.0,
        errorDelegate: errorDelegate,
      )!
          .viewBoxOffset,
      const DsvgOffset(x: 0.0, y: 0.0),
    );
    expect(
      parseViewBoxAndDimensions(
        svgWithViewBoxAndWidthHeight.attributes.toAttributeMap().typedGet,
        fontSize: 14.0,
        xHeight: 7.0,
        errorDelegate: errorDelegate,
      )!
          .viewBoxRect,
      rect,
    );
    expect(
      parseViewBoxAndDimensions(
        svgWithWidthHeight.attributes.toAttributeMap().typedGet,
        fontSize: 14.0,
        xHeight: 7.0,
        errorDelegate: errorDelegate,
      )!
          .viewBoxRect,
      rect,
    );
    expect(
      () => parseViewBoxAndDimensions(
        svgWithNoSizeInfo.attributes.toAttributeMap().typedGet,
        fontSize: 14.0,
        xHeight: 7.0,
        errorDelegate: errorDelegate,
      ),
      throwsStateError,
    );
    expect(
      parseViewBoxAndDimensions(
        svgWithViewBoxMinXMinY.attributes.toAttributeMap().typedGet,
        fontSize: 14.0,
        xHeight: 7.0,
        errorDelegate: errorDelegate,
      )!
          .viewBoxRect,
      rect,
    );
    expect(
      parseViewBoxAndDimensions(
        svgWithViewBoxMinXMinY.attributes.toAttributeMap().typedGet,
        fontSize: 14.0,
        xHeight: 7.0,
        errorDelegate: errorDelegate,
      )!
          .viewBoxOffset,
      const DsvgOffset(x: -42.0, y: -56.0),
    );
  });
  test('TileMode tests', () {
    final XmlStartElementEvent pad =
        parseEvents('<linearGradient spreadMethod="pad" />').first as XmlStartElementEvent;
    final XmlStartElementEvent reflect =
        parseEvents('<linearGradient spreadMethod="reflect" />').first as XmlStartElementEvent;
    final XmlStartElementEvent repeat =
        parseEvents('<linearGradient spreadMethod="repeat" />').first as XmlStartElementEvent;
    final XmlStartElementEvent invalid =
        parseEvents('<linearGradient spreadMethod="invalid" />').first as XmlStartElementEvent;
    final XmlStartElementEvent none = parseEvents('<linearGradient />').first as XmlStartElementEvent;
    expect(parseTileMode(pad.attributes.toAttributeMap().typedGet), DsvgTileMode.clamp);
    expect(parseTileMode(invalid.attributes.toAttributeMap().typedGet), DsvgTileMode.clamp);
    expect(parseTileMode(none.attributes.toAttributeMap().typedGet), DsvgTileMode.clamp);
    expect(parseTileMode(reflect.attributes.toAttributeMap().typedGet), DsvgTileMode.mirror);
    expect(parseTileMode(repeat.attributes.toAttributeMap().typedGet), DsvgTileMode.repeated);
  });
  test('@stroke-dashoffset tests', () {
    final XmlStartElementEvent abs =
        parseEvents('<stroke stroke-dashoffset="20" />').first as XmlStartElementEvent;
    final XmlStartElementEvent pct =
        parseEvents('<stroke stroke-dashoffset="20%" />').first as XmlStartElementEvent;
    expect(
      parseDashOffset(
        abs.attributes.toAttributeMap().typedGet,
        fontSize: 14.0,
        xHeight: 7.0,
      ),
      equals(const DsvgDashOffsetAbsolute(value: 20.0)),
    );
    expect(
      parseDashOffset(
        pct.attributes.toAttributeMap().typedGet,
        fontSize: 14.0,
        xHeight: 7.0,
      ),
      equals(const DsvgDashOffsetPercentage(value: 0.2)),
    );
  });
  test('font-weight tests', () {
    expect(parseFontWeight('100'), DsvgFontWeight.w100);
    expect(parseFontWeight('200'), DsvgFontWeight.w200);
    expect(parseFontWeight('300'), DsvgFontWeight.w300);
    expect(parseFontWeight('400'), DsvgFontWeight.w400);
    expect(parseFontWeight('500'), DsvgFontWeight.w500);
    expect(parseFontWeight('600'), DsvgFontWeight.w600);
    expect(parseFontWeight('700'), DsvgFontWeight.w700);
    expect(parseFontWeight('800'), DsvgFontWeight.w800);
    expect(parseFontWeight('900'), DsvgFontWeight.w900);
    expect(parseFontWeight('normal'), DsvgFontWeight.w400);
    expect(parseFontWeight('bold'), DsvgFontWeight.w700);
    expect(() => parseFontWeight('invalid'), throwsUnsupportedError);
  });
  test('font-style tests', () {
    expect(parseFontStyle('normal'), DsvgFontStyle.normal);
    expect(parseFontStyle('italic'), DsvgFontStyle.italic);
    expect(parseFontStyle('oblique'), DsvgFontStyle.italic);
    expect(parseFontStyle(null), isNull);
    expect(() => parseFontStyle('invalid'), throwsUnsupportedError);
  });
  test('text-decoration tests', () {
    expect(parseTextDecoration('none'), DsvgTextDecoration.none);
    expect(parseTextDecoration('line-through'), DsvgTextDecoration.linethrough);
    expect(parseTextDecoration('overline'), DsvgTextDecoration.overline);
    expect(parseTextDecoration('underline'), DsvgTextDecoration.underline);
    expect(parseTextDecoration(null), isNull);
    expect(() => parseTextDecoration('invalid'), throwsUnsupportedError);
  });
  test('text-decoration-style tests', () {
    expect(parseTextDecorationStyle('solid'), DsvgTextDecorationStyle.solid);
    expect(parseTextDecorationStyle('dashed'), DsvgTextDecorationStyle.dashed);
    expect(parseTextDecorationStyle('dotted'), DsvgTextDecorationStyle.dotted);
    expect(parseTextDecorationStyle('double'), DsvgTextDecorationStyle.double);
    expect(parseTextDecorationStyle('wavy'), DsvgTextDecorationStyle.wavy);
    expect(parseTextDecorationStyle(null), isNull);
    expect(() => parseTextDecorationStyle('invalid'), throwsUnsupportedError);
  });
  group('parseStyle', () {
    test('uses currentColor for stroke color', () {
      const DsvgColor currentColor = DsvgColor(0xFFB0E3BE);
      final XmlStartElementEvent svg =
          parseEvents('<svg stroke="currentColor" />').first as XmlStartElementEvent;
      final DsvgDrawableStyle svgStyle = parseStyle(
        errorDelegate,
        svg.attributes.toAttributeMap().typedGet,
        null,
        null,
        currentColor: currentColor,
        fontSize: 14.0,
        xHeight: 7.0,
      );
      expect(
        svgStyle.stroke?.color,
        equals(currentColor),
      );
    });
    test('uses currentColor for fill color', () {
      const DsvgColor currentColor = DsvgColor(0xFFB0E3BE);
      final XmlStartElementEvent svg =
          parseEvents('<svg fill="currentColor" />').first as XmlStartElementEvent;
      final DsvgDrawableStyle svgStyle = parseStyle(
        errorDelegate,
        svg.attributes.toAttributeMap().typedGet,
        null,
        null,
        currentColor: currentColor,
        fontSize: 14.0,
        xHeight: 7.0,
      );
      expect(
        svgStyle.fill?.color,
        equals(currentColor),
      );
    });
    group('calculates em units based on the font size for', () {
      test('stroke width', () {
        final XmlStartElementEvent svg =
            parseEvents('<circle stroke="green" stroke-width="2em" />').first as XmlStartElementEvent;
        const double fontSize = 26.0;
        final DsvgDrawableStyle svgStyle = parseStyle(
          errorDelegate,
          svg.attributes.toAttributeMap().typedGet,
          null,
          null,
          fontSize: fontSize,
          xHeight: 7.0,
        );
        expect(
          svgStyle.stroke?.strokeWidth,
          equals(fontSize * 2),
        );
      });
      test('dash array', () {
        final XmlStartElementEvent svg = parseEvents(
          '<line x2="10" y2="10" stroke="black" stroke-dasharray="0.2em 0.5em 10" />',
        ).first as XmlStartElementEvent;
        const double fontSize = 26.0;
        final DsvgDrawableStyle svgStyle = parseStyle(
          errorDelegate,
          svg.attributes.toAttributeMap().typedGet,
          null,
          null,
          fontSize: fontSize,
          xHeight: 7.0,
        );
        final CircularIntervalList<double> dashArray = CircularIntervalList<double>(svgStyle.dashArray!);
        expect(
          <double>[
            dashArray.next,
            dashArray.next,
            dashArray.next,
          ],
          equals(<double>[
            fontSize * 0.2,
            fontSize * 0.5,
            10,
          ]),
        );
      });
      test('dash offset', () {
        final XmlStartElementEvent svg = parseEvents(
          '<line x2="5" y2="30" stroke="black" stroke-dasharray="3 1" stroke-dashoffset="0.15em" />',
        ).first as XmlStartElementEvent;
        const double fontSize = 26.0;
        final DsvgDrawableStyle svgStyle = parseStyle(
          errorDelegate,
          svg.attributes.toAttributeMap().typedGet,
          null,
          null,
          fontSize: fontSize,
          xHeight: 7.0,
        );
        expect(
          svgStyle.dashOffset,
          equals(const DsvgDashOffsetAbsolute(value: fontSize * 0.15)),
        );
      });
    });
    group('calculates ex units based on the x-height for', () {
      test('stroke width', () {
        final XmlStartElementEvent svg = parseEvents(
          '<circle stroke="green" stroke-width="2ex" />',
        ).first as XmlStartElementEvent;
        const double fontSize = 26.0;
        const double xHeight = 11.0;
        final DsvgDrawableStyle svgStyle = parseStyle(
          errorDelegate,
          svg.attributes.toAttributeMap().typedGet,
          null,
          null,
          fontSize: fontSize,
          xHeight: xHeight,
        );
        expect(
          svgStyle.stroke?.strokeWidth,
          equals(xHeight * 2),
        );
      });
      test('dash array', () {
        final XmlStartElementEvent svg = parseEvents(
          '<line x2="10" y2="10" stroke="black" stroke-dasharray="0.2ex 0.5ex 10" />',
        ).first as XmlStartElementEvent;
        const double fontSize = 26.0;
        const double xHeight = 11.0;
        final DsvgDrawableStyle svgStyle = parseStyle(
          errorDelegate,
          svg.attributes.toAttributeMap().typedGet,
          null,
          null,
          fontSize: fontSize,
          xHeight: xHeight,
        );
        final CircularIntervalList<double> dashArray = CircularIntervalList<double>(
          svgStyle.dashArray!,
        );
        expect(
          <double>[
            dashArray.next,
            dashArray.next,
            dashArray.next,
          ],
          equals(<double>[
            xHeight * 0.2,
            xHeight * 0.5,
            10,
          ]),
        );
      });
      test('dash offset', () {
        final XmlStartElementEvent svg = parseEvents(
          '<line x2="5" y2="30" stroke="black" stroke-dasharray="3 1" stroke-dashoffset="0.15ex" />',
        ).first as XmlStartElementEvent;
        const double fontSize = 26.0;
        const double xHeight = 11.0;
        final DsvgDrawableStyle svgStyle = parseStyle(
          errorDelegate,
          svg.attributes.toAttributeMap().typedGet,
          null,
          null,
          fontSize: fontSize,
          xHeight: xHeight,
        );
        expect(
          svgStyle.dashOffset,
          equals(const DsvgDashOffsetAbsolute(value: xHeight * 0.15)),
        );
      });
    });
  });
}

/// Extension on List<XmlEventAttribute> for easy conversion to an attribute
/// map.
extension AttributeMapXmlEventAttributeExtension on List<XmlEventAttribute> {
  /// Converts the List<XmlEventAttribute> to an attribute map.
  Map<String, String> toAttributeMap() => <String, String>{
        for (final XmlEventAttribute attribute in this) attribute.localName: attribute.value.trim(),
      };
}
