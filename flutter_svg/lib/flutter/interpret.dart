import 'dart:convert' hide Codec;
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dart_svg/affine_transform.dart';
import 'package:dart_svg/dsl/dsvg.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:vector_math/vector_math_64.dart';

import 'io/http/http.dart';
import 'util.dart';

/// Creates a [Picture] from this [DsvgParentRoot].
///
/// Be cautious about not clipping to the ViewBox - you will be
/// allowing your drawing to take more memory than it otherwise would,
/// particularly when it is eventually rasterized.
Future<Picture> renderDrawableRootToPicture({
  required final DsvgParentRoot drawableRoot,
  required final bool clipToViewBox,
  required final Size? size,
  required final ColorFilter? colorFilter,
}) async {
  if (drawableRoot.viewport.viewBox.w == 0) {
    throw StateError(
      'Cannot convert to picture with ${drawableRoot.viewport}',
    );
  } else {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      dsvgRectToFlutter(
        drawableRoot.viewport.viewBoxRect,
      ),
    );
    if (colorFilter != null) {
      canvas.saveLayer(null, Paint()..colorFilter = colorFilter);
    } else {
      canvas.save();
    }
    if (size != null) {
      drawableRootScaleCanvasToViewBox(
        drawableRoot,
        canvas,
        size,
      );
    }
    if (clipToViewBox == true) {
      drawableRootClipCanvasToViewBox(
        drawableRoot,
        canvas,
      );
    }
    await renderDrawable(
      drawable: DsvgDrawableStyleable<DsvgDrawableParent<DsvgParentRoot>>(
        styleable: DsvgDrawableParent<DsvgParentRoot>(
          parent: drawableRoot,
        ),
      ),
      canvas: canvas,
      bounds: dsvgRectToFlutter(
        drawableRoot.viewport.viewBoxRect,
      ),
    );
    canvas.restore();
    return recorder.endRecording();
  }
}

