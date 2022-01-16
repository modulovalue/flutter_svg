// ignore_for_file: prefer_asserts_with_message

import 'dart:convert' hide Codec;
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dart_svg/dsl/dsvg.dart';
import 'package:dart_svg/dsl/dsvg_affine_matrix.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:vector_math/vector_math_64.dart';

import 'io/http/http.dart';
import 'util.dart';

/// Creates a [Picture] from a [DsvgParentRoot].
///
/// Be cautious about not clipping to the ViewBox - you will be
/// allowing your drawing to take more memory than it otherwise would,
/// particularly when it is eventually rasterized.
Future<Picture> renderRootToPicture({
  required final DsvgParentRoot drawableRoot,
  required final bool clipToViewBox,
  required final ColorFilter? colorFilter,
}) async {
  if (drawableRoot.viewport.viewBox.w == 0) {
    throw StateError(
      'Cannot convert to picture with ${drawableRoot.viewport}',
    );
  } else {
    final recorder = PictureRecorder();
    final canvas = Canvas(
      recorder,
      dsvgRectToFlutter(
        drawableRoot.viewport.viewBoxRect,
      ),
    );
    if (colorFilter != null) {
      canvas.saveLayer(
        null,
        Paint()..colorFilter = colorFilter,
      );
    } else {
      canvas.save();
    }
    drawableRootScaleCanvasToViewBox(
      drawableRoot,
      canvas,
      dsvgSizeToFlutter(
        drawableRoot.viewport.viewBox,
      ),
    );
    if (clipToViewBox == true) {
      drawableRootClipCanvasToViewBox(
        drawableRoot,
        canvas,
      );
    }
    await RenderContent.renderRoot(
      a: drawableRoot,
      canvas: canvas,
      renderChild: (final rect, final child) => RenderContent.renderDrawable(
        canvas: canvas,
        drawable: child,
      ),
    );
    canvas.restore();
    return recorder.endRecording();
  }
}

Future<Picture> renderDrawableToPicture({
  required final DsvgDrawable drawable,
  required final Rect bounds,
}) async {
  final recorder = PictureRecorder();
  final canvas = Canvas(
    recorder,
    bounds,
  );
  await RenderContent.renderDrawable(
    canvas: canvas,
    drawable: drawable,
  );
  return recorder.endRecording();
}

abstract class RenderContent {
  // TODO consider taking out the image resolution step outside so that
  // TODO users that are known to not use any images don't have to await.
  static Future<void> renderDrawable({
    required final DsvgDrawable drawable,
    required final Canvas canvas,
  }) =>
      drawable.match(
        text: (final a) => RenderContent.renderText(
          a: a,
          canvas: canvas,
        ),
        styleable: (final a) => a.styleable.matchStyleable(
          parent: (final a) => a.parent.matchParent(
            root: (final a) => RenderContent.renderRoot(
              a: a,
              canvas: canvas,
              renderChild: (final rect, final child) => RenderContent.renderDrawable(
                drawable: child,
                canvas: canvas,
              ),
            ),
            group: (final a) => RenderContent.renderGroup(
              a: a,
              canvas: canvas,
              renderChild: (final child) => RenderContent.renderDrawable(
                drawable: child,
                canvas: canvas,
              ),
            ),
          ),
          rasterImage: (final a) => RenderContent.renderImage(
            a: a,
            canvas: canvas,
          ),
          shape: (final a) => RenderContent.renderShape(
            a: a,
            canvas: canvas,
          ),
        ),
      );

  static Future<void> renderGroup({
    required final DsvgParentGroup a,
    required final Canvas canvas,
    required final Future<void> Function(DsvgDrawable) renderChild,
  }) async {
    final _groupData = a.groupData;
    final _children = _groupData.children;
    if (_children.isNotEmpty) {
      final _style = _groupData.style;
      final _transform = _groupData.transform;
      final _mask = _style.mask;
      final _clipPath = _style.clipPath;
      final _blendMode = _style.blendMode;
      Future<void> innerDraw() async {
        if (_style.groupOpacity != 0) {
          if (_transform != null) {
            canvas.save();
            canvas.transform(_transform.toMatrix4().storage);
          }
          bool needsSaveLayer = _mask != null;
          final blendingPaint = Paint();
          final _opacity = _style.groupOpacity;
          if (_opacity != null) {
            if (_opacity != 1.0) {
              blendingPaint.color = Color.fromRGBO(
                0,
                0,
                0,
                _opacity,
              );
              needsSaveLayer = true;
            }
          }
          if (_blendMode != null) {
            blendingPaint.blendMode = _dsvgBlendModeToFlutter(
              _blendMode,
            );
            needsSaveLayer = true;
          }
          if (needsSaveLayer) {
            canvas.saveLayer(null, blendingPaint);
          }
          for (final child in _children) {
            await renderChild(
              child,
            );
          }
          if (_mask != null) {
            canvas.saveLayer(null, _grayscaleDstInPaint);
            // TODO the canvas ops should be delegated to the child?
            await renderChild(
              _mask,
            );
            canvas.restore();
          }
          if (needsSaveLayer) {
            canvas.restore();
          }
          if (_transform != null) {
            canvas.restore();
          }
        }
      }

      if (_clipPath != null) {
        if (_clipPath.isNotEmpty) {
          for (final clipPath in _clipPath) {
            canvas.save();
            canvas.clipPath(
              _dsvgPathToFlutterPath(
                path: clipPath,
              ),
            );
            if (_children.length > 1) {
              canvas.saveLayer(null, Paint());
            }
            // TODO the canvas ops should be delegated to the child?
            await innerDraw();
            if (_children.length > 1) {
              canvas.restore();
            }
            canvas.restore();
          }
        } else {
          await innerDraw();
        }
      } else {
        await innerDraw();
      }
    }
  }

