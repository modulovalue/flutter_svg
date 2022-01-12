import 'package:meta/meta.dart';

import 'dsvg_color.dart';
import 'dsvg_gradient.dart';
import 'dsvg_painting_style.dart';
import 'dsvg_stroke_cap.dart';
import 'dsvg_stroke_join.dart';

@immutable
class DsvgPaint {
  const DsvgPaint(
    final this.style, {
    final this.color,
    final this.shader,
    final this.strokeCap,
    final this.strokeJoin,
    final this.strokeMiterLimit,
    final this.strokeWidth,
  });

  final DsvgColor? color;
  final DsvgGradient? shader;
  final DsvgPaintingStyle? style;
  final DsvgStrokeCap? strokeCap;
  final DsvgStrokeJoin? strokeJoin;
  final double? strokeMiterLimit;
  final double? strokeWidth;
}

/// Will merge two DrawablePaints, preferring properties defined in `a` if they're not null.
///
/// If `a` is `identical` with [emptyDrawablePaint], `b` will be ignored.
DsvgPaint? mergeDrawablePaint(
    final DsvgPaint? a,
    final DsvgPaint? b,
    ) {
  if (a == null && b == null) {
    return null;
  } else if (b == null && a != null) {
    return a;
  } else if (identical(a, emptyDrawablePaint) || identical(b, emptyDrawablePaint)) {
    return a ?? b;
  } else if (a == null) {
    return b;
  } else {
    // If we got here, the styles should not be null.
    assert(
    a.style == b!.style,
    'Cannot merge Paints with different PaintStyles; got:\na: $a\nb: $b.',
    );
    return DsvgPaint(
      a.style ?? b!.style,
      color: a.color ?? b!.color,
      shader: a.shader ?? b!.shader,
      strokeCap: a.strokeCap ?? b!.strokeCap,
      strokeJoin: a.strokeJoin ?? b!.strokeJoin,
      strokeMiterLimit: a.strokeMiterLimit ?? b!.strokeMiterLimit,
      strokeWidth: a.strokeWidth ?? b!.strokeWidth,
    );
  }
}

/// An empty [DsvgPaint].
///
/// Used to assist with inheritance of painting properties.
const DsvgPaint emptyDrawablePaint = DsvgPaint(null);

/// Returns whether this paint is null or equivalent to SVGs "none".
bool drawablePaintIsEmpty(
    final DsvgPaint? paint,
    ) =>
    paint == null || paint == emptyDrawablePaint;
