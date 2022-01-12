import 'package:meta/meta.dart';

import 'dsvg_offset.dart';
import 'dsvg_rect.dart';
import 'dsvg_size.dart';

/// Contains the viewport size and offset for a Drawable.
@immutable
class DsvgViewport {
  /// Creates a new DrawableViewport, which acts as a bounding box for the Drawable
  /// and specifies what offset (if any) the coordinate system needs to be translated by.
  ///
  /// Both `rect` and `offset` must not be null.
  const DsvgViewport(
    final this.size,
    final this.viewBox, {
    final this.viewBoxOffset = const DsvgOffset(
      x: 0.0,
      y: 0.0,
    ),
  });

  /// The offset for all drawing commands in this Drawable.
  final DsvgOffset viewBoxOffset;

  /// A [DsvgRect] representing the viewBox of this DrawableViewport.
  DsvgRect get viewBoxRect => DsvgRect.fromLTWH(
        0.0,
        0.0,
        viewBox.w,
        viewBox.h,
      );

  /// The viewBox size for the drawable.
  final DsvgSize viewBox;

  /// The viewport size of the drawable.
  ///
  /// This may or may not be identical to the
  final DsvgSize size;

  /// The width of the viewport rect.
  double get width => size.w;

  /// The height of the viewport rect.
  double get height => size.h;

  @override
  String toString() => 'DrawableViewport{$size, viewBox: $viewBox, viewBoxOffset: $viewBoxOffset}';
}
