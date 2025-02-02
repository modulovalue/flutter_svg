import 'dart:collection';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml_events.dart' hide parseEvents;

import '../svg/theme.dart';
import '../utilities/errors.dart';
import '../utilities/numbers.dart';
import '../utilities/xml.dart';
import '../vector_drawable.dart';
import 'colors.dart';
import 'parsers.dart';
import 'xml_parsers.dart';

final Set<String> _unhandledElements = <String>{'title', 'desc'};

typedef _ParseFunc = Future<void>? Function(
    SvgParserState parserState, bool warningsAsErrors);
typedef _PathFunc = Path? Function(
    Map<String, String> attributes, double fontSize, double xHeight);

final RegExp _trimPattern = RegExp(r'[\r|\n|\t]');

const Map<String, _ParseFunc> _svgElementParsers = <String, _ParseFunc>{
  'svg': _Elements.svg,
  'g': _Elements.g,
  'a': _Elements.g, // treat as group
  'use': _Elements.use,
  'symbol': _Elements.symbol,
  'mask': _Elements.symbol, // treat as symbol
  'radialGradient': _Elements.radialGradient,
  'linearGradient': _Elements.linearGradient,
  'clipPath': _Elements.clipPath,
  'image': _Elements.image,
  'text': _Elements.text,
};

const Map<String, _PathFunc> _svgPathFuncs = <String, _PathFunc>{
  'circle': _Paths.circle,
  'path': _Paths.path,
  'rect': _Paths.rect,
  'polygon': _Paths.polygon,
  'polyline': _Paths.polyline,
  'ellipse': _Paths.ellipse,
  'line': _Paths.line,
};

Offset _parseCurrentOffset(SvgParserState parserState, Offset? lastOffset) {
  final String? x = parserState.attribute('x', def: null);
  final String? y = parserState.attribute('y', def: null);
  final double fontSize = parserState.fontSize;
  final double xHeight = parserState.xHeight;

  return Offset(
    x != null
        ? parseDoubleWithUnits(
            x,
            fontSize: fontSize,
            xHeight: xHeight,
          )!
        : parseDoubleWithUnits(
              parserState.attribute('dx', def: '0'),
              fontSize: fontSize,
              xHeight: xHeight,
            )! +
            (lastOffset?.dx ?? 0),
    y != null
        ? parseDoubleWithUnits(
            y,
            fontSize: fontSize,
            xHeight: xHeight,
          )!
        : parseDoubleWithUnits(
              parserState.attribute('dy', def: '0'),
              fontSize: fontSize,
              xHeight: xHeight,
            )! +
            (lastOffset?.dy ?? 0),
  );
}

class _TextInfo {
  const _TextInfo(
    this.style,
    this.offset,
    this.transform,
  );

  final DrawableStyle style;
  final Offset offset;
  final Matrix4? transform;

  @override
  String toString() => '$runtimeType{$offset, $style, $transform}';
}

// ignore: avoid_classes_with_only_static_members
class _Elements {
  static Future<void>? svg(SvgParserState parserState, bool warningsAsErrors) {
    final DrawableViewport? viewBox = parseViewBox(
      parserState.attributes,
      fontSize: parserState.fontSize,
      xHeight: parserState.xHeight,
    );

    final String? id = parserState.attribute('id', def: '');

    final Color? color =
        parseColor(parserState.attribute('color', def: null)) ??
            // Fallback to the currentColor from theme if no color is defined
            // on the root SVG element.
            parserState.theme.currentColor;

    // TODO(dnfield): Support nested SVG elements. https://github.com/dnfield/flutter_svg/issues/132
    if (parserState._root != null) {
      const String errorMessage = 'Unsupported nested <svg> element.';
      if (warningsAsErrors) {
        throw UnsupportedError(errorMessage);
      }
      FlutterError.reportError(FlutterErrorDetails(
        exception: UnsupportedError(errorMessage),
        informationCollector: () => <DiagnosticsNode>[
          ErrorDescription(
              'The root <svg> element contained an unsupported nested SVG element.'),
          if (parserState._key != null) ErrorDescription(''),
          if (parserState._key != null)
            DiagnosticsProperty<String>('Picture key', parserState._key),
        ],
        library: 'SVG',
        context: ErrorDescription('in _Element.svg'),
      ));

      parserState._parentDrawables.addLast(
        _SvgGroupTuple(
          'svg',
          DrawableGroup(
            id,
            <Drawable>[],
            parseStyle(
              parserState._key,
              parserState.attributes,
              parserState._definitions,
              viewBox!.viewBoxRect,
              null,
              currentColor: color,
              fontSize: parserState.fontSize,
              xHeight: parserState.xHeight,
            ),
            color: color,
          ),
        ),
      );
      return null;
    }
    parserState._root = DrawableRoot(
      id,
      viewBox!,
      <Drawable>[],
      parserState._definitions,
      parseStyle(
        parserState._key,
        parserState.attributes,
        parserState._definitions,
        viewBox.viewBoxRect,
        null,
        currentColor: color,
        fontSize: parserState.fontSize,
        xHeight: parserState.xHeight,
      ),
      color: color,
    );
    parserState.addGroup(parserState._currentStartElement!, parserState._root);
    return null;
  }

