import 'dart:math';

import 'package:vector_math/vector_math_64.dart';

import '../affine_transform.dart';
import '../parser/parse_double.dart';

/// Parses a SVG transform attribute into a [Matrix4].
///
/// Based on work in the "vi-tool" by @amirh, but extended to support additional
/// transforms and use a Matrix4 rather than Matrix3 for the affine matrices.
Matrix4? parseTransform(
  final String? transform,
) {
  if (transform == null || transform == '') {
    return null;
  } else {
    if (!_transformValidator.hasMatch(transform)) {
      throw StateError('illegal or unsupported transform: $transform');
    } else {
      final Iterable<Match> matches = _transformCommand.allMatches(transform).toList().reversed;
      Matrix4 result = Matrix4.identity();
      for (final Match m in matches) {
        final String command = m.group(1)!.trim();
        final String? args = m.group(2);
        switch (command) {
          case 'matrix':
            final List<String> _args = args!.trim().split(_valueSeparator);
            assert(
              _args.isNotEmpty,
              "The arguments can't be empty.",
            );
            assert(
              _args.length == 6,
              "There must be six arguments.",
            );
            final double a = parseDouble(_args[0])!;
            final double b = parseDouble(_args[1])!;
            final double c = parseDouble(_args[2])!;
            final double d = parseDouble(_args[3])!;
            final double e = parseDouble(_args[4])!;
            final double f = parseDouble(_args[5])!;
            result = affineMatrix(a, b, c, d, e, f).multiplied(result);
            break;
          case 'translate':
            final List<String> _args = args!.split(_valueSeparator);
            assert(_args.isNotEmpty, "The arguments can't be empty.");
            assert(_args.length <= 2, "The must be 1 or 2 arguments.");
            final double x = parseDouble(_args[0])!;
            final double y = () {
              if (_args.length < 2) {
                return 0.0;
              } else {
                return parseDouble(_args[1])!;
              }
            }();
            result = affineMatrix(1.0, 0.0, 0.0, 1.0, x, y).multiplied(result);
            break;
          case 'scale':
            final List<String> _args = args!.split(_valueSeparator);
            assert(_args.isNotEmpty, "The arguments can't be empty.");
            assert(_args.length <= 2, "There must be 1 or 2 arguments.");
            final double x = parseDouble(_args[0])!;
            final double y = () {
              if (_args.length < 2) {
                return x;
              } else {
                return parseDouble(_args[1])!;
              }
            }();
            result = affineMatrix(x, 0.0, 0.0, y, 0.0, 0.0).multiplied(result);
            break;
          case 'rotate':
            final List<String> _args = args!.split(_valueSeparator);
            assert(_args.length <= 3, "There must be 1, 2 or 3 arguments.",);
            final double a = radians(parseDouble(_args[0])!);
            final Matrix4 rotate = affineMatrix(cos(a), sin(a), -sin(a), cos(a), 0.0, 0.0);
            if (_args.length > 1) {
              final double x = parseDouble(_args[1])!;
              final double y = () {
                if (_args.length == 3) {
                  return parseDouble(_args[2])!;
                } else {
                  return x;
                }
              }();
              result = affineMatrix(1.0, 0.0, 0.0, 1.0, x, y)
                  .multiplied(result)
                  .multiplied(rotate)
                  .multiplied(affineMatrix(1.0, 0.0, 0.0, 1.0, -x, -y));
            } else {
              result = rotate.multiplied(result);
            }
            break;
          case 'skewX':
            final double x = parseDouble(args)!;
            result = affineMatrix(1.0, 0.0, tan(x), 1.0, 0.0, 0.0).multiplied(result);
            break;
          case 'skewY':
            final double y = parseDouble(args)!;
            result = affineMatrix(1.0, tan(y), 0.0, 1.0, 0.0, 0.0).multiplied(result);
            break;
          default:
            throw StateError('Unsupported transform: $command');
        }
      }
      return result;
    }
  }
}

final RegExp _transformValidator = RegExp('^($_transformCommandAtom)*\$');
final RegExp _transformCommand = RegExp(_transformCommandAtom);
const String _transformCommandAtom = ' *,?([^(]+)\\(([^)]*)\\)';
final RegExp _valueSeparator = RegExp('( *, *| +)');
