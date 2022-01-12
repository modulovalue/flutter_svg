import 'dart:typed_data';

import 'dsvg_drawable.dart';
import 'dsvg_drawable_style.dart';
import 'dsvg_offset.dart';
import 'dsvg_parent.dart';
import 'dsvg_path.dart';
import 'dsvg_size.dart';
import 'dsvg_source_location.dart';

abstract class DsvgStyleable {
  Z matchStyleable<Z>({
    required final Z Function(DsvgDrawableParent) parent,
    required final Z Function(DsvgDrawableRasterImage) rasterImage,
    required final Z Function(DsvgDrawableShape) shape,
  });
}

/// A raster image (e.g. PNG, JPEG, or GIF) embedded in the drawable.
class DsvgDrawableRasterImage implements DsvgStyleable {
  const DsvgDrawableRasterImage({
    required final this.id,
    required final this.imageHref,
    required final this.topLeftOffset,
    required final this.style,
    required final this.targetSize,
    required final this.transform,
  });

  final String? id;
  final String imageHref;
  final DsvgOffset topLeftOffset;
  final DsvgSize? targetSize;
  final Float64List? transform;
  final DsvgDrawableStyle style;

  @override
  Z matchStyleable<Z>({
    required final Z Function(DsvgDrawableParent) parent,
    required final Z Function(DsvgDrawableRasterImage) rasterImage,
    required final Z Function(DsvgDrawableShape) shape,
  }) =>
      rasterImage(this);
}

/// Represents a drawing element that will be rendered to the canvas.
class DsvgDrawableShape implements DsvgStyleable {
  const DsvgDrawableShape({
    required final this.id,
    required final this.path,
    required final this.style,
    required final this.transform,
    required final this.sourceLocation,
  });

  final String? id;
  final Float64List? transform;
  final DsvgDrawableStyle style;
  final DsvgPath path;
  final DsvgSourceLocation? sourceLocation;

  @override
  Z matchStyleable<Z>({
    required final Z Function(DsvgDrawableParent) parent,
    required final Z Function(DsvgDrawableRasterImage) rasterImage,
    required final Z Function(DsvgDrawableShape) shape,
  }) =>
      shape(this);
}

/// A [DsvgDrawable] that can have child [DsvgDrawable] and [DsvgDrawableStyle].
class DsvgDrawableParent<T extends DsvgParent> implements DsvgStyleable {
  final T parent;

  const DsvgDrawableParent({
    required final this.parent,
  });

  @override
  Z matchStyleable<Z>({
    required final Z Function(DsvgDrawableParent) parent,
    required final Z Function(DsvgDrawableRasterImage p1) rasterImage,
    required final Z Function(DsvgDrawableShape p1) shape,
  }) =>
      parent(this);
}

/// Creates an instance with merged style information.
T mergeStyleable<T extends DsvgStyleable>(
  final T styleable,
  final DsvgDrawableStyle newStyle,
) =>
    styleable.matchStyleable(
      parent: (final a) => a.parent.matchParent(
        root: (final a) {
          final DsvgDrawableStyle mergedStyle = mergeAndBlendDrawableStyle(
            a.groupData.style,
            fill: newStyle.fill,
            stroke: newStyle.stroke,
            clipPath: newStyle.clipPath,
            mask: newStyle.mask,
            dashArray: newStyle.dashArray,
            dashOffset: newStyle.dashOffset,
            pathFillType: newStyle.pathFillType,
            textStyle: newStyle.textStyle,
          );
          final List<DsvgDrawable> mergedChildren = a.groupData.children.map<DsvgDrawable>(
            (final DsvgDrawable child) {
              if (child is DsvgDrawableStyleable) {
                return DsvgDrawableStyleable(
                  styleable: mergeStyleable<DsvgStyleable>(
                    child.styleable,
                    mergedStyle,
                  ),
                );
              } else {
                return child;
              }
            },
          ).toList();
          return DsvgDrawableParent(
            parent: DsvgParentRoot(
              sourceLocation: a.sourceLocation,
              id: a.id,
              viewport: a.viewport,
              groupData: DsvgGroupData(
                children: mergedChildren,
                style: mergedStyle,
                transform: a.groupData.transform,
                color: null,
              ),
            ),
          ) as T;
        },
        group: (final a) {
          final DsvgDrawableStyle mergedStyle = mergeAndBlendDrawableStyle(
            a.groupData.style,
            fill: newStyle.fill,
            stroke: newStyle.stroke,
            clipPath: newStyle.clipPath,
            dashArray: newStyle.dashArray,
            dashOffset: newStyle.dashOffset,
            pathFillType: newStyle.pathFillType,
            textStyle: newStyle.textStyle,
          );
          final List<DsvgDrawable> mergedChildren = a.groupData.children
              .map<DsvgDrawable>(
                (final DsvgDrawable child) => child.match(
                  text: (final a) => a,
                  styleable: (final a) => DsvgDrawableStyleable(
                    styleable: mergeStyleable(
                      a.styleable,
                      mergedStyle,
                    ),
                  ),
                ),
              )
              .toList();
          return DsvgDrawableParent(
            parent: DsvgParentGroup(
              id: a.id,
              sourceLocation: a.sourceLocation,
              groupData: DsvgGroupData(
                children: mergedChildren,
                style: mergedStyle,
                transform: a.groupData.transform,
                color: null,
              ),
            ),
          ) as T;
        },
      ),
      rasterImage: (final a) => DsvgDrawableRasterImage(
        id: a.id,
        imageHref: a.imageHref,
        topLeftOffset: a.topLeftOffset,
        style: mergeAndBlendDrawableStyle(
          a.style,
          fill: newStyle.fill,
          stroke: newStyle.stroke,
          clipPath: newStyle.clipPath,
          mask: newStyle.mask,
          dashArray: newStyle.dashArray,
          dashOffset: newStyle.dashOffset,
          pathFillType: newStyle.pathFillType,
          textStyle: newStyle.textStyle,
        ),
        targetSize: a.targetSize,
        transform: a.transform,
      ) as T,
      shape: (final a) => DsvgDrawableShape(
        id: a.id,
        path: a.path,
        style: mergeAndBlendDrawableStyle(
          a.style,
          fill: newStyle.fill,
          stroke: newStyle.stroke,
          clipPath: newStyle.clipPath,
          mask: newStyle.mask,
          dashArray: newStyle.dashArray,
          dashOffset: newStyle.dashOffset,
          pathFillType: newStyle.pathFillType,
          textStyle: newStyle.textStyle,
        ),
        transform: a.transform,
        sourceLocation: a.sourceLocation,
      ) as T,
    );
