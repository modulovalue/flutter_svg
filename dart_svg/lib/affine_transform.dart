import 'package:vector_math/vector_math_64.dart';

/// Creates a [Matrix4] affine matrix.
Matrix4 affineMatrix(
  final double a,
  final double b,
  final double c,
  final double d,
  final double e,
  final double f,
) =>
    Matrix4(
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