/// Draws the contents or children of [drawable] to the `canvas`, using
/// the `parentPaint` to optionally override the child's paint.
///
/// The `bounds` specify the area to draw in.
Future<void> renderDrawable({
  required final DsvgDrawable drawable,
  required final Canvas canvas,
  required final Rect bounds,
}) {
  return drawable.match(
    text: (final DsvgDrawableText a) async {
      // Determines the correct location for an [Offset] given laid-out
      // [paragraph] and a [DrawableTextPosition].
      Offset resolveOffset(
        final Paragraph paragraph,
        final DsvgDrawableTextAnchorPosition anchor,
        final DsvgOffset offset,
      ) {
        switch (anchor) {
          case DsvgDrawableTextAnchorPosition.middle:
            return Offset(
              offset.x - paragraph.minIntrinsicWidth / 2,
              offset.y - paragraph.alphabeticBaseline,
            );
          case DsvgDrawableTextAnchorPosition.end:
            return Offset(
              offset.x - paragraph.minIntrinsicWidth,
              offset.y - paragraph.alphabeticBaseline,
            );
          case DsvgDrawableTextAnchorPosition.start:
            return Offset(
              offset.x,
              offset.y - paragraph.alphabeticBaseline,
            );
          default:
            return Offset(
              offset.x,
              offset.y,
            );
        }
      }

      // Creates a [Paragraph] object using the specified [text], [style], and [foregroundOverride].
      Paragraph createParagraph(
        final String text,
        final DsvgDrawableStyle style,
        final DsvgPaint? foregroundOverride,
        final DsvgRect rootBounds,
      ) {
        final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle())
          ..pushStyle(
            _toFlutterTextStyle(
              drawableTextStyle: style.textStyle!,
              foregroundOverride: () {
                if (foregroundOverride == null) {
                  return null;
                } else {
                  return MapEntry<Rect, DsvgPaint>(
                    dsvgRectToFlutter(rootBounds),
                    foregroundOverride,
                  );
                }
              }(),
            ),
          )
          ..addText(text);
        return builder.build()..layout(_infiniteParagraphConstraints);
      }

      final Paragraph? fill = () {
        final DsvgParagraph? _fill = a.fill;
        if (_fill == null) {
          return null;
        } else {
          return createParagraph(_fill.textValue, _fill.style, _fill.fill, _fill.rootBounds);
        }
      }();
      final Paragraph? stroke = () {
        final DsvgParagraph? _stroke = a.stroke;
        if (_stroke == null) {
          return null;
        } else {
          return createParagraph(
            _stroke.textValue,
            _stroke.style,
            _stroke.fill,
            _stroke.rootBounds,
          );
        }
      }();
      final bool hasDrawableContent = (fill?.width ?? 0.0) + (stroke?.width ?? 0.0) > 0.0;
      if (hasDrawableContent) {
        if (a.transform != null) {
          canvas.save();
          canvas.transform(a.transform!);
        }
        if (fill != null) {
          canvas.drawParagraph(
            fill,
            resolveOffset(
              fill,
              a.anchor,
              a.offset,
            ),
          );
        }
        if (stroke != null) {
          canvas.drawParagraph(
            stroke,
            resolveOffset(
              stroke,
              a.anchor,
              a.offset,
            ),
          );
        }
        if (a.transform != null) {
          canvas.restore();
        }
      }
    },
    styleable: (final DsvgDrawableStyleable<DsvgStyleable> a) => a.styleable.matchStyleable(
      parent: (final DsvgDrawableParent<DsvgParent> a) => a.parent.matchParent(
        root: (final DsvgParentRoot a) async {
          if (a.hasDrawableContent) {
            if (a.groupData.transform != null) {
              canvas.save();
              canvas.transform(a.groupData.transform!);
            }
            if (a.viewport.viewBoxOffset != const DsvgOffset(x: 0.0, y: 0.0)) {
              canvas.translate(a.viewport.viewBoxOffset.x, a.viewport.viewBoxOffset.y);
            }
            for (final DsvgDrawable child in a.groupData.children) {
              await renderDrawable(
                drawable: child,
                canvas: canvas,
                bounds: dsvgRectToFlutter(a.viewport.viewBoxRect),
              );
            }
            if (a.groupData.transform != null) {
              canvas.restore();
            }
            if (a.viewport.viewBoxOffset != const DsvgOffset(x: 0.0, y: 0.0)) {
              canvas.restore();
            }
          }
        },
        group: (final DsvgParentGroup a) async {
          if (a.hasDrawableContent) {
            Future<void> innerDraw() async {
              if (a.groupData.style!.groupOpacity == 0) {
                return;
              } else {
                if (a.groupData.transform != null) {
                  canvas.save();
                  canvas.transform(a.groupData.transform!);
                }
                bool needsSaveLayer = a.groupData.style!.mask != null;
                final Paint blendingPaint = Paint();
                if (a.groupData.style!.groupOpacity != null && a.groupData.style!.groupOpacity != 1.0) {
                  blendingPaint.color = Color.fromRGBO(0, 0, 0, a.groupData.style!.groupOpacity!);
                  needsSaveLayer = true;
                }
                if (a.groupData.style!.blendMode != null) {
                  blendingPaint.blendMode = _dsvgBlendModeToFlutter(a.groupData.style!.blendMode!);
                  needsSaveLayer = true;
                }
                if (needsSaveLayer) {
                  canvas.saveLayer(null, blendingPaint);
                }
                for (final DsvgDrawable child in a.groupData.children) {
                  await renderDrawable(
                    drawable: child,
                    canvas: canvas,
                    bounds: bounds,
                  );
                }
                if (a.groupData.style!.mask != null) {
                  canvas.saveLayer(null, _grayscaleDstInPaint);
                  await renderDrawable(
                    drawable: a.groupData.style!.mask!,
                    canvas: canvas,
                    bounds: bounds,
                  );
                  canvas.restore();
                }
                if (needsSaveLayer) {
                  canvas.restore();
                }
                if (a.groupData.transform != null) {
                  canvas.restore();
                }
              }
            }

            if (a.groupData.style?.clipPath?.isNotEmpty == true) {
              for (final DsvgPath clipPath in a.groupData.style!.clipPath!) {
                canvas.save();
                canvas.clipPath(_dsvgPathToFlutterPath(path: clipPath));
                if (a.groupData.children.length > 1) {
                  canvas.saveLayer(null, Paint());
                }
                await innerDraw();
                if (a.groupData.children.length > 1) {
                  canvas.restore();
                }
                canvas.restore();
              }
            } else {
              await innerDraw();
            }
          }
        },
      ),
      rasterImage: (final DsvgDrawableRasterImage a) async {
        final Image image = await _resolveImage2(
          href: a.imageHref,
        );
        // final bool hasDrawableContent = image.height > 0 && image.width > 0;
        final DsvgSize imageSize = DsvgSize(
          w: image.width.toDouble(),
          h: image.height.toDouble(),
        );
        DsvgSize? desiredSize = imageSize;
        double scale = 1.0;
        if (a.targetSize != null) {
          desiredSize = a.targetSize;
          scale = min(
            a.targetSize!.w / image.width,
            a.targetSize!.h / image.height,
          );
        }
        if (scale != 1.0 || a.topLeftOffset != const DsvgOffset(x: 0.0, y: 0.0) || a.transform != null) {
          final DsvgSize halfDesiredSize = DsvgSize(
            w: desiredSize!.w / 2.0,
            h: desiredSize.h / 2.0,
          );
          final DsvgSize scaledHalfImageSize = DsvgSize(
            w: imageSize.w * scale / 2.0,
            h: imageSize.h * scale / 2.0,
          );
          final DsvgOffset shift = DsvgOffset(
            x: halfDesiredSize.w - scaledHalfImageSize.w,
            y: halfDesiredSize.h - scaledHalfImageSize.h,
          );
          canvas.save();
          canvas.translate(a.topLeftOffset.x + shift.x, a.topLeftOffset.y + shift.y);
          canvas.scale(scale, scale);
          if (a.transform != null) {
            canvas.transform(a.transform!);
          }
        }
        canvas.drawImage(image, Offset.zero, Paint());
        if (scale != 1.0 || a.topLeftOffset != const DsvgOffset(x: 0.0, y: 0.0) || a.transform != null) {
          canvas.restore();
        }
      },
      shape: (final DsvgDrawableShape a) async {
        final Path _path = _dsvgPathToFlutterPath(
          path: a.path,
        );
        final Rect bounds = _path.getBounds();
        // Can't use bounds.isEmpty here because some paths give a 0 width or height
        // see https://skia.org/user/api/SkPath_Reference#SkPath_getBounds
        // can't rely on style because parent style may end up filling or stroking
        // TODO(dnfield): implement display properties - but that should really be done on style.
        final bool hasDrawableContent = bounds.width + bounds.height > 0;
        if (hasDrawableContent) {
          _path.fillType = _dsvgPathFillTypeToFlutterPathFillType(
            a.style.pathFillType ?? DsvgPathFillType.nonZero,
          );
          // if we have multiple clips to apply, need to wrap this in a loop.
          Future<void> innerDraw() async {
            if (a.transform != null) {
              canvas.save();
              canvas.transform(a.transform!);
            }
            if (a.style.blendMode != null) {
              canvas.saveLayer(null, Paint()..blendMode = _dsvgBlendModeToFlutter(a.style.blendMode!));
            }
            if (a.style.mask != null) {
              canvas.saveLayer(null, Paint());
            }
            if (a.style.fill?.style != null) {
              assert(a.style.fill!.style == DsvgPaintingStyle.fill);
              canvas.drawPath(
                _path,
                _toFlutterPaint(
                  drawablePaint2: () {
                    if (a.style.fill == null) {
                      return null;
                    } else {
                      return MapEntry<Rect, DsvgPaint>(
                        bounds,
                        a.style.fill!,
                      );
                    }
                  }(),
                )!,
              );
            }
            if (a.style.stroke?.style != null) {
              assert(a.style.stroke!.style == DsvgPaintingStyle.stroke);
              if (a.style.dashArray != null && !identical(a.style.dashArray, <double>[])) {
                canvas.drawPath(
                  dashPath(
                    _path,
                    dashArray: CircularIntervalList<double>(
                      a.style.dashArray!,
                    ),
                    dashOffset: a.style.dashOffset?.match(
                      absolute: (final double a) => DashOffset.absolute(a),
                      percentage: (final double a) => DashOffset.percentage(a),
                    ),
                  ),
                  _toFlutterPaint(
                    drawablePaint2: () {
                      if (a.style.stroke == null) {
                        return null;
                      } else {
                        return MapEntry<Rect, DsvgPaint>(
                          bounds,
                          a.style.stroke!,
                        );
                      }
                    }(),
                  )!,
                );
              } else {
                canvas.drawPath(
                  _path,
                  _toFlutterPaint(
                    drawablePaint2: () {
                      if (a.style.stroke == null) {
                        return null;
                      } else {
                        return MapEntry<Rect, DsvgPaint>(
                          bounds,
                          a.style.stroke!,
                        );
                      }
                    }(),
                  )!,
                );
              }
            }
            if (a.style.mask != null) {
              canvas.saveLayer(null, _grayscaleDstInPaint);
              await renderDrawable(
                drawable: a.style.mask!,
                canvas: canvas,
                bounds: bounds,
              );
              canvas.restore();
              canvas.restore();
            }
            if (a.style.blendMode != null) {
              canvas.restore();
            }
            if (a.transform != null) {
              canvas.restore();
            }
          }

          if (a.style.clipPath?.isNotEmpty == true) {
            for (final DsvgPath clip in a.style.clipPath!) {
              canvas.save();
              canvas.clipPath(_dsvgPathToFlutterPath(path: clip));
              await innerDraw();
              canvas.restore();
            }
          } else {
            await innerDraw();
          }
        }
      },
    ),
  );
}