  static Future<void>? g(SvgParserState parserState, bool warningsAsErrors) {
    if (parserState._currentStartElement?.isSelfClosing == true) {
      return null;
    }
    final DrawableParent parent = parserState.currentGroup!;
    final Color? color =
        parseColor(parserState.attribute('color', def: null)) ?? parent.color;

    final DrawableGroup group = DrawableGroup(
      parserState.attribute('id', def: ''),
      <Drawable>[],
      parseStyle(
        parserState._key,
        parserState.attributes,
        parserState._definitions,
        parserState.rootBounds,
        parent.style,
        currentColor: color,
        fontSize: parserState.fontSize,
        xHeight: parserState.xHeight,
      ),
      transform: parseTransform(parserState.attribute('transform'))?.storage,
      color: color,
    );
    parent.children!.add(group);
    parserState.addGroup(parserState._currentStartElement!, group);
    return null;
  }

  static Future<void>? symbol(
      SvgParserState parserState, bool warningsAsErrors) {
    final DrawableParent parent = parserState.currentGroup!;
    final Color? color =
        parseColor(parserState.attribute('color', def: null)) ?? parent.color;

    final DrawableGroup group = DrawableGroup(
      parserState.attribute('id', def: ''),
      <Drawable>[],
      parseStyle(
        parserState._key,
        parserState.attributes,
        parserState._definitions,
        null,
        parent.style,
        currentColor: color,
        fontSize: parserState.fontSize,
        xHeight: parserState.xHeight,
      ),
      transform: parseTransform(parserState.attribute('transform'))?.storage,
      color: color,
    );
    parserState.addGroup(parserState._currentStartElement!, group);
    return null;
  }

  static Future<void>? use(SvgParserState parserState, bool warningsAsErrors) {
    final DrawableParent? parent = parserState.currentGroup;
    final String xlinkHref = getHrefAttribute(parserState.attributes)!;
    if (xlinkHref.isEmpty) {
      return null;
    }

    final DrawableStyle style = parseStyle(
      parserState._key,
      parserState.attributes,
      parserState._definitions,
      parserState.rootBounds,
      parent!.style,
      currentColor: parent.color,
      fontSize: parserState.fontSize,
      xHeight: parserState.xHeight,
    );

    final Matrix4 transform =
        parseTransform(parserState.attribute('transform')) ??
            Matrix4.identity();
    transform.translate(
      parseDoubleWithUnits(
        parserState.attribute('x', def: '0'),
        fontSize: parserState.fontSize,
        xHeight: parserState.xHeight,
      ),
      parseDoubleWithUnits(
        parserState.attribute('y', def: '0'),
        fontSize: parserState.fontSize,
        xHeight: parserState.xHeight,
      )!,
    );

    final DrawableStyleable ref =
        parserState._definitions.getDrawable('url($xlinkHref)')!;
    final DrawableGroup group = DrawableGroup(
      parserState.attribute('id', def: ''),
      <Drawable>[ref.mergeStyle(style)],
      style,
      transform: transform.storage,
    );
    parserState.checkForIri(group);

    parent.children!.add(group);
    return null;
  }

  static Future<void>? parseStops(
    SvgParserState parserState,
    List<Color> colors,
    List<double> offsets,
  ) {
    final DrawableParent parent = parserState.currentGroup!;

    for (XmlEvent event in parserState._readSubtree()) {
      if (event is XmlEndElementEvent) {
        continue;
      }
      if (event is XmlStartElementEvent) {
        final String? rawOpacity = getAttribute(
          parserState.attributes,
          'stop-opacity',
          def: '1',
        );
        final Color stopColor =
            parseColor(getAttribute(parserState.attributes, 'stop-color')) ??
                parent.color ??
                colorBlack;
        colors.add(stopColor.withOpacity(parseDouble(rawOpacity)!));

        final String rawOffset = getAttribute(
          parserState.attributes,
          'offset',
          def: '0%',
        )!;
        offsets.add(parseDecimalOrPercentage(rawOffset));
      }
    }
    return null;
  }

