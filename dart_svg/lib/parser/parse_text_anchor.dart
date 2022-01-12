import '../dsl/dsvg_drawable_text_anchor_position.dart';

/// Parses a `text-anchor` attribute.
DsvgDrawableTextAnchorPosition? parseTextAnchor(
  final String? raw,
) {
  switch (raw) {
    case 'inherit':
      return null;
    case 'middle':
      return DsvgDrawableTextAnchorPosition.middle;
    case 'end':
      return DsvgDrawableTextAnchorPosition.end;
    case 'start':
    default:
      return DsvgDrawableTextAnchorPosition.start;
  }
}