Path _dsvgPathToFlutterPath({
  required DsvgPath path,
}) {
  return path.match(
    fillTypeSet: (final DsvgPathFillTypeSet a) => _dsvgPathToFlutterPath(
      path: a.path,
    )..fillType = _dsvgPathFillTypeToFlutterPathFillType(
        a.fillType,
      ),
    transformed: (final DsvgPathTransformed a) => _dsvgPathToFlutterPath(
      path: a.path,
    )..transform(
        a.transform.storage,
      ),
    circle: (final DsvgPathCircle a) => Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(
            a.cx,
            a.cy,
          ),
          radius: a.r,
        ),
      ),
    path: (final DsvgPathPath a) {
      final Path path = parseSvgPathData(a.d);
      final PathFillType? fillType = _dsvgPathFillTypeToFlutterPathFillTypeNull(
        a.fillType,
      );
      if (fillType != null) {
        path.fillType = fillType;
      }
      return path;
    },
    rect: (final DsvgPathRect a) => Path()
      ..addRect(
        Rect.fromLTWH(
          a.x,
          a.y,
          a.w,
          a.h,
        ),
      ),
    rect2: (final DsvgPathRect2 a) => Path()
      ..addRRect(
        RRect.fromRectXY(
          Rect.fromLTWH(a.x, a.y, a.w, a.h),
          a.rx,
          a.ry,
        ),
      ),
    polygon: (final DsvgPathPolygon a) =>
        _parsePathFromPoints(
          a.points,
          true,
        ) ??
        Path(),
    polyline: (final DsvgPathPolyline a) =>
        _parsePathFromPoints(
          a.points,
          false,
        ) ??
        Path(),
    ellipse: (final DsvgPathEllipse a) => Path()
      ..addOval(
        Rect.fromLTWH(
          a.cx - a.rx,
          a.cy - a.ry,
          a.rx * 2,
          a.ry * 2,
        ),
      ),
    line: (final DsvgPathLine a) => Path()
      ..moveTo(a.x1, a.y1)
      ..lineTo(a.x2, a.y2),
  );
}