  static Future<void>? radialGradient(
    SvgParserState parserState,
    bool warningsAsErrors,
  ) {
    final double fontSize = parserState.fontSize;
    final double xHeight = parserState.xHeight;
    final String? gradientUnits = getAttribute(
      parserState.attributes,
      'gradientUnits',
      def: null,
    );
    bool isObjectBoundingBox = gradientUnits != 'userSpaceOnUse';

    final String? rawCx = parserState.attribute('cx', def: '50%');
    final String? rawCy = parserState.attribute('cy', def: '50%');
    final String? rawR = parserState.attribute('r', def: '50%');
    final String? rawFx = parserState.attribute('fx', def: rawCx);
    final String? rawFy = parserState.attribute('fy', def: rawCy);
    final TileMode spreadMethod = parseTileMode(parserState.attributes);
    final String id = buildUrlIri(parserState.attributes);
    final Matrix4? originalTransform = parseTransform(
      parserState.attribute('gradientTransform', def: null),
    );

    final List<double> offsets = <double>[];
    final List<Color> colors = <Color>[];

    if (parserState._currentStartElement!.isSelfClosing) {
      final String? href = getHrefAttribute(parserState.attributes);
      final DrawableGradient? ref =
          parserState._definitions.getGradient<DrawableGradient>('url($href)');
      if (ref == null) {
        reportMissingDef(parserState._key, href, 'radialGradient');
      } else {
        if (gradientUnits == null) {
          isObjectBoundingBox =
              ref.unitMode == GradientUnitMode.objectBoundingBox;
        }
        colors.addAll(ref.colors!);
        offsets.addAll(ref.offsets!);
      }
    } else {
      parseStops(parserState, colors, offsets);
    }

    late double cx, cy, r, fx, fy;
    if (isObjectBoundingBox) {
      cx = parseDecimalOrPercentage(rawCx!);
      cy = parseDecimalOrPercentage(rawCy!);
      r = parseDecimalOrPercentage(rawR!);
      fx = parseDecimalOrPercentage(rawFx!);
      fy = parseDecimalOrPercentage(rawFy!);
    } else {
      cx = isPercentage(rawCx!)
          ? parsePercentage(rawCx) * parserState.rootBounds.width +
              parserState.rootBounds.left
          : parseDoubleWithUnits(rawCx, fontSize: fontSize, xHeight: xHeight)!;
      cy = isPercentage(rawCy!)
          ? parsePercentage(rawCy) * parserState.rootBounds.height +
              parserState.rootBounds.top
          : parseDoubleWithUnits(rawCy, fontSize: fontSize, xHeight: xHeight)!;
      r = isPercentage(rawR!)
          ? parsePercentage(rawR) *
              ((parserState.rootBounds.height + parserState.rootBounds.width) /
                  2)
          : parseDoubleWithUnits(rawR, fontSize: fontSize, xHeight: xHeight)!;
      fx = isPercentage(rawFx!)
          ? parsePercentage(rawFx) * parserState.rootBounds.width +
              parserState.rootBounds.left
          : parseDoubleWithUnits(rawFx, fontSize: fontSize, xHeight: xHeight)!;
      fy = isPercentage(rawFy!)
          ? parsePercentage(rawFy) * parserState.rootBounds.height +
              parserState.rootBounds.top
          : parseDoubleWithUnits(rawFy, fontSize: fontSize, xHeight: xHeight)!;
    }

    parserState._definitions.addGradient(
      id,
      DrawableRadialGradient(
        center: Offset(cx, cy),
        radius: r,
        focal: (fx != cx || fy != cy) ? Offset(fx, fy) : Offset(cx, cy),
        focalRadius: 0.0,
        colors: colors,
        offsets: offsets,
        unitMode: isObjectBoundingBox
            ? GradientUnitMode.objectBoundingBox
            : GradientUnitMode.userSpaceOnUse,
        spreadMethod: spreadMethod,
        transform: originalTransform?.storage,
      ),
    );
    return null;
  }

