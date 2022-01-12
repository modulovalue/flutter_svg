import '../dsl/dsvg.dart';
import '../parser/parse_attribute.dart';
import '../parser/parse_double_with_units.dart';

DsvgPath Function()? parsePath({
  required final String pathName,
  required final Map<String, String> attributes,
  required final double fontSize,
  required final double xHeight,
}) {
  switch (pathName) {
    case 'circle':
      return () {
        final double cx = parseDoubleWithUnits(
          getAttribute(attributes, 'cx', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!;
        final double cy = parseDoubleWithUnits(
          getAttribute(attributes, 'cy', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!;
        final double r = parseDoubleWithUnits(
          getAttribute(attributes, 'r', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!;
        return DsvgPathCircle(
          cx: cx,
          cy: cy,
          r: r,
        );
      };
    case 'path':
      return () {
        final String d = getAttribute(attributes, 'd', def: '')!;
        return DsvgPathPath(
          d: d,
          fillType: null,
        );
      };
    case 'rect':
      return () {
        final double x = parseDoubleWithUnits(
          getAttribute(attributes, 'x', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!;
        final double y = parseDoubleWithUnits(
          getAttribute(attributes, 'y', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!;
        final double w = parseDoubleWithUnits(
          getAttribute(attributes, 'width', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!;
        final double h = parseDoubleWithUnits(
          getAttribute(attributes, 'height', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!;
        String? rxRaw = getAttribute(attributes, 'rx', def: null);
        String? ryRaw = getAttribute(attributes, 'ry', def: null);
        rxRaw ??= ryRaw;
        ryRaw ??= rxRaw;
        if (rxRaw != null && rxRaw != '') {
          final double rx = parseDoubleWithUnits(
            rxRaw,
            fontSize: fontSize,
            xHeight: xHeight,
          )!;
          final double ry = parseDoubleWithUnits(
            ryRaw,
            fontSize: fontSize,
            xHeight: xHeight,
          )!;
          return DsvgPathRect2(
            x: x,
            y: y,
            w: w,
            h: h,
            rx: rx,
            ry: ry,
          );
        } else {
          return DsvgPathRect(
            x: x,
            y: y,
            w: w,
            h: h,
          );
        }
      };
    case 'polygon':
      return () {
        return DsvgPathPolygon(
          points: getAttribute(attributes, 'points', def: ''),
        );
      };
    case 'polyline':
      return () {
        return DsvgPathPolyline(
          points: getAttribute(attributes, 'points', def: ''),
        );
      };
    case 'ellipse':
      return () {
        final double cx = parseDoubleWithUnits(
          getAttribute(attributes, 'cx', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!;
        final double cy = parseDoubleWithUnits(
          getAttribute(attributes, 'cy', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!;
        final double rx = parseDoubleWithUnits(
          getAttribute(attributes, 'rx', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!;
        final double ry = parseDoubleWithUnits(
          getAttribute(attributes, 'ry', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!;
        return DsvgPathEllipse(
          cx: cx,
          cy: cy,
          rx: rx,
          ry: ry,
        );
      };
    case 'line':
      return () {
        final double x1 = parseDoubleWithUnits(
          getAttribute(attributes, 'x1', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!;
        final double x2 = parseDoubleWithUnits(
          getAttribute(attributes, 'x2', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!;
        final double y1 = parseDoubleWithUnits(
          getAttribute(attributes, 'y1', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!;
        final double y2 = parseDoubleWithUnits(
          getAttribute(attributes, 'y2', def: '0'),
          fontSize: fontSize,
          xHeight: xHeight,
        )!;
        return DsvgPathLine(
          x1: x1,
          x2: x2,
          y1: y1,
          y2: y2,
        );
      };
    default:
      return null;
  }
}