/// Creates a [Paint] object from this [DsvgPaint].
Paint? _toFlutterPaint({
  required final MapEntry<Rect, DsvgPaint>? drawablePaint2,
}) {
  if (drawablePaint2 == null) {
    return null;
  } else {
    final Paint paint = Paint();
    final DsvgPaint drawablePaint = drawablePaint2.value;
    if (drawablePaint.color != null) {
      paint.color = _dsvgColorToFlutterColor(drawablePaint.color!);
    }
    if (drawablePaint.shader != null) {
      final Rect bounds = drawablePaint2.key;
      paint.shader = drawablePaint.shader!.match(
        radialGradient: (final DsvgGradientRadial a) {
          final bool isObjectBoundingBox = a.unitMode == DsvgGradientUnitMode.objectBoundingBox;
          Matrix4 m4transform = () {
            if (a.transform == null) {
              return Matrix4.identity();
            } else {
              return Matrix4.fromFloat64List(a.transform!);
            }
          }();
          if (isObjectBoundingBox) {
            final Matrix4 scale = affineMatrix(bounds.width, 0.0, 0.0, bounds.height, 0.0, 0.0);
            final Matrix4 translate = affineMatrix(1.0, 0.0, 0.0, 1.0, bounds.left, bounds.top);
            m4transform = translate.multiplied(scale)..multiply(m4transform);
          }
          return Gradient.radial(
            Offset(a.centerX, a.centerY),
            a.radius!,
            a.colors!.map((final DsvgColor a) => _dsvgColorToFlutterColor(a)).toList(),
            a.offsets,
            _dsvgTileModeToFlutter(a.spreadMethod),
            m4transform.storage,
            Offset(a.focalX, a.focalY),
            0.0,
          );
        },
        linearGradient: (final DsvgGradientLinear a) {
          final bool isObjectBoundingBox = a.unitMode == DsvgGradientUnitMode.objectBoundingBox;
          Matrix4 m4transform = () {
            if (a.transform == null) {
              return Matrix4.identity();
            } else {
              return Matrix4.fromFloat64List(a.transform!);
            }
          }();
          if (isObjectBoundingBox) {
            final Matrix4 scale = affineMatrix(bounds.width, 0.0, 0.0, bounds.height, 0.0, 0.0);
            final Matrix4 translate = affineMatrix(1.0, 0.0, 0.0, 1.0, bounds.left, bounds.top);
            m4transform = translate.multiplied(scale)..multiply(m4transform);
          }
          final Vector3 v3from = m4transform.transform3(
            Vector3(
              a.gradientStartOffset.x,
              a.gradientStartOffset.y,
              0.0,
            ),
          );
          final Vector3 v3to = m4transform.transform3(
            Vector3(
              a.gradientEndOffset.x,
              a.gradientEndOffset.y,
              0.0,
            ),
          );
          return Gradient.linear(
            Offset(v3from.x, v3from.y),
            Offset(v3to.x, v3to.y),
            a.colors!.map((final DsvgColor a) => _dsvgColorToFlutterColor(a)).toList(),
            a.offsets,
            _dsvgTileModeToFlutter(a.spreadMethod),
          );
        },
      );
    }
    if (drawablePaint.strokeCap != null) {
      paint.strokeCap = _dsvgStrokeCapToFlutterStrokeCap(drawablePaint.strokeCap!);
    }
    if (drawablePaint.strokeJoin != null) {
      paint.strokeJoin = _dsvgStrokeCapToFlutterStrokeJoin(drawablePaint.strokeJoin!);
    }
    if (drawablePaint.strokeMiterLimit != null) {
      paint.strokeMiterLimit = drawablePaint.strokeMiterLimit!;
    }
    if (drawablePaint.strokeWidth != null) {
      paint.strokeWidth = drawablePaint.strokeWidth!;
    }
    if (drawablePaint.style != null) {
      paint.style = _dsvgStrokeCapToFlutterPaintingStyle(drawablePaint.style!);
    }
    return paint;
  }
}

