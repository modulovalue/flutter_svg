import 'dsvg.dart';

class DsvgParagraph {
  const DsvgParagraph({
    required final this.textValue,
    required final this.style,
    required final this.fill,
    required final this.rootBounds,
  });

  final String textValue;
  final DsvgDrawableStyle style;
  final DsvgPaint? fill;
  final DsvgRect rootBounds;
}