  static Future<void> renderRoot({
    required final DsvgParentRoot a,
    required final Canvas canvas,
    required final Future<void> Function(Rect, DsvgDrawable) renderChild,
  }) async {
    final groupData = a.groupData;
    final _children = groupData.children;
    final _viewport = a.viewport;
    if (_children.isNotEmpty) {
      if (!_viewport.viewBox.isEmpty) {
        canvas.save();
        final _transform = groupData.transform;
        if (_transform != null) {
          canvas.transform(_transform.toMatrix4().storage);
        }
        if (_viewport.viewBoxOffset != const DsvgOffsetZero()) {
          canvas.translate(
            _viewport.viewBoxOffset.x,
            _viewport.viewBoxOffset.y,
          );
        }
        for (final child in _children) {
          // TODO transform and translate should be delegated to the child.
          await renderChild(
            dsvgRectToFlutter(
              _viewport.viewBoxRect,
            ),
            child,
          );
        }
        canvas.restore();
      }
    }
  }

  static Future<void> renderImage({
    required final DsvgDrawableRasterImage a,
    required final Canvas canvas,
  }) async {
    final image = await _resolveImage2(
      href: a.imageHref,
    );
    final imageSize = DsvgSize(
      w: image.width.toDouble(),
      h: image.height.toDouble(),
    );
    DsvgSize? desiredSize = imageSize;
    double scale = 1.0;
    final _targetSize = a.targetSize;
    if (_targetSize != null) {
      desiredSize = a.targetSize;
      scale = min(
        _targetSize.w / image.width,
        _targetSize.h / image.height,
      );
    }
    canvas.save();
    if (scale != 1.0 || a.topLeftOffset != const DsvgOffsetZero()) {
      final halfDesiredSize = DsvgSize(
        w: desiredSize!.w / 2.0,
        h: desiredSize.h / 2.0,
      );
      final scaledHalfImageSize = DsvgSize(
        w: imageSize.w * scale / 2.0,
        h: imageSize.h * scale / 2.0,
      );
      final shift = DsvgOffset(
        x: halfDesiredSize.w - scaledHalfImageSize.w,
        y: halfDesiredSize.h - scaledHalfImageSize.h,
      );
      canvas
        ..save()
        ..translate(a.topLeftOffset.x + shift.x, a.topLeftOffset.y + shift.y)
        ..scale(scale, scale);
    }
    final _transform = a.transform;
    if (_transform != null) {
      canvas.transform(_transform.toMatrix4().storage);
    }
    canvas.drawImage(
      image,
      Offset.zero,
      Paint(),
    );
    canvas.restore();
  }

