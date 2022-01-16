import 'package:dart_svg/dsl/dsvg.dart';
import 'package:flutter/material.dart';

import 'render_picture.dart';

/// Scales the `canvas` so that the drawing units in this [DsvgDrawable]
/// will scale to the `desiredSize`.
///
/// If the `viewBox` dimensions are not 1:1 with `desiredSize`, will scale to
/// the smaller dimension and translate to center the image along the larger
/// dimension.
void drawableRootScaleCanvasToViewBox(
  final DsvgParentRoot root,
  final Canvas canvas,
  final Size desiredSize,
) {
  final Matrix4 transform = Matrix4.identity();
  if (scaleCanvasToViewBox(
    transform,
    desiredSize,
    dsvgRectToFlutter(root.viewport.viewBoxRect),
    dsvgSizeToFlutter(root.viewport.size),
  )) {
    canvas.transform(transform.storage);
  }
}

/// Clips the canvas to a rect corresponding to the `viewBox`.
void drawableRootClipCanvasToViewBox(
  final DsvgParentRoot root,
  final Canvas canvas,
) =>
    canvas.clipRect(
      dsvgRectToFlutter(
        root.viewport.viewBoxRect,
      ),
    );

Rect dsvgRectToFlutter(
  final DsvgRect rect,
) =>
    Rect.fromLTRB(
      rect.left,
      rect.top,
      rect.right,
      rect.bottom,
    );

Size dsvgSizeToFlutter(
  final DsvgSize size,
) =>
    Size(
      size.w,
      size.h,
    );

ColorFilter? getColorFilter(
  final Color? color,
  final BlendMode colorBlendMode,
) {
  if (color == null) {
    return null;
  } else {
    return ColorFilter.mode(
      color,
      colorBlendMode,
    );
  }
}
