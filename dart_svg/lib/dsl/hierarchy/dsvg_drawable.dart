import 'package:meta/meta.dart';

import '../dsvg_affine_matrix.dart';
import '../dsvg_drawable_text_anchor_position.dart';
import '../dsvg_offset.dart';
import '../dsvg_paragraph.dart';
import '../dsvg_source_location.dart';
import 'dsvg_styleable.dart';

@immutable
abstract class DsvgDrawable {
  R match<R>({
    required final R Function(DsvgDrawableText) text,
    required final R Function(DsvgDrawableStyleable) styleable,
  });
}

class DsvgDrawableText implements DsvgDrawable {
  DsvgDrawableText({
    required final this.id,
    required final this.fillInterior,
    required final this.strokeOutline,
    required final this.positionOffset,
    required final this.offsetAnchor,
    required final this.transform,
    required final this.sourceLocation,
  }) : assert(
          fillInterior != null || strokeOutline != null,
          "Either fill or stroke must not be null.",
        );

  final String? id;
  final DsvgOffset positionOffset;
  final DsvgDrawableTextAnchorPosition offsetAnchor;
  final DsvgParagraph? fillInterior;
  final DsvgParagraph? strokeOutline;
  final DsvgAffineMatrix? transform;
  final DsvgSourceLocation sourceLocation;

  @override
  R match<R>({
    required final R Function(DsvgDrawableText p1) text,
    required final R Function(DsvgDrawableStyleable) styleable,
  }) =>
      text(this);
}

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
