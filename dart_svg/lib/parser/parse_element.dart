import 'dart:collection';

import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml_events.dart';

import '../dsl/dsvg.dart';
import '../parser/parse_attribute.dart';
import '../parser/parse_color.dart';
import '../parser/parse_decimal_or_percentage.dart';
import '../parser/parse_double.dart';
import '../parser/parse_double_with_units.dart';
import '../parser/parse_href.dart';
import '../parser/parse_iri.dart';
import '../parser/parse_path.dart';
import '../parser/parse_percentage.dart';
import '../parser/parse_transform.dart';
import '../parser/parse_viewbox.dart';
import '../util/event_to_source_location.dart';
import 'parse_fill_rule.dart';
import 'parse_style.dart';
import 'parse_tile_mode.dart';
import 'parser_state.dart';

SuccessfullyHandled? parseElement({
  required final DsvgTheme theme,
  required final SvgParserState parserState,
  required final SvgErrorDelegate errorDelegate,
  required final XmlStartElementEvent event,
}) {
  final elementName = event.name;
  String? attribute(
    final String name, {
    final String? def,
  }) =>
      getAttribute(
        parserState.currentAttributes,
        name,
        def: def,
      );

  DsvgOffset _parseCurrentOffset(
    final SvgParserState parserState,
    final DsvgOffset? lastOffset,
    final DsvgTheme theme,
  ) {
    final String? x = attribute('x', def: null);
    final String? y = attribute('y', def: null);
    final double fontSize = theme.fontSize;
    final double xHeight = theme.xHeight;
    return DsvgOffset(
      x: () {
        if (x != null) {
          return parseDoubleWithUnits(
            x,
            fontSize: fontSize,
            xHeight: xHeight,
          )!;
        } else {
          return parseDoubleWithUnits(
                attribute('dx', def: '0'),
                fontSize: fontSize,
                xHeight: xHeight,
              )! +
              (lastOffset?.x ?? 0);
        }
      }(),
      y: () {
        if (y != null) {
          return parseDoubleWithUnits(
            y,
            fontSize: fontSize,
            xHeight: xHeight,
          )!;
        } else {
          return parseDoubleWithUnits(
                attribute('dy', def: '0'),
                fontSize: fontSize,
                xHeight: xHeight,
              )! +
              (lastOffset?.y ?? 0);
        }
      }(),
    );
  }

  Future<void>? _parseStops(
    final SvgParserState parserState,
    final List<DsvgColor> colors,
    final List<double> offsets,
  ) {
    final DsvgParent parent = parserState.current!;
    for (final XmlEvent event in parserState.readSubtree()) {
      if (event is XmlStartElementEvent) {
        final String? rawOpacity = getAttribute(
          parserState.currentAttributes,
          'stop-opacity',
          def: '1',
        );
        final DsvgColor stopColor = svgColorStringToColor(
              getAttribute(parserState.currentAttributes, 'stop-color', def: ''),
            ) ??
            parent.matchParent(
              root: (final a) => a.groupData.color,
              group: (final a) => a.groupData.color,
            ) ??
            const DsvgColor(0xFF000000);
        colors.add(stopColor.withOpacity(parseDouble(rawOpacity)!));
        final String rawOffset = getAttribute(
          parserState.currentAttributes,
          'offset',
          def: '0%',
        )!;
        offsets.add(parseDecimalOrPercentage(rawOffset));
      }
    }
    return null;
  }

  void svg() {
    final DsvgViewport? viewBox = parseViewBox(
      parserState.currentAttributes,
      fontSize: theme.fontSize,
      xHeight: theme.xHeight,
      errorDelegate: errorDelegate,
    );
    final String? id = attribute('id', def: '');
    final DsvgColor? color = svgColorStringToColor(
          attribute(
            'color',
            def: null,
          ),
        ) ??
        // Fallback to the currentColor from theme if no color is defined
        // on the root SVG element.
        theme.currentColor;
    // TODO(dnfield): Support nested SVG elements. https://github.com/dnfield/flutter_svg/issues/132
    if (parserState.absoluteRoot != null) {
      errorDelegate.reportUnsupportedNestedSvg();
      parserState.push(
        'svg',
        DsvgParentGroup(
          id: id,
          sourceLocation: xmlEventToDsvgSourceLocation(
            event: event,
          ),
          groupData: DsvgGroupData(
            children: <DsvgDrawable>[],
            style: parseStyle(
              parserState.errorDelegate,
              parserState.currentAttributes,
              parserState.definitions,
              null,
              currentColor: color,
              fontSize: theme.fontSize,
              xHeight: theme.xHeight,
            ),
            color: color,
            transform: null,
          ),
        ),
      );
    } else {
      parserState.absoluteRoot = DsvgParentRoot(
        sourceLocation: xmlEventToDsvgSourceLocation(
          event: event,
        ),
        id: id,
        viewport: viewBox!,
        groupData: DsvgGroupData(
          children: <DsvgDrawable>[],
          style: parseStyle(
            parserState.errorDelegate,
            parserState.currentAttributes,
            parserState.definitions,
            null,
            currentColor: color,
            fontSize: theme.fontSize,
            xHeight: theme.xHeight,
          ),
          color: color,
          transform: null,
        ),
      );
      parserState.push(
        parserState.currentStartElement!.name,
        parserState.absoluteRoot,
      );
    }
  }

  void g() {
    final DsvgParent parent = parserState.current!;
    final DsvgColor? color = svgColorStringToColor(
          attribute(
            'color',
            def: null,
          ),
        ) ??
        parent.matchParent(
          root: (final a) => a.groupData.color,
          group: (final a) => a.groupData.color,
        );
    final DsvgParentGroup group = DsvgParentGroup(
      id: attribute('id', def: ''),
      groupData: DsvgGroupData(
        children: <DsvgDrawable>[],
        style: parseStyle(
          parserState.errorDelegate,
          parserState.currentAttributes,
          parserState.definitions,
          parent.matchParent(
            root: (final a) => a.groupData.style,
            group: (final a) => a.groupData.style,
          ),
          currentColor: color,
          fontSize: theme.fontSize,
          xHeight: theme.xHeight,
        ),
        transform: parseTransform(attribute('transform'))?.storage,
        color: color,
      ),
      sourceLocation: xmlEventToDsvgSourceLocation(
        event: event,
      ),
    );
    if (!parserState.inDefs) {
      parent
          .matchParent(
            root: (final a) => a.groupData.children,
            group: (final a) => a.groupData.children,
          )
          .add(DsvgDrawableStyleable(styleable: DsvgDrawableParent(parent: group)));
    }
    parserState.push(
      parserState.currentStartElement!.name,
      group,
    );
  }

  void use() {
    final DsvgParent? parent = parserState.current;
    final String xlinkHref = getHrefAttribute(parserState.currentAttributes)!;
    if (xlinkHref.isNotEmpty) {
      final DsvgDrawableStyle style = parseStyle(
        parserState.errorDelegate,
        parserState.currentAttributes,
        parserState.definitions,
        parent!.matchParent(
          root: (final a) => a.groupData.style,
          group: (final a) => a.groupData.style,
        ),
        currentColor: parent.matchParent(
          root: (final a) => a.groupData.color,
          group: (final a) => a.groupData.color,
        ),
        fontSize: theme.fontSize,
        xHeight: theme.xHeight,
      );
      final Matrix4 transform = parseTransform(attribute('transform')) ?? Matrix4.identity();
      transform.translate(
        parseDoubleWithUnits(
          attribute('x', def: '0'),
          fontSize: theme.fontSize,
          xHeight: theme.xHeight,
        ),
        parseDoubleWithUnits(
          attribute('y', def: '0'),
          fontSize: theme.fontSize,
          xHeight: theme.xHeight,
        )!,
      );
      final DsvgDrawableStyleable ref = parserState.definitions.getDrawable('url($xlinkHref)')!;
      final DsvgDrawableStyleable<DsvgDrawableParent<DsvgParentGroup>> group = DsvgDrawableStyleable(
        styleable: DsvgDrawableParent(
          parent: DsvgParentGroup(
            sourceLocation: xmlEventToDsvgSourceLocation(
              event: event,
            ),
            id: attribute('id', def: ''),
            groupData: DsvgGroupData(
              children: <DsvgDrawable>[
                DsvgDrawableStyleable(
                  styleable: mergeStyleable(
                    ref.styleable,
                    style,
                  ),
                ),
              ],
              style: style,
              transform: transform.storage,
              color: null,

            ),
          ),
        ),
      );
      final bool isIri = parserState.checkForIri(group);
      if (!parserState.inDefs || !isIri) {
        parent
            .matchParent(
              root: (final a) => a.groupData.children,
              group: (final a) => a.groupData.children,
            )
            .add(group);
      }
    }
  }

  void symbol() {
    final DsvgParent parent = parserState.current!;
    final DsvgColor? color2 = svgColorStringToColor(
          attribute(
            'color',
            def: null,
          ),
        ) ??
        parent.matchParent(
          root: (final a) => a.groupData.color,
          group: (final a) => a.groupData.color,
        );
    parserState.push(
      parserState.currentStartElement!.name,
      DsvgParentGroup(
        sourceLocation: xmlEventToDsvgSourceLocation(
          event: event,
        ),
        id: attribute('id', def: ''),
        groupData: DsvgGroupData(
          children: <DsvgDrawable>[],
          style: parseStyle(
            parserState.errorDelegate,
            parserState.currentAttributes,
            parserState.definitions,
            parent.matchParent(
              root: (final a) => a.groupData.style,
              group: (final a) => a.groupData.style,
            ),
            currentColor: color2,
            fontSize: theme.fontSize,
            xHeight: theme.xHeight,
          ),
          transform: parseTransform(
            attribute('transform'),
          )?.storage,
          color: color2,
        ),
      ),
    );
  }

  void radialGradient() {
    final double fontSize = theme.fontSize;
    final double xHeight = theme.xHeight;
    final String? gradientUnits = getAttribute(
      parserState.currentAttributes,
      'gradientUnits',
      def: null,
    );
    bool isObjectBoundingBox = gradientUnits != 'userSpaceOnUse';
    final String? rawCx = attribute('cx', def: '50%');
    final String? rawCy = attribute('cy', def: '50%');
    final String? rawR = attribute('r', def: '50%');
    final String? rawFx = attribute('fx', def: rawCx);
    final String? rawFy = attribute('fy', def: rawCy);
    final DsvgTileMode spreadMethod = parseTileMode(parserState.currentAttributes);
    final String id = parseUrlIri(
      attributes: parserState.currentAttributes,
    );
    final Matrix4? originalTransform = parseTransform(
      attribute('gradientTransform', def: null),
    );
    final List<double> offsets = <double>[];
    final List<DsvgColor> colors = <DsvgColor>[];
    if (parserState.currentStartElement!.isSelfClosing) {
      final String? href = getHrefAttribute(parserState.currentAttributes);
      final DsvgGradient? ref = parserState.definitions.getGradient<DsvgGradient>('url($href)');
      if (ref == null) {
        parserState.errorDelegate.reportMissingDef(
          href,
          'radialGradient',
        );
      } else {
        if (gradientUnits == null) {
          isObjectBoundingBox = ref.unitMode == DsvgGradientUnitMode.objectBoundingBox;
        }
        colors.addAll(ref.colors!);
        offsets.addAll(ref.offsets!);
      }
    } else {
      _parseStops(parserState, colors, offsets);
    }
    late double cx, cy, r, fx, fy;
    final DsvgRect rootBounds = parserState.absoluteRoot!.viewport.viewBoxRect;
    if (isObjectBoundingBox) {
      cx = parseDecimalOrPercentage(rawCx!);
      cy = parseDecimalOrPercentage(rawCy!);
      r = parseDecimalOrPercentage(rawR!);
      fx = parseDecimalOrPercentage(rawFx!);
      fy = parseDecimalOrPercentage(rawFy!);
    } else {
      cx = () {
        if (isPercentage(rawCx!)) {
          return parsePercentage(rawCx) * rootBounds.width + rootBounds.left;
        } else {
          return parseDoubleWithUnits(rawCx, fontSize: fontSize, xHeight: xHeight)!;
        }
      }();
      cy = () {
        if (isPercentage(rawCy!)) {
          return parsePercentage(rawCy) * rootBounds.height + rootBounds.top;
        } else {
          return parseDoubleWithUnits(rawCy, fontSize: fontSize, xHeight: xHeight)!;
        }
      }();
      r = () {
        if (isPercentage(rawR!)) {
          return parsePercentage(rawR) * ((rootBounds.height + rootBounds.width) / 2);
        } else {
          return parseDoubleWithUnits(rawR, fontSize: fontSize, xHeight: xHeight)!;
        }
      }();
      fx = () {
        if (isPercentage(rawFx!)) {
          return parsePercentage(rawFx) * rootBounds.width + rootBounds.left;
        } else {
          return parseDoubleWithUnits(rawFx, fontSize: fontSize, xHeight: xHeight)!;
        }
      }();
      fy = () {
        if (isPercentage(rawFy!)) {
          return parsePercentage(rawFy) * rootBounds.height + rootBounds.top;
        } else {
          return parseDoubleWithUnits(rawFy, fontSize: fontSize, xHeight: xHeight)!;
        }
      }();
    }
    parserState.definitions.addGradient(
      id,
      DsvgGradientRadial(
        centerX: cx,
        centerY: cy,
        radius: r,
        focalX: () {
          if (fx != cx || fy != cy) {
            return fx;
          } else {
            return cx;
          }
        }(),
        focalY: () {
          if (fx != cx || fy != cy) {
            return fy;
          } else {
            return cy;
          }
        }(),
        focalRadius: 0.0,
        colors: colors,
        offsets: offsets,
        unitMode: () {
          if (isObjectBoundingBox) {
            return DsvgGradientUnitMode.objectBoundingBox;
          } else {
            return DsvgGradientUnitMode.userSpaceOnUse;
          }
        }(),
        spreadMethod: spreadMethod,
        transform: originalTransform?.storage,
      ),
    );
  }

  void linearGradient() {
    final double fontSize = theme.fontSize;
    final double xHeight = theme.xHeight;
    final String? gradientUnits = getAttribute(
      parserState.currentAttributes,
      'gradientUnits',
      def: null,
    );
    bool isObjectBoundingBox = gradientUnits != 'userSpaceOnUse';
    final String? x1 = attribute('x1', def: '0%');
    final String? x2 = attribute('x2', def: '100%');
    final String? y1 = attribute('y1', def: '0%');
    final String? y2 = attribute('y2', def: '0%');
    final String id = parseUrlIri(attributes: parserState.currentAttributes);
    final Matrix4? originalTransform = parseTransform(
      attribute('gradientTransform', def: null),
    );
    final DsvgTileMode spreadMethod = parseTileMode(parserState.currentAttributes);
    final List<DsvgColor> colors = <DsvgColor>[];
    final List<double> offsets = <double>[];
    if (parserState.currentStartElement!.isSelfClosing) {
      final String? href = getHrefAttribute(parserState.currentAttributes);
      final DsvgGradient? ref = parserState.definitions.getGradient<DsvgGradient>('url($href)');
      if (ref == null) {
        parserState.errorDelegate.reportMissingDef(
          href,
          'linearGradient',
        );
      } else {
        if (gradientUnits == null) {
          isObjectBoundingBox = ref.unitMode == DsvgGradientUnitMode.objectBoundingBox;
        }
        colors.addAll(ref.colors!);
        offsets.addAll(ref.offsets!);
      }
    } else {
      _parseStops(parserState, colors, offsets);
    }
    final DsvgRect rootBounds = parserState.absoluteRoot!.viewport.viewBoxRect;
    DsvgOffset fromOffset;
    DsvgOffset toOffset;
    if (isObjectBoundingBox) {
      fromOffset = DsvgOffset(
        x: parseDecimalOrPercentage(x1!),
        y: parseDecimalOrPercentage(y1!),
      );
      toOffset = DsvgOffset(
        x: parseDecimalOrPercentage(x2!),
        y: parseDecimalOrPercentage(y2!),
      );
    } else {
      fromOffset = DsvgOffset(
        x: () {
          if (isPercentage(x1!)) {
            return parsePercentage(x1) * rootBounds.width + rootBounds.left;
          } else {
            return parseDoubleWithUnits(x1, fontSize: fontSize, xHeight: xHeight)!;
          }
        }(),
        y: () {
          if (isPercentage(y1!)) {
            return parsePercentage(y1) * rootBounds.height + rootBounds.top;
          } else {
            return parseDoubleWithUnits(y1, fontSize: fontSize, xHeight: xHeight)!;
          }
        }(),
      );
      toOffset = DsvgOffset(
        x: () {
          if (isPercentage(x2!)) {
            return parsePercentage(x2) * rootBounds.width + rootBounds.left;
          } else {
            return parseDoubleWithUnits(x2, fontSize: fontSize, xHeight: xHeight)!;
          }
        }(),
        y: () {
          if (isPercentage(y2!)) {
            return parsePercentage(y2) * rootBounds.height + rootBounds.top;
          } else {
            return parseDoubleWithUnits(y2, fontSize: fontSize, xHeight: xHeight)!;
          }
        }(),
      );
    }
    parserState.definitions.addGradient(
      id,
      DsvgGradientLinear(
        gradientStartOffset: fromOffset,
        gradientEndOffset: toOffset,
        colors: colors,
        offsets: offsets,
        spreadMethod: spreadMethod,
        unitMode: () {
          if (isObjectBoundingBox) {
            return DsvgGradientUnitMode.objectBoundingBox;
          } else {
            return DsvgGradientUnitMode.userSpaceOnUse;
          }
        }(),
        transform: originalTransform?.storage,
      ),
    );
  }

  void clipPath() {
    final String id = parseUrlIri(
      attributes: parserState.currentAttributes,
    );
    final List<DsvgPath> paths = <DsvgPath>[];
    DsvgPathFillTypeSet? currentPath;
    for (final XmlEvent event in parserState.readSubtree()) {
      if (event is XmlStartElementEvent) {
        final DsvgPath Function()? pathFn = parsePath(
          pathName: event.name,
          attributes: parserState.currentAttributes,
          fontSize: theme.fontSize,
          xHeight: theme.xHeight,
        );
        if (pathFn != null) {
          final DsvgPathFillTypeSet nextPath = DsvgPathFillTypeSet(
            path: () {
              final Matrix4? transform = parseTransform(
                getAttribute(
                  parserState.currentAttributes,
                  'transform',
                  def: null,
                ),
              );
              if (transform != null) {
                return DsvgPathTransformed(
                  path: pathFn(),
                  transform: transform,
                );
              } else {
                return pathFn();
              }
            }(),
            fillType: parseFillRule(
              parserState.currentAttributes,
              'clip-rule',
            )!,
          );
          if (currentPath != null && nextPath.fillType != currentPath.fillType) {
            currentPath = nextPath;
            paths.add(currentPath);
          } else if (currentPath == null) {
            currentPath = nextPath;
            paths.add(currentPath);
          } else {
            paths.add(nextPath);
          }
        } else if (event.name == 'use') {
          final String? xlinkHref = getHrefAttribute(parserState.currentAttributes);
          final DsvgDrawableStyleable? definitionDrawable =
              parserState.definitions.getDrawable('url($xlinkHref)');
          void extractPathsFromDrawable(DsvgDrawable? target) {
            target?.match(
              text: (final a) {},
              styleable: (final a) => a.styleable.matchStyleable(
                parent: (final a) => a.parent.matchParent(
                  root: (final a) => a.groupData.children.forEach(extractPathsFromDrawable),
                  group: (final a) => a.groupData.children.forEach(extractPathsFromDrawable),
                ),
                rasterImage: (final a) {},
                shape: (final a) {
                  paths.add(
                    a.path,
                  );
                },
              ),
            );
          }

          extractPathsFromDrawable(definitionDrawable);
        } else {
          errorDelegate.reportUnsupportedClipPathChild(event.name);
        }
      }
    }
    parserState.definitions.addClipPath(id, paths);
  }

  void image() {
    final double fontSize = theme.fontSize;
    final double xHeight = theme.xHeight;
    final String? href = getHrefAttribute(parserState.currentAttributes);
    if (href == null) {
      return;
    } else {
      final DsvgOffset offset = DsvgOffset(
        x: parseDoubleWithUnits(
          attribute('x', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!,
        y: parseDoubleWithUnits(
          attribute('y', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!,
      );
      final DsvgSize size = DsvgSize(
        w: parseDoubleWithUnits(
          attribute('width', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!,
        h: parseDoubleWithUnits(
          attribute('height', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!,
      );
      final DsvgParent parent = parserState.current!;
      final DsvgDrawableStyle? parentStyle = parent.matchParent(
        root: (final a) => a.groupData.style,
        group: (final a) => a.groupData.style,
      );
      final DsvgDrawableRasterImage drawable = DsvgDrawableRasterImage(
        id: attribute('id', def: ''),
        imageHref: href,
        topLeftOffset: offset,
        style: parseStyle(
          parserState.errorDelegate,
          parserState.currentAttributes,
          parserState.definitions,
          parentStyle,
          currentColor: parent.matchParent(
            root: (final a) => a.groupData.color,
            group: (final a) => a.groupData.color,
          ),
          fontSize: theme.fontSize,
          xHeight: theme.xHeight,
        ),
        targetSize: size,
        transform: parseTransform(attribute('transform'))?.storage,
      );
      final bool isIri = parserState.checkForIri(
        DsvgDrawableStyleable(styleable: drawable),
      );
      if (!parserState.inDefs || !isIri) {
        parserState.current!
            .matchParent(
              root: (final a) => a.groupData.children,
              group: (final a) => a.groupData.children,
            )
            .add(
              DsvgDrawableStyleable(styleable: drawable),
            );
      }
    }
  }

  void text() {
    assert(
      parserState.current != null,
      "A parent must exist.",
    );
    if (parserState.currentStartElement!.isSelfClosing) {
      return;
    }
    // <text>, <tspan> -> Collect styles
    // <tref> TBD - looks like Inkscape supports it, but no browser does.
    // XmlNodeType.TEXT/CDATA -> DrawableText
    // Track the style(s) and offset(s) for <text> and <tspan> elements
    final Queue<_TextInfo> textInfos = ListQueue<_TextInfo>();
    void _processStartElement(
      final XmlStartElementEvent event,
    ) {
      _TextInfo? lastTextInfo;
      if (textInfos.isNotEmpty) {
        lastTextInfo = textInfos.last;
      }
      final DsvgOffset currentOffset = _parseCurrentOffset(
        parserState,
        lastTextInfo?.offset.translate(0, 0),
        theme,
      );
      Matrix4? transform = parseTransform(attribute('transform'));
      if (lastTextInfo?.transform != null) {
        if (transform == null) {
          transform = lastTextInfo!.transform;
        } else {
          transform = lastTextInfo!.transform!.multiplied(transform);
        }
      }
      final DsvgDrawableStyle? parentStyle = lastTextInfo?.style ??
          parserState.current!.matchParent(
            root: (final a) => a.groupData.style,
            group: (final a) => a.groupData.style,
          );
      textInfos.add(
        _TextInfo(
          parseStyle(
            parserState.errorDelegate,
            parserState.currentAttributes,
            parserState.definitions,
            parentStyle,
            fontSize: theme.fontSize,
            xHeight: theme.xHeight,
          ),
          currentOffset,
          transform,
        ),
      );
      if (event.isSelfClosing) {
        textInfos.removeLast();
      }
    }

    _processStartElement(
      parserState.currentStartElement!,
    );
    final DsvgRect rootBounds = parserState.absoluteRoot!.viewport.viewBoxRect;
    for (final XmlEvent event in parserState.readSubtree()) {
      void _processText(
        final String value,
      ) {
        if (value.isNotEmpty) {
          assert(
            textInfos.isNotEmpty,
            "Text infos can't be empty.",
          );
          final _TextInfo lastTextInfo = textInfos.last;
          final DsvgParagraph fill = DsvgParagraph(
            rootBounds: rootBounds,
            textValue: value,
            style: lastTextInfo.style,
            fill: lastTextInfo.style.fill,
          );
          final DsvgParagraph stroke = DsvgParagraph(
            rootBounds: rootBounds,
            textValue: value,
            style: lastTextInfo.style,
            fill: () {
              if (drawablePaintIsEmpty(lastTextInfo.style.stroke)) {
                // A [DrawablePaint] with a transparent stroke.
                const DsvgPaint transparentStroke = DsvgPaint(
                  DsvgPaintingStyle.stroke,
                  color: DsvgColor(0x0),
                );
                return transparentStroke;
              } else {
                return lastTextInfo.style.stroke;
              }
            }(),
          );
          parserState.current!
              .matchParent(
                root: (final a) => a.groupData.children,
                group: (final a) => a.groupData.children,
              )
              .add(
                DsvgDrawableText(
                  id: attribute('id', def: ''),
                  fill: fill,
                  stroke: stroke,
                  offset: lastTextInfo.offset,
                  anchor: lastTextInfo.style.textStyle!.anchor ?? DsvgDrawableTextAnchorPosition.start,
                  transform: lastTextInfo.transform?.storage,
                  sourceLocation: xmlEventToDsvgSourceLocation(
                    event: event,
                  ),
                ),
              );
        }
      }

      if (event is XmlCDATAEvent) {
        _processText(
          event.text.trim(),
        );
      } else if (event is XmlTextEvent) {
        final String? space = getAttribute(
          parserState.currentAttributes,
          'space',
          def: null,
        );
        if (space != 'preserve') {
          _processText(
            event.text.trim(),
          );
        } else {
          _processText(
            event.text.replaceAll(_trimPattern, ''),
          );
        }
      }
      if (event is XmlStartElementEvent) {
        _processStartElement(
          event,
        );
      } else if (event is XmlEndElementEvent) {
        textInfos.removeLast();
      }
    }
  }

  switch (elementName) {
    case 'svg':
      svg();
      return const SuccessfullyHandled();
    case 'g':
      g();
      return const SuccessfullyHandled();
    case 'a':
      g();
      return const SuccessfullyHandled();
    case 'use':
      use();
      return const SuccessfullyHandled();
    case 'symbol':
      symbol();
      return const SuccessfullyHandled();
    case 'mask':
      symbol();
      return const SuccessfullyHandled();
    case 'radialGradient':
      radialGradient();
      return const SuccessfullyHandled();
    case 'linearGradient':
      linearGradient();
      return const SuccessfullyHandled();
    case 'clipPath':
      clipPath();
      return const SuccessfullyHandled();
    case 'image':
      image();
      return const SuccessfullyHandled();
    case 'text':
      text();
      return const SuccessfullyHandled();
    default:
      return null;
  }
}

class SuccessfullyHandled {
  const SuccessfullyHandled();
}

final RegExp _trimPattern = RegExp(r'[\r|\n|\t]');

class _TextInfo {
  const _TextInfo(
    this.style,
    this.offset,
    this.transform,
  );

  final DsvgDrawableStyle style;
  final DsvgOffset offset;
  final Matrix4? transform;
}