Path? _parsePathFromPoints(
  final String? points,
  final bool close,
) {
  if (points == '') {
    return null;
  } else {
    final String path = 'M$points${() {
      if (close) {
        return 'z';
      } else {
        return '';
      }
    }()}';
    return parseSvgPathData(path);
  }
}

FontStyle _dsvgFontStyleToFlutterFontStyle(
  final DsvgFontStyle style,
) {
  switch (style) {
    case DsvgFontStyle.normal:
      return FontStyle.normal;
    case DsvgFontStyle.italic:
      return FontStyle.italic;
  }
}

FontStyle? _dsvgFontStyleToFlutterFontStyleNull(
  final DsvgFontStyle? style,
) {
  if (style == null) {
    return null;
  } else {
    _dsvgFontStyleToFlutterFontStyle(style);
  }
}

Color _dsvgColorToFlutterColor(
  final DsvgColor color,
) =>
    Color(color.value);

Color? _dsvgColorToFlutterColorNull(
  final DsvgColor? color,
) {
  if (color == null) {
    return null;
  } else {
    return _dsvgColorToFlutterColor(
      color,
    );
  }
}

StrokeCap _dsvgStrokeCapToFlutterStrokeCap(
  final DsvgStrokeCap strokeCap,
) {
  switch (strokeCap) {
    case DsvgStrokeCap.butt:
      return StrokeCap.butt;
    case DsvgStrokeCap.round:
      return StrokeCap.round;
    case DsvgStrokeCap.square:
      return StrokeCap.square;
  }
}

