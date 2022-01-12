import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'dsvg_drawable_text_anchor_position.dart';
import 'dsvg_offset.dart';
import 'dsvg_paragraph.dart';
import 'dsvg_source_location.dart';
import 'dsvg_styleable.dart';

/// Base interface for vector drawing.
@immutable
abstract class DsvgDrawable {
  R match<R>({
    required final R Function(DsvgDrawableText) text,
    required final R Function(DsvgDrawableStyleable) styleable,
  });
}

/// A [DsvgDrawable] for text objects.
class DsvgDrawableText implements DsvgDrawable {
  /// Creates a new [DsvgDrawableText] object.
  ///
  /// One of fill or stroke must be specified.
  DsvgDrawableText({
    required final this.id,
    required final this.fill,
    required final this.stroke,
    required final this.offset,
    required final this.anchor,
    required final this.transform,
    required final this.sourceLocation,
  }) : assert(
          fill != null || stroke != null,
          "Either fill or stroke must not be null.",
        );

  final String? id;

  /// The offset for positioning the text. The [anchor] property controls
  /// how this offset is interpreted.
  final DsvgOffset offset;

  /// The anchor for the offset, i.e. whether it is the start, middle, or end
  /// of the text.
  final DsvgDrawableTextAnchorPosition anchor;

  /// If specified, how to draw the interior portion of the text.
  final DsvgParagraph? fill;

  /// If specified, how to draw the outline of the text.
  final DsvgParagraph? stroke;

  /// A transform to apply when drawing the text.
  final Float64List? transform;

  final DsvgSourceLocation sourceLocation;

  @override
  R match<R>({
    required final R Function(DsvgDrawableText p1) text,
    required final R Function(DsvgDrawableStyleable) styleable,
  }) =>
      text(this);
}

/// A [DsvgDrawable] that can have a DsvgDrawableStyle applied to it.
class DsvgDrawableStyleable<T extends DsvgStyleable> implements DsvgDrawable {
  final T styleable;

  const DsvgDrawableStyleable({
    required final this.styleable,
  });

  @override
  R match<R>({
    required final R Function(DsvgDrawableText p1) text,
    required final R Function(DsvgDrawableStyleable) styleable,
  }) =>
      styleable(this);
}
