import 'package:meta/meta.dart';

import 'dsvg_blend_mode.dart';
import 'dsvg_dash_offset.dart';
import 'dsvg_paint.dart';
import 'dsvg_path.dart';
import 'dsvg_path_fill_type.dart';
import 'dsvg_text_style.dart';
import 'hierarchy/dsvg_drawable.dart';

@immutable
class DsvgDrawableStyle {
  const DsvgDrawableStyle({
    final this.stroke,
    final this.dashArray,
    final this.dashOffset,
    final this.fill,
    final this.textStyle,
    final this.pathFillType,
    final this.groupOpacity,
    final this.clipPath,
    final this.mask,
    final this.blendMode,
  });

  /// If not `null` and not `identical` with [emptyDrawablePaint],
  /// will result in a stroke for the rendered DsvgDrawableShape.
  /// Drawn __after__ the [fill].
  final DsvgPaint? stroke;

  /// The dashing array to use for the [stroke], if any.
  final List<double>? dashArray;

  /// The [DsvgDashOffset] to use for where to begin the [dashArray].
  final DsvgDashOffset? dashOffset;

  /// If not `null` and not `identical` with [emptyDrawablePaint],
  /// will result in a fill for the rendered DsvgDrawableShape.  Drawn
  /// __before__ the [stroke].
  final DsvgPaint? fill;

  /// The style to apply to text elements of this drawable or its children.
  final DsvgTextStyle? textStyle;

  /// The fill rule to use for this path.
  final DsvgPathFillType? pathFillType;

  /// The clip to apply, if any.
  final List<DsvgPath>? clipPath;

  /// The mask to apply, if any.
  final DsvgDrawableStyleable? mask;

  /// Controls group level opacity.
  final double? groupOpacity;

  /// The blend mode to apply, if any.
  final DsvgBlendMode? blendMode;

  @override
  String toString() =>
      'DrawableStyle{$stroke,$dashArray,$dashOffset,$fill,$textStyle,$pathFillType,$groupOpacity,$clipPath,$mask}';
}

/// Creates a new [DsvgDrawableStyle] if `parent` is not null, filling in any null
/// properties on this with the properties from other (except [groupOpacity],
/// is not inherited).
DsvgDrawableStyle mergeAndBlendDrawableStyle(
  final DsvgDrawableStyle? parent, {
  final DsvgPaint? fill,
  final DsvgPaint? stroke,
  final List<double>? dashArray,
  final DsvgDashOffset? dashOffset,
  final DsvgTextStyle? textStyle,
  final DsvgPathFillType? pathFillType,
  final double? groupOpacity,
  final List<DsvgPath>? clipPath,
  final DsvgDrawableStyleable? mask,
  final DsvgBlendMode? blendMode,
}) =>
    DsvgDrawableStyle(
      fill: mergeDrawablePaint(fill, parent?.fill),
      stroke: mergeDrawablePaint(stroke, parent?.stroke),
      dashArray: dashArray ?? parent?.dashArray,
      dashOffset: dashOffset ?? parent?.dashOffset,
      textStyle: mergeDrawableTextStyle(textStyle, parent?.textStyle),
      pathFillType: pathFillType ?? parent?.pathFillType,
      groupOpacity: groupOpacity,
      // clips don't make sense to inherit - applied to canvas with save/restore
      // that wraps any potential children
      clipPath: clipPath,
      mask: mask,
      blendMode: blendMode,
    );