StrokeJoin _dsvgStrokeCapToFlutterStrokeJoin(
  final DsvgStrokeJoin strokeCap,
) {
  switch (strokeCap) {
    case DsvgStrokeJoin.miter:
      return StrokeJoin.miter;
    case DsvgStrokeJoin.round:
      return StrokeJoin.round;
    case DsvgStrokeJoin.bevel:
      return StrokeJoin.bevel;
  }
}

PaintingStyle _dsvgStrokeCapToFlutterPaintingStyle(
  final DsvgPaintingStyle paintingStyle,
) {
  switch (paintingStyle) {
    case DsvgPaintingStyle.fill:
      return PaintingStyle.fill;
    case DsvgPaintingStyle.stroke:
      return PaintingStyle.stroke;
  }
}

/// Creates a Flutter [TextStyle], overriding the foreground if specified.
TextStyle _toFlutterTextStyle({
  required final DsvgTextStyle drawableTextStyle,
  final MapEntry<Rect, DsvgPaint>? foregroundOverride,
}) =>
    TextStyle(
      decoration: _dsvgTextDecorationToFlutterTextDecoration(
        drawableTextStyle.decoration,
      ),
      decorationColor: _dsvgColorToFlutterColorNull(
        drawableTextStyle.decorationColor,
      ),
      decorationStyle: _dsvgTextDecorationStyleToFlutter(
        drawableTextStyle.decorationStyle,
      ),
      fontWeight: _dsvgFontWeightToFlutter(
        drawableTextStyle.fontWeight,
      ),
      fontStyle: _dsvgFontStyleToFlutterFontStyleNull(
        drawableTextStyle.fontStyle,
      ),
      fontFamily: drawableTextStyle.fontFamily,
      fontSize: drawableTextStyle.fontSize,
      height: drawableTextStyle.height,
      foreground: _toFlutterPaint(
        drawablePaint2: foregroundOverride,
      ),
    );

TileMode _dsvgTileModeToFlutter(
  final DsvgTileMode tileMode,
) {
  switch (tileMode) {
    case DsvgTileMode.clamp:
      return TileMode.clamp;
    case DsvgTileMode.repeated:
      return TileMode.repeated;
    case DsvgTileMode.mirror:
      return TileMode.mirror;
  }
}

/// Parses a `text-decoration` attribute value into a [TextDecoration].
TextDecoration? _dsvgTextDecorationToFlutterTextDecoration(
  final DsvgTextDecoration? textDecoration,
) {
  switch (textDecoration) {
    case null:
      return null;
    case DsvgTextDecoration.none:
      return TextDecoration.none;
    case DsvgTextDecoration.underline:
      return TextDecoration.underline;
    case DsvgTextDecoration.overline:
      return TextDecoration.overline;
    case DsvgTextDecoration.linethrough:
      return TextDecoration.lineThrough;
  }
}

PathFillType _dsvgPathFillTypeToFlutterPathFillType(
  final DsvgPathFillType fillType,
) {
  switch (fillType) {
    case DsvgPathFillType.nonZero:
      return PathFillType.nonZero;
    case DsvgPathFillType.evenOdd:
      return PathFillType.evenOdd;
  }
}

PathFillType? _dsvgPathFillTypeToFlutterPathFillTypeNull(
  final DsvgPathFillType? fillType,
) {
  switch (fillType) {
    case null:
      return null;
    case DsvgPathFillType.nonZero:
      return PathFillType.nonZero;
    case DsvgPathFillType.evenOdd:
      return PathFillType.evenOdd;
  }
}