  static Future<void> renderText({
    required final Canvas canvas,
    required final DsvgDrawableText a,
  }) async {
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
      }
    }

    Paragraph createParagraph(
      final String text,
      final DsvgDrawableStyle style,
      final DsvgPaint? foregroundOverride,
      final DsvgRect rootBounds,
    ) {
      final builder = ParagraphBuilder(
        ParagraphStyle(),
      )
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

    final fill = () {
      final _fill = a.fillInterior;
      if (_fill == null) {
        return null;
      } else {
        return createParagraph(
          _fill.textValue,
          _fill.style,
          _fill.fill,
          _fill.rootBounds,
        );
      }
    }();
    final stroke = () {
      final _stroke = a.strokeOutline;
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
    final hasDrawableContent = (fill?.width ?? 0.0) + (stroke?.width ?? 0.0) > 0.0;
    if (hasDrawableContent) {
      final _transform = a.transform;
      canvas.save();
      if (_transform != null) {
        canvas.transform(_transform.toMatrix4().storage);
      }
      if (fill != null) {
        canvas.drawParagraph(
          fill,
          resolveOffset(
            fill,
            a.offsetAnchor,
            a.positionOffset,
          ),
        );
      }
      if (stroke != null) {
        canvas.drawParagraph(
          stroke,
          resolveOffset(
            stroke,
            a.offsetAnchor,
            a.positionOffset,
          ),
        );
      }
      canvas.restore();
    }
  }

  static Future<void> renderShape({
    required final DsvgDrawableShape a,
    required final Canvas canvas,
  }) async {
    final _path = _dsvgPathToFlutterPath(
      path: a.path,
    );
    final bounds = _path.getBounds();
    // Can't use bounds.isEmpty here because some paths give a 0 width or height
    // see https://skia.org/user/api/SkPath_Reference#SkPath_getBounds
    // can't rely on style because parent style may end up filling or stroking
    // TODO(dnfield): implement display properties - but that should really be done on style.
    final hasDrawableContent = bounds.width + bounds.height > 0;
    if (hasDrawableContent) {
      _path.fillType = _dsvgPathFillTypeToFlutterPathFillType(
        a.style.pathFillType ?? DsvgPathFillType.nonZero,
      );
      // if we have multiple clips to apply, need to wrap this in a loop.
      Future<void> innerDraw() async {
        final _transform = a.transform;
        if (_transform != null) {
          canvas.save();
          canvas.transform(_transform.toMatrix4().storage);
        }
        final _style = a.style;
        final _blendmode = _style.blendMode;
        if (_blendmode != null) {
          canvas.saveLayer(null, Paint()..blendMode = _dsvgBlendModeToFlutter(_blendmode));
        }
        final _mask = _style.mask;
        if (_mask != null) {
          canvas.saveLayer(null, Paint());
        }
        final _fill = _style.fill;
        if (_fill != null) {
          final _style = _fill.style;
          if (_style != null) {
            assert(
              _style == DsvgPaintingStyle.fill,
            );
            canvas.drawPath(
              _path,
              _toFlutterPaint(
                bounds: bounds,
                drawablePaint: _fill,
              ),
            );
          }
        }
        final _stroke = _style.stroke;
        if (_stroke != null) {
          final _strokeStyle = _stroke.style;
          if (_strokeStyle != null) {
            assert(
              _strokeStyle == DsvgPaintingStyle.stroke,
            );
            final _dashArray = _style.dashArray;
            if (_dashArray != null && _dashArray.isNotEmpty) {
              canvas.drawPath(
                dashPath(
                  _path,
                  dashArray: CircularIntervalList<double>(
                    _dashArray,
                  ),
                  dashOffset: _style.dashOffset?.match(
                    absolute: (final a) => DashOffset.absolute(a),
                    percentage: (final a) => DashOffset.percentage(a),
                  ),
                ),
                _toFlutterPaint(
                  bounds: bounds,
                  drawablePaint: _stroke,
                ),
              );
            } else {
              canvas.drawPath(
                _path,
                _toFlutterPaint(
                  bounds: bounds,
                  drawablePaint: _stroke,
                ),
              );
            }
          }
        }
        if (_mask != null) {
          canvas.saveLayer(null, _grayscaleDstInPaint);
          await RenderContent.renderDrawable(
            canvas: canvas,
            drawable: _mask,
          );
          canvas.restore();
          canvas.restore();
        }
        if (_blendmode != null) {
          canvas.restore();
        }
        if (_transform != null) {
          canvas.restore();
        }
      }

      if (a.style.clipPath?.isNotEmpty == true) {
        for (final clip in a.style.clipPath!) {
          canvas.save();
          canvas.clipPath(_dsvgPathToFlutterPath(path: clip));
          await innerDraw();
          canvas.restore();
        }
      } else {
        await innerDraw();
      }
    }
  }

  /// Paint used in masks.
  static final Paint _grayscaleDstInPaint = Paint()
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
}

Path _dsvgPathToFlutterPath({
  required DsvgPath path,
}) =>
    path.match(
      fillTypeSet: (final a) => _dsvgPathToFlutterPath(
        path: a.path,
      )..fillType = _dsvgPathFillTypeToFlutterPathFillType(
          a.fillType,
        ),
      transformed: (final a) => _dsvgPathToFlutterPath(
        path: a.path,
      )..transform(
          a.transform.toMatrix4().storage,
        ),
      circle: (final a) => Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(
              a.cx,
              a.cy,
            ),
            radius: a.r,
          ),
        ),
      path: (final a) {
        final path = parseSvgPathData(a.d);
        final fillType = _dsvgPathFillTypeToFlutterPathFillTypeNull(
          a.fillType,
        );
        if (fillType != null) {
          path.fillType = fillType;
        }
        return path;
      },
      rect: (final a) => Path()
        ..addRect(
          Rect.fromLTWH(
            a.x,
            a.y,
            a.w,
            a.h,
          ),
        ),
      rect2: (final a) => Path()
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
      polyline: (final a) =>
          _parsePathFromPoints(
            a.points,
            false,
          ) ??
          Path(),
      ellipse: (final a) => Path()
        ..addOval(
          Rect.fromLTWH(
            a.cx - a.rx,
            a.cy - a.ry,
            a.rx * 2,
            a.ry * 2,
          ),
        ),
      line: (final a) => Path()
        ..moveTo(a.x1, a.y1)
        ..lineTo(a.x2, a.y2),
    );