  static Future<void>? linearGradient(
      SvgParserState parserState, bool warningsAsErrors) {
    final double fontSize = parserState.fontSize;
    final double xHeight = parserState.xHeight;
    final String? gradientUnits = getAttribute(
      parserState.attributes,
      'gradientUnits',
      def: null,
    );
    bool isObjectBoundingBox = gradientUnits != 'userSpaceOnUse';

    final String? x1 = parserState.attribute('x1', def: '0%');
    final String? x2 = parserState.attribute('x2', def: '100%');
    final String? y1 = parserState.attribute('y1', def: '0%');
    final String? y2 = parserState.attribute('y2', def: '0%');
    final String id = buildUrlIri(parserState.attributes);
    final Matrix4? originalTransform = parseTransform(
      parserState.attribute('gradientTransform', def: null),
    );
    final TileMode spreadMethod = parseTileMode(parserState.attributes);

    final List<Color> colors = <Color>[];
    final List<double> offsets = <double>[];
    if (parserState._currentStartElement!.isSelfClosing) {
      final String? href = getHrefAttribute(parserState.attributes);
      final DrawableGradient? ref =
          parserState._definitions.getGradient<DrawableGradient>('url($href)');
      if (ref == null) {
        reportMissingDef(parserState._key, href, 'linearGradient');
      } else {
        if (gradientUnits == null) {
          isObjectBoundingBox =
              ref.unitMode == GradientUnitMode.objectBoundingBox;
        }
        colors.addAll(ref.colors!);
        offsets.addAll(ref.offsets!);
      }
    } else {
      parseStops(parserState, colors, offsets);
    }

    Offset fromOffset, toOffset;
    if (isObjectBoundingBox) {
      fromOffset = Offset(
        parseDecimalOrPercentage(x1!),
        parseDecimalOrPercentage(y1!),
      );
      toOffset = Offset(
        parseDecimalOrPercentage(x2!),
        parseDecimalOrPercentage(y2!),
      );
    } else {
      fromOffset = Offset(
        isPercentage(x1!)
            ? parsePercentage(x1) * parserState.rootBounds.width +
                parserState.rootBounds.left
            : parseDoubleWithUnits(x1, fontSize: fontSize, xHeight: xHeight)!,
        isPercentage(y1!)
            ? parsePercentage(y1) * parserState.rootBounds.height +
                parserState.rootBounds.top
            : parseDoubleWithUnits(y1, fontSize: fontSize, xHeight: xHeight)!,
      );

      toOffset = Offset(
        isPercentage(x2!)
            ? parsePercentage(x2) * parserState.rootBounds.width +
                parserState.rootBounds.left
            : parseDoubleWithUnits(x2, fontSize: fontSize, xHeight: xHeight)!,
        isPercentage(y2!)
            ? parsePercentage(y2) * parserState.rootBounds.height +
                parserState.rootBounds.top
            : parseDoubleWithUnits(y2, fontSize: fontSize, xHeight: xHeight)!,
      );
    }

    parserState._definitions.addGradient(
      id,
      DrawableLinearGradient(
        from: fromOffset,
        to: toOffset,
        colors: colors,
        offsets: offsets,
        spreadMethod: spreadMethod,
        unitMode: isObjectBoundingBox
            ? GradientUnitMode.objectBoundingBox
            : GradientUnitMode.userSpaceOnUse,
        transform: originalTransform?.storage,
      ),
    );

    return null;
  }

  static Future<void>? clipPath(
      SvgParserState parserState, bool warningsAsErrors) {
    final String id = buildUrlIri(parserState.attributes);

    final List<Path> paths = <Path>[];
    Path? currentPath;
    for (XmlEvent event in parserState._readSubtree()) {
      if (event is XmlEndElementEvent) {
        continue;
      }
      if (event is XmlStartElementEvent) {
        final _PathFunc? pathFn = _svgPathFuncs[event.name];

        if (pathFn != null) {
          final Path nextPath = applyTransformIfNeeded(
            pathFn(
              parserState.attributes,
              parserState.fontSize,
              parserState.xHeight,
            ),
            parserState.attributes,
          )!;
          nextPath.fillType =
              parseFillRule(parserState.attributes, 'clip-rule')!;
          if (currentPath != null &&
              nextPath.fillType != currentPath.fillType) {
            currentPath = nextPath;
            paths.add(currentPath);
          } else if (currentPath == null) {
            currentPath = nextPath;
            paths.add(currentPath);
          } else {
            currentPath.addPath(nextPath, Offset.zero);
          }
        } else if (event.name == 'use') {
          final String? xlinkHref = getHrefAttribute(parserState.attributes);
          final DrawableStyleable? definitionDrawable =
              parserState._definitions.getDrawable('url($xlinkHref)');

          void extractPathsFromDrawable(Drawable? target) {
            if (target is DrawableShape) {
              paths.add(target.path);
            } else if (target is DrawableGroup) {
              target.children!.forEach(extractPathsFromDrawable);
            }
          }

          extractPathsFromDrawable(definitionDrawable);
        } else {
          final String errorMessage =
              'Unsupported clipPath child ${event.name}';
          if (warningsAsErrors) {
            throw UnsupportedError(errorMessage);
          }
          FlutterError.reportError(FlutterErrorDetails(
            exception: UnsupportedError(errorMessage),
            informationCollector: () => <DiagnosticsNode>[
              ErrorDescription(
                  'The <clipPath> element contained an unsupported child ${event.name}'),
              if (parserState._key != null) ErrorDescription(''),
              if (parserState._key != null)
                DiagnosticsProperty<String>('Picture key', parserState._key),
            ],
            library: 'SVG',
            context: ErrorDescription('in _Element.clipPath'),
          ));
        }
      }
    }
    parserState._definitions.addClipPath(id, paths);
    return null;
  }