TextDecorationStyle? _dsvgTextDecorationStyleToFlutter(
  final DsvgTextDecorationStyle? style,
) {
  switch (style) {
    case null:
      return null;
    case DsvgTextDecorationStyle.solid:
      return TextDecorationStyle.solid;
    case DsvgTextDecorationStyle.dashed:
      return TextDecorationStyle.dashed;
    case DsvgTextDecorationStyle.dotted:
      return TextDecorationStyle.dotted;
    case DsvgTextDecorationStyle.double:
      return TextDecorationStyle.double;
    case DsvgTextDecorationStyle.wavy:
      return TextDecorationStyle.wavy;
  }
}

FontWeight? _dsvgFontWeightToFlutter(
  final DsvgFontWeight? fontWeight,
) {
  switch (fontWeight) {
    case null:
      return null;
    case DsvgFontWeight.w100:
      return FontWeight.w100;
    case DsvgFontWeight.w200:
      return FontWeight.w200;
    case DsvgFontWeight.w300:
      return FontWeight.w300;
    case DsvgFontWeight.w400:
      return FontWeight.w400;
    case DsvgFontWeight.w500:
      return FontWeight.w500;
    case DsvgFontWeight.w600:
      return FontWeight.w600;
    case DsvgFontWeight.w700:
      return FontWeight.w700;
    case DsvgFontWeight.w800:
      return FontWeight.w800;
    case DsvgFontWeight.w900:
      return FontWeight.w900;
  }
}

BlendMode _dsvgBlendModeToFlutter(
  final DsvgBlendMode blendMode,
) {
  switch (blendMode) {
    case DsvgBlendMode.multiply:
      return BlendMode.multiply;
    case DsvgBlendMode.screen:
      return BlendMode.screen;
    case DsvgBlendMode.overlay:
      return BlendMode.overlay;
    case DsvgBlendMode.darken:
      return BlendMode.darken;
    case DsvgBlendMode.lighten:
      return BlendMode.lighten;
    case DsvgBlendMode.colorDodge:
      return BlendMode.colorDodge;
    case DsvgBlendMode.colorBurn:
      return BlendMode.colorBurn;
    case DsvgBlendMode.hardLight:
      return BlendMode.hardLight;
    case DsvgBlendMode.softLight:
      return BlendMode.softLight;
    case DsvgBlendMode.difference:
      return BlendMode.difference;
    case DsvgBlendMode.exclusion:
      return BlendMode.exclusion;
    case DsvgBlendMode.hue:
      return BlendMode.hue;
    case DsvgBlendMode.saturation:
      return BlendMode.saturation;
    case DsvgBlendMode.color:
      return BlendMode.color;
    case DsvgBlendMode.luminosity:
      return BlendMode.luminosity;
  }
}

/// Paint used in masks.
final Paint _grayscaleDstInPaint = Paint()
  ..blendMode = BlendMode.dstIn
// Convert to grayscale (https://www.w3.org/Graphics/Color/sRGB) and use them as transparency
  ..colorFilter = const ColorFilter.matrix(
    <double>[
      0, 0, 0, 0, 0, //
      0, 0, 0, 0, 0,
      0, 0, 0, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
    ],
  );

/// Resolves an image reference, potentially downloading it via HTTP.
Future<Image> _resolveImage2({
  required final String href,
}) async {
  assert(href != '');
  final Future<Image> Function(Uint8List) decodeImage = (Uint8List bytes) async {
    final Codec codec = await instantiateImageCodec(bytes);
    final FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  };
  if (href.startsWith('http')) {
    final Uint8List bytes = await httpGet(href);
    return decodeImage(bytes);
  } else if (href.startsWith('data:')) {
    final int commaLocation = href.indexOf(',') + 1;
    final Uint8List bytes = base64.decode(href.substring(commaLocation).replaceAll(_whitespacePattern, ''));
    return decodeImage(bytes);
  } else {
    throw UnsupportedError('Could not resolve image href: $href');
  }
}

final RegExp _whitespacePattern = RegExp(r'\s');

const ParagraphConstraints _infiniteParagraphConstraints = ParagraphConstraints(
  width: double.infinity,
);