/// Creates a [Paint] object from this [DsvgPaint].
Paint _toFlutterPaint({
  required final Rect bounds,
  required final DsvgPaint drawablePaint,
}) {
  final paint = Paint();
  if (drawablePaint.color != null) {
    paint.color = _dsvgColorToFlutterColor(drawablePaint.color!);
  }
  if (drawablePaint.shader != null) {
    paint.shader = drawablePaint.shader!.match(
      radialGradient: (final a) {
        final isObjectBoundingBox = a.unitMode == DsvgGradientUnitMode.objectBoundingBox;
        Matrix4 m4transform = () {
          final _transform = a.transform;
          if (_transform == null) {
            return Matrix4.identity();
          } else {
            return _transform.toMatrix4();
          }
        }();
        if (isObjectBoundingBox) {
          final scale = DsvgAffineMatrixSet(a: bounds.width, b: 0.0, c: 0.0, d: bounds.height, e: 0.0, f: 0.0)
              .toMatrix4();
          final translate =
              DsvgAffineMatrixSet(a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: bounds.left, f: bounds.top).toMatrix4();
          m4transform = translate.multiplied(scale)..multiply(m4transform);
        }
        return Gradient.radial(
          Offset(a.centerX, a.centerY),
          a.radius!,
          a.colors!.map((final a) => _dsvgColorToFlutterColor(a)).toList(),
          a.offsets,
          _dsvgTileModeToFlutter(a.spreadMethod),
          m4transform.storage,
          Offset(a.focalX, a.focalY),
          0.0,
        );
      },
      linearGradient: (final a) {
        final isObjectBoundingBox = a.unitMode == DsvgGradientUnitMode.objectBoundingBox;
        Matrix4 m4transform = () {
          final _transform = a.transform;
          if (_transform == null) {
            return Matrix4.identity();
          } else {
            return _transform.toMatrix4();
          }
        }();
        if (isObjectBoundingBox) {
          final scale = DsvgAffineMatrixSet(a: bounds.width, b: 0.0, c: 0.0, d: bounds.height, e: 0.0, f: 0.0)
              .toMatrix4();
          final translate =
              DsvgAffineMatrixSet(a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: bounds.left, f: bounds.top).toMatrix4();
          m4transform = translate.multiplied(scale)..multiply(m4transform);
        }
        final v3from = m4transform.transform3(
          Vector3(
            a.gradientStartOffset.x,
            a.gradientStartOffset.y,
            0.0,
          ),
        );
        final v3to = m4transform.transform3(
          Vector3(
            a.gradientEndOffset.x,
            a.gradientEndOffset.y,
            0.0,
          ),
        );
        return Gradient.linear(
          Offset(v3from.x, v3from.y),
          Offset(v3to.x, v3to.y),
          a.colors!.map((final a) => _dsvgColorToFlutterColor(a)).toList(),
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

Path? _parsePathFromPoints(
  final String? points,
  final bool close,
) {
  if (points == '') {
    return null;
  } else {
    final path = 'M$points${() {
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
      foreground: () {
        if (foregroundOverride == null) {
          return null;
        } else {
          return _toFlutterPaint(
            bounds: foregroundOverride.key,
            drawablePaint: foregroundOverride.value,
          );
        }
      }(),
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

/// Resolves an image reference, potentially downloading it via HTTP.
Future<Image> _resolveImage2({
  required final String href,
}) async {
  assert(
    href != '',
  );
  Future<Image> decodeImage(
    final Uint8List bytes,
  ) async {
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  if (href.startsWith('http')) {
    final bytes = await httpGet(href);
    return decodeImage(bytes);
  } else if (href.startsWith('data:')) {
    final commaLocation = href.indexOf(',') + 1;
    final bytes = base64.decode(
      href
          .substring(
            commaLocation,
          )
          .replaceAll(
            _whitespacePattern,
            '',
          ),
    );
    return decodeImage(bytes);
  } else {
    throw UnsupportedError(
      'Could not resolve image href: $href',
    );
  }
}

final RegExp _whitespacePattern = RegExp(r'\s');

const ParagraphConstraints _infiniteParagraphConstraints = ParagraphConstraints(
  width: double.infinity,
);