  static Future<void> image(
      SvgParserState parserState, bool warningsAsErrors) async {
    final double fontSize = parserState.fontSize;
    final double xHeight = parserState.xHeight;
    final String? href = getHrefAttribute(parserState.attributes);
    if (href == null) {
      return;
    }
    final Offset offset = Offset(
      parseDoubleWithUnits(
        parserState.attribute('x', def: '0'),
        fontSize: fontSize,
        xHeight: xHeight,
      )!,
      parseDoubleWithUnits(
        parserState.attribute('y', def: '0'),
        fontSize: fontSize,
        xHeight: xHeight,
      )!,
    );
    final Size size = Size(
      parseDoubleWithUnits(
        parserState.attribute('width', def: '0'),
        fontSize: fontSize,
        xHeight: xHeight,
      )!,
      parseDoubleWithUnits(
        parserState.attribute('height', def: '0'),
        fontSize: fontSize,
        xHeight: xHeight,
      )!,
    );
    final Image image = await resolveImage(href);
    final DrawableParent parent = parserState._parentDrawables.last.drawable!;
    final DrawableStyle? parentStyle = parent.style;
    final DrawableRasterImage drawable = DrawableRasterImage(
      parserState.attribute('id', def: ''),
      image,
      offset,
      parseStyle(
        parserState._key,
        parserState.attributes,
        parserState._definitions,
        parserState.rootBounds,
        parentStyle,
        currentColor: parent.color,
        fontSize: parserState.fontSize,
        xHeight: parserState.xHeight,
      ),
      size: size,
      transform: parseTransform(parserState.attribute('transform'))?.storage,
    );
    parserState.checkForIri(drawable);

    parserState.currentGroup!.children!.add(drawable);
  }

  static Future<void> text(
      SvgParserState parserState, bool warningsAsErrors) async {
    assert(parserState != null); // ignore: unnecessary_null_comparison
    assert(parserState.currentGroup != null);
    if (parserState._currentStartElement!.isSelfClosing) {
      return;
    }

    // <text>, <tspan> -> Collect styles
    // <tref> TBD - looks like Inkscape supports it, but no browser does.
    // XmlNodeType.TEXT/CDATA -> DrawableText
    // Track the style(s) and offset(s) for <text> and <tspan> elements
    final Queue<_TextInfo> textInfos = ListQueue<_TextInfo>();
    double lastTextWidth = 0;

    void _processText(String value) {
      if (value.isEmpty) {
        return;
      }
      assert(textInfos.isNotEmpty);
      final _TextInfo lastTextInfo = textInfos.last;
      final Paragraph fill = createParagraph(
        value,
        lastTextInfo.style,
        lastTextInfo.style.fill,
      );
      final Paragraph stroke = createParagraph(
        value,
        lastTextInfo.style,
        DrawablePaint.isEmpty(lastTextInfo.style.stroke)
            ? transparentStroke
            : lastTextInfo.style.stroke,
      );
      parserState.currentGroup!.children!.add(
        DrawableText(
          parserState.attribute('id', def: ''),
          fill,
          stroke,
          lastTextInfo.offset,
          lastTextInfo.style.textStyle!.anchor ??
              DrawableTextAnchorPosition.start,
          transform: lastTextInfo.transform?.storage,
        ),
      );
      lastTextWidth = fill.maxIntrinsicWidth;
    }

    void _processStartElement(XmlStartElementEvent event) {
      _TextInfo? lastTextInfo;
      if (textInfos.isNotEmpty) {
        lastTextInfo = textInfos.last;
      }
      final Offset currentOffset = _parseCurrentOffset(
        parserState,
        lastTextInfo?.offset.translate(lastTextWidth, 0),
      );
      Matrix4? transform = parseTransform(parserState.attribute('transform'));
      if (lastTextInfo?.transform != null) {
        if (transform == null) {
          transform = lastTextInfo!.transform;
        } else {
          transform = lastTextInfo!.transform!.multiplied(transform);
        }
      }

      final DrawableStyle? parentStyle =
          lastTextInfo?.style ?? parserState.currentGroup!.style;

      textInfos.add(_TextInfo(
        parseStyle(
          parserState._key,
          parserState.attributes,
          parserState._definitions,
          parserState.rootBounds,
          parentStyle,
          fontSize: parserState.fontSize,
          xHeight: parserState.xHeight,
        ),
        currentOffset,
        transform,
      ));
      if (event.isSelfClosing) {
        textInfos.removeLast();
      }
    }

    _processStartElement(parserState._currentStartElement!);

    for (XmlEvent event in parserState._readSubtree()) {
      if (event is XmlCDATAEvent) {
        _processText(event.text.trim());
      } else if (event is XmlTextEvent) {
        final String? space =
            getAttribute(parserState.attributes, 'space', def: null);
        if (space != 'preserve') {
          _processText(event.text.trim());
        } else {
          _processText(event.text.replaceAll(_trimPattern, ''));
        }
      }
      if (event is XmlStartElementEvent) {
        _processStartElement(event);
      } else if (event is XmlEndElementEvent) {
        textInfos.removeLast();
      }
    }
  }
}

