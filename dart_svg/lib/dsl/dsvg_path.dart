import '../dsl/dsvg_path_fill_type.dart';
import 'dsvg_affine_matrix.dart';

abstract class DsvgPath {}

class DsvgPathTransformed implements DsvgPath {
  final DsvgPath path;
  final DsvgAffineMatrix transform;

  const DsvgPathTransformed({
    required final this.path,
    required final this.transform,
  });
}

class DsvgPathFillTypeSet implements DsvgPath {
  final DsvgPath path;
  final DsvgPathFillType fillType;

  const DsvgPathFillTypeSet({
    required final this.path,
    required final this.fillType,
  });
}

class DsvgPathCircle implements DsvgPath {
  final double cx;
  final double cy;
  final double r;

  const DsvgPathCircle({
    required final this.cx,
    required final this.cy,
    required final this.r,
  });
}

class DsvgPathPath implements DsvgPath {
  final String d;
  final DsvgPathFillType? fillType;

  const DsvgPathPath({
    required final this.d,
    required final this.fillType,
  });
}

class DsvgPathRect implements DsvgPath {
  final double x;
  final double y;
  final double w;
  final double h;

  const DsvgPathRect({
    required final this.x,
    required final this.y,
    required final this.w,
    required final this.h,
  });
}

class DsvgPathRect2 implements DsvgPath {
  final double x;
  final double y;
  final double w;
  final double h;
  final double rx;
  final double ry;

  const DsvgPathRect2({
    required final this.x,
    required final this.y,
    required final this.w,
    required final this.h,
    required final this.rx,
    required final this.ry,
  });
}

class DsvgPathPolygon implements DsvgPath {
  final String? points;

  const DsvgPathPolygon({
    required final this.points,
  });
}

class DsvgPathPolyline implements DsvgPath {
  final String? points;

  const DsvgPathPolyline({
    required final this.points,
  });
}

class DsvgPathEllipse implements DsvgPath {
  final double cx;
  final double cy;
  final double rx;
  final double ry;

  const DsvgPathEllipse({
    required final this.cx,
    required final this.cy,
    required final this.rx,
    required final this.ry,
  });
}

class DsvgPathLine implements DsvgPath {
  final double x1;
  final double x2;
  final double y1;
  final double y2;

  const DsvgPathLine({
    required final this.x1,
    required final this.x2,
    required final this.y1,
    required final this.y2,
  });
}

extension DsvgPathMatch on DsvgPath {
  Z match<Z>({
    required final Z Function(DsvgPathCircle) circle,
    required final Z Function(DsvgPathFillTypeSet) fillTypeSet,
    required final Z Function(DsvgPathPath) path,
    required final Z Function(DsvgPathTransformed) transformed,
    required final Z Function(DsvgPathRect) rect,
    required final Z Function(DsvgPathRect2) rect2,
    required final Z Function(DsvgPathPolygon) polygon,
    required final Z Function(DsvgPathPolyline) polyline,
    required final Z Function(DsvgPathEllipse) ellipse,
    required final Z Function(DsvgPathLine) line,
  }) {
    final DsvgPath self = this;
    if (self is DsvgPathCircle) return circle(self);
    if (self is DsvgPathFillTypeSet) return fillTypeSet(self);
    if (self is DsvgPathPath) return path(self);
    if (self is DsvgPathTransformed) return transformed(self);
    if (self is DsvgPathRect) return rect(self);
    if (self is DsvgPathRect2) return rect2(self);
    if (self is DsvgPathPolygon) return polygon(self);
    if (self is DsvgPathPolyline) return polyline(self);
    if (self is DsvgPathEllipse) return ellipse(self);
    if (self is DsvgPathLine) return line(self);
    throw Exception('Invalid state');
  }
}
