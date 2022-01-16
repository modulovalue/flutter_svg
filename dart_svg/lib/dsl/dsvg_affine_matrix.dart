import 'package:vector_math/vector_math_64.dart';

abstract class DsvgAffineMatrix {
  Matrix4 toMatrix4();
}

class DsvgAffineTranslation implements DsvgAffineMatrix {
  final DsvgAffineMatrix? matrix;
  final double x;
  final double y;

  const DsvgAffineTranslation({
    required this.matrix,
    required this.x,
    required this.y,
  });

  @override
  Matrix4 toMatrix4() => (matrix?.toMatrix4() ?? Matrix4.identity())..translate(x, y);
}

class DsvgAffineMatrixSet implements DsvgAffineMatrix {
  final double a;
  final double b;
  final double c;
  final double d;
  final double e;
  final double f;

  const DsvgAffineMatrixSet({
    required final this.a,
    required final this.b,
    required final this.c,
    required final this.d,
    required final this.e,
    required final this.f,
  });

  @override
  Matrix4 toMatrix4() => Matrix4(
        a,
        b,
        0.0,
        0.0,
        c,
        d,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        e,
        f,
        0.0,
        1.0,
      );
}

class DsvgAffineMatrixMultiply implements DsvgAffineMatrix {
  final DsvgAffineMatrix left;
  final DsvgAffineMatrix? right;

  const DsvgAffineMatrixMultiply({
    required final this.left,
    required final this.right,
  });

  @override
  Matrix4 toMatrix4() {
    final _right = right;
    if (_right == null) {
      return left.toMatrix4();
    } else {
      return left.toMatrix4().multiplied(
            _right.toMatrix4(),
          );
    }
  }
}