// ignore: avoid_classes_with_only_static_members
class _Paths {
  static Path circle(
    Map<String, String> attributes,
    double fontSize,
    double xHeight,
  ) {
    final double cx = parseDoubleWithUnits(
      getAttribute(attributes, 'cx', def: '0'),
      fontSize: fontSize,
      xHeight: xHeight,
    )!;
    final double cy = parseDoubleWithUnits(
      getAttribute(attributes, 'cy', def: '0'),
      fontSize: fontSize,
      xHeight: xHeight,
    )!;
    final double r = parseDoubleWithUnits(
      getAttribute(attributes, 'r', def: '0'),
      fontSize: fontSize,
      xHeight: xHeight,
    )!;
    final Rect oval = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    return Path()..addOval(oval);
  }

  static Path path(
      Map<String, String> attributes, double fontSize, double xHeight) {
    final String d = getAttribute(attributes, 'd')!;
    return parseSvgPathData(d);
  }

  static Path rect(
      Map<String, String> attributes, double fontSize, double xHeight) {
    final double x = parseDoubleWithUnits(
      getAttribute(attributes, 'x', def: '0'),
      fontSize: fontSize,
      xHeight: xHeight,
    )!;
    final double y = parseDoubleWithUnits(
      getAttribute(attributes, 'y', def: '0'),
      fontSize: fontSize,
      xHeight: xHeight,
    )!;
    final double w = parseDoubleWithUnits(
      getAttribute(attributes, 'width', def: '0'),
      fontSize: fontSize,
      xHeight: xHeight,
    )!;
    final double h = parseDoubleWithUnits(
      getAttribute(attributes, 'height', def: '0'),
      fontSize: fontSize,
      xHeight: xHeight,
    )!;
    final Rect rect = Rect.fromLTWH(x, y, w, h);
    String? rxRaw = getAttribute(attributes, 'rx', def: null);
    String? ryRaw = getAttribute(attributes, 'ry', def: null);
    rxRaw ??= ryRaw;
    ryRaw ??= rxRaw;

    if (rxRaw != null && rxRaw != '') {
      final double rx = parseDoubleWithUnits(
        rxRaw,
        fontSize: fontSize,
        xHeight: xHeight,
      )!;
      final double ry = parseDoubleWithUnits(
        ryRaw,
        fontSize: fontSize,
        xHeight: xHeight,
      )!;

      return Path()..addRRect(RRect.fromRectXY(rect, rx, ry));
    }

    return Path()..addRect(rect);
  }

  static Path? polygon(
      Map<String, String> attributes, double fontSize, double xHeight) {
    return parsePathFromPoints(attributes, true);
  }

  static Path? polyline(
      Map<String, String> attributes, double fontSize, double xHeight) {
    return parsePathFromPoints(attributes, false);
  }

  static Path? parsePathFromPoints(Map<String, String> attributes, bool close) {
    final String? points = getAttribute(attributes, 'points');
    if (points == '') {
      return null;
    }
    final String path = 'M$points${close ? 'z' : ''}';

    return parseSvgPathData(path);
  }

  static Path ellipse(
      Map<String, String> attributes, double fontSize, double xHeight) {
    final double cx = parseDoubleWithUnits(
      getAttribute(attributes, 'cx', def: '0'),
      fontSize: fontSize,
      xHeight: xHeight,
    )!;
    final double cy = parseDoubleWithUnits(
      getAttribute(attributes, 'cy', def: '0'),
      fontSize: fontSize,
      xHeight: xHeight,
    )!;
    final double rx = parseDoubleWithUnits(
      getAttribute(attributes, 'rx', def: '0'),
      fontSize: fontSize,
      xHeight: xHeight,
    )!;
    final double ry = parseDoubleWithUnits(
      getAttribute(attributes, 'ry', def: '0'),
      fontSize: fontSize,
      xHeight: xHeight,
    )!;

    final Rect r = Rect.fromLTWH(cx - rx, cy - ry, rx * 2, ry * 2);
    return Path()..addOval(r);
  }

