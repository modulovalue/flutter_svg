import 'dart:typed_data';

import 'dsvg_color.dart';
import 'dsvg_drawable.dart';
import 'dsvg_drawable_style.dart';
import 'dsvg_source_location.dart';
import 'dsvg_viewport.dart';

abstract class DsvgParent {
  Z matchParent<Z>({
    required final Z Function(DsvgParentRoot) root,
    required final Z Function(DsvgParentGroup) group,
  });
}

/// The root element of a drawable.
class DsvgParentRoot implements DsvgParent {
  const DsvgParentRoot({
    required final this.id,
    required final this.viewport,
    required final this.sourceLocation,
    required final this.groupData,
  });

  final String? id;
  /// The expected coordinates used by child paths for drawing.
  final DsvgViewport viewport;
  final DsvgSourceLocation? sourceLocation;
  final DsvgGroupData groupData;

  bool get hasDrawableContent => groupData.children.isNotEmpty == true && !viewport.viewBox.isEmpty;

  @override
  Z matchParent<Z>({
    required final Z Function(DsvgParentRoot) root,
    required final Z Function(DsvgParentGroup) group,
  }) =>
      root(this);
}

/// Represents a group of drawing elements that may
/// share a common `transform`, `stroke`, or `fill`.
class DsvgParentGroup implements DsvgParent {
  const DsvgParentGroup({
    required final this.id,
    required final this.sourceLocation,
    required final this.groupData,
  });

  final String? id;
  final DsvgSourceLocation? sourceLocation;
  final DsvgGroupData groupData;

  bool get hasDrawableContent => groupData.children.isNotEmpty;

  @override
  Z matchParent<Z>({
    required final Z Function(DsvgParentRoot) root,
    required final Z Function(DsvgParentGroup) group,
  }) =>
      group(this);
}

class DsvgGroupData {
  final List<DsvgDrawable> children;
  final DsvgDrawableStyle? style;
  final Float64List? transform;

  /// The default color used to provide a potential indirect color value
  /// for the `fill`, `stroke` and `stop-color` of descendant elements.
  ///
  /// See: https://www.w3.org/TR/SVG11/color.html#ColorProperty
  final DsvgColor? color;

  const DsvgGroupData({
    required final this.children,
    required final this.style,
    required final this.transform,
    required final this.color,
  });
}