  static Path line(
      Map<String, String> attributes, double fontSize, double xHeight) {
    final double x1 = parseDoubleWithUnits(
      getAttribute(attributes, 'x1', def: '0'),
      fontSize: fontSize,
      xHeight: xHeight,
    )!;
    final double x2 = parseDoubleWithUnits(
      getAttribute(attributes, 'x2', def: '0'),
      fontSize: fontSize,
      xHeight: xHeight,
    )!;
    final double y1 = parseDoubleWithUnits(
      getAttribute(attributes, 'y1', def: '0'),
      fontSize: fontSize,
      xHeight: xHeight,
    )!;
    final double y2 = parseDoubleWithUnits(
      getAttribute(attributes, 'y2', def: '0'),
      fontSize: fontSize,
      xHeight: xHeight,
    )!;

    return Path()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2);
  }
}

class _SvgGroupTuple {
  _SvgGroupTuple(this.name, this.drawable);

  final String name;
  final DrawableParent? drawable;
}

/// The implementation of [SvgParser].
///
/// Maintains state while pushing an [XmlPushReader] through the SVG tree.
class SvgParserState {
  /// Creates a new [SvgParserState].
  SvgParserState(
    Iterable<XmlEvent> events,
    this.theme,
    this._key,
    this._warningsAsErrors,
  )
  // ignore: unnecessary_null_comparison
  : assert(events != null),
        _eventIterator = events.iterator;

  /// The theme used when parsing SVG elements.
  final SvgTheme theme;

  final Iterator<XmlEvent> _eventIterator;
  final String? _key;
  final bool _warningsAsErrors;
  final DrawableDefinitionServer _definitions = DrawableDefinitionServer();
  final Queue<_SvgGroupTuple> _parentDrawables = ListQueue<_SvgGroupTuple>(10);
  DrawableRoot? _root;
  late Map<String, String> _currentAttributes;
  XmlStartElementEvent? _currentStartElement;

  /// The current depth of the reader in the XML hierarchy.
  int depth = 0;

  void _discardSubtree() {
    final int subtreeStartDepth = depth;
    while (_eventIterator.moveNext()) {
      final XmlEvent event = _eventIterator.current;
      if (event is XmlStartElementEvent && !event.isSelfClosing) {
        depth += 1;
      } else if (event is XmlEndElementEvent) {
        depth -= 1;
        assert(depth >= 0);
      }
      _currentAttributes = <String, String>{};
      _currentStartElement = null;
      if (depth < subtreeStartDepth) {
        return;
      }
    }
  }

  Iterable<XmlEvent> _readSubtree() sync* {
    final int subtreeStartDepth = depth;
    while (_eventIterator.moveNext()) {
      final XmlEvent event = _eventIterator.current;
      bool isSelfClosing = false;
      if (event is XmlStartElementEvent) {
        final Map<String, String> attributeMap =
            event.attributes.toAttributeMap();
        if (getAttribute(attributeMap, 'display') == 'none' ||
            getAttribute(attributeMap, 'visibility') == 'hidden') {
          print('SVG Warning: Discarding:\n\n  $event\n\n'
              'and any children it has since it is not visible.\n'
              'If that element is meant to be visible, the `display` or '
              '`visibility` attributes should be removed.\n'
              'If that element is not meant to be visible, it would be better '
              'to remove it from the SVG file.');
          if (!event.isSelfClosing) {
            depth += 1;
            _discardSubtree();
          }
          continue;
        }
        _currentAttributes = attributeMap;
        _currentStartElement = event;
        depth += 1;
        isSelfClosing = event.isSelfClosing;
      }
      yield event;

      if (isSelfClosing || event is XmlEndElementEvent) {
        depth -= 1;
        assert(depth >= 0);
        _currentAttributes = <String, String>{};
        _currentStartElement = null;
      }
      if (depth < subtreeStartDepth) {
        return;
      }
    }
  }

  /// Drive the [XmlTextReader] to EOF and produce a [DrawableRoot].
  Future<DrawableRoot> parse() async {
    for (XmlEvent event in _readSubtree()) {
      if (event is XmlStartElementEvent) {
        if (startElement(event)) {
          continue;
        }
        final _ParseFunc? parseFunc = _svgElementParsers[event.name];
        await parseFunc?.call(this, _warningsAsErrors);
        if (parseFunc == null) {
          if (!event.isSelfClosing) {
            _discardSubtree();
          }
          assert(() {
            unhandledElement(event);
            return true;
          }());
        }
      } else if (event is XmlEndElementEvent) {
        endElement(event);
      }
    }
    if (_root == null) {
      throw StateError('Invalid SVG data');
    }
    return _root!;
  }

  /// The XML Attributes of the current node in the tree.
  Map<String, String> get attributes => _currentAttributes;

  /// Gets the attribute for the current position of the parser.
  String? attribute(String name, {String? def}) =>
      getAttribute(attributes, name, def: def);

  /// The current group, if any, in the [Drawable] heirarchy.
  DrawableParent? get currentGroup {
    assert(_parentDrawables != null); // ignore: unnecessary_null_comparison
    assert(_parentDrawables.isNotEmpty);
    return _parentDrawables.last.drawable;
  }

  /// The root bounds of the drawable.
  Rect get rootBounds {
    assert(_root != null, 'Cannot get rootBounds with null root');
    assert(_root!.viewport != null); // ignore: unnecessary_null_comparison
    return _root!.viewport.viewBoxRect;
  }

  /// Whether this [DrawableStyleable] belongs in the [DrawableDefinitions] or not.
  bool checkForIri(DrawableStyleable? drawable) {
    final String iri = buildUrlIri(attributes);
    if (iri != emptyUrlIri) {
      _definitions.addDrawable(iri, drawable!);
      return true;
    }
    return false;
  }

  /// Appends a group to the collection.
  void addGroup(XmlStartElementEvent event, DrawableParent? drawable) {
    _parentDrawables.addLast(_SvgGroupTuple(event.name, drawable));
    checkForIri(drawable);
  }

  /// Appends a [DrawableShape] to the [currentGroup].
  bool addShape(XmlStartElementEvent event) {
    final _PathFunc? pathFunc = _svgPathFuncs[event.name];
    if (pathFunc == null) {
      return false;
    }

    final DrawableParent parent = _parentDrawables.last.drawable!;
    final DrawableStyle? parentStyle = parent.style;
    final Path path = pathFunc(attributes, fontSize, xHeight)!;
    final DrawableStyleable drawable = DrawableShape(
      getAttribute(attributes, 'id', def: ''),
      path,
      parseStyle(
        _key,
        attributes,
        _definitions,
        path.getBounds(),
        parentStyle,
        defaultFillColor: colorBlack,
        currentColor: parent.color,
        fontSize: fontSize,
        xHeight: xHeight,
      ),
      transform: parseTransform(getAttribute(attributes, 'transform'))?.storage,
    );
    checkForIri(drawable);
    parent.children!.add(drawable);
    return true;
  }

  /// Potentially handles a starting element.
  bool startElement(XmlStartElementEvent event) {
    if (event.name == 'defs') {
      if (!event.isSelfClosing) {
        addGroup(
          event,
          DrawableGroup(
            '__defs__${event.hashCode}',
            <Drawable>[],
            null,
            color: currentGroup?.color,
            transform: currentGroup?.transform,
          ),
        );
        return true;
      }
    }
    return addShape(event);
  }

  /// Handles the end of an XML element.
  void endElement(XmlEndElementEvent event) {
    if (event.name == _parentDrawables.last.name) {
      _parentDrawables.removeLast();
    }
  }

  /// Prints an error for unhandled elements.
  ///
  /// Will only print an error once for unhandled/unexpected elements, except for
  /// `<style/>`, `<title/>`, and `<desc/>` elements.
  void unhandledElement(XmlStartElementEvent event) {
    final String errorMessage =
        'unhandled element ${event.name}; Picture key: $_key';
    if (_warningsAsErrors) {
      // Throw error instead of log warning.
      throw UnimplementedError(errorMessage);
    }
    if (event.name == 'style') {
      FlutterError.reportError(FlutterErrorDetails(
        exception: UnimplementedError(
            'The <style> element is not implemented in this library.'),
        informationCollector: () => <DiagnosticsNode>[
          ErrorDescription(
              'Style elements are not supported by this library and the requested SVG may not '
              'render as intended.'),
          ErrorHint(
              'If possible, ensure the SVG uses inline styles and/or attributes (which are '
              'supported), or use a preprocessing utility such as svgcleaner to inline the '
              'styles for you.'),
          ErrorDescription(''),
          DiagnosticsProperty<String>('Picture key', _key),
        ],
        library: 'SVG',
        context: ErrorDescription('in parseSvgElement'),
      ));
    } else if (_unhandledElements.add(event.name)) {
      print(errorMessage);
    }
  }
}

extension on SvgParserState {
  /// Retrieves the font size of the current [theme].
  double get fontSize => theme.fontSize;

  /// Retrieves the x-height of the current [theme].
  double get xHeight => theme.xHeight;
}
