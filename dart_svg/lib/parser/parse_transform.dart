import 'dart:math';

import '../dsl/dsvg_affine_matrix.dart';
import '../parser/parse_double.dart';

/// Parses an SVG transform attribute.
///
/// Based on work in the "vi-tool" by @amirh.
DsvgAffineMatrix? parseTransform(
  final String? transform,
) {
  if (transform == null || transform == '') {
    return null;
  } else {
    if (!_transformValidator.hasMatch(transform)) {
      throw StateError('illegal or unsupported transform: $transform');
    } else {
      final matches = _transformCommand.allMatches(transform).toList().reversed;
      DsvgAffineMatrix? result;
      for (final m in matches) {
        final command = m.group(1)!.trim();
        final args = m.group(2);
        switch (command) {
          case 'matrix':
            final _args = args!.trim().split(_valueSeparator);
            assert(
              _args.isNotEmpty,
              "The arguments can't be empty.",
            );
            assert(
              _args.length == 6,
              "There must be six arguments.",
            );
            final a = parseDouble(_args[0]);
            final b = parseDouble(_args[1]);
            final c = parseDouble(_args[2]);
            final d = parseDouble(_args[3]);
            final e = parseDouble(_args[4]);
            final f = parseDouble(_args[5]);
            result = DsvgAffineMatrixMultiply(
              left: DsvgAffineMatrixSet(a: a, b: b, c: c, d: d, e: e, f: f),
              right: result,
            );
            break;
          case 'translate':
            final _args = args!.split(_valueSeparator);
            assert(_args.isNotEmpty, "The arguments can't be empty.");
            assert(_args.length <= 2, "The must be 1 or 2 arguments.");
            final x = parseDouble(_args[0]);
            final y = () {
              if (_args.length < 2) {
                return 0.0;
              } else {
                return parseDouble(_args[1]);
              }
            }();
            result = DsvgAffineMatrixMultiply(
              left: DsvgAffineMatrixSet(a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: x, f: y),
              right: result,
            );
            break;
          case 'scale':
            final _args = args!.split(_valueSeparator);
            assert(_args.isNotEmpty, "The arguments can't be empty.");
            assert(_args.length <= 2, "There must be 1 or 2 arguments.");
            final x = parseDouble(_args[0]);
            final y = () {
              if (_args.length < 2) {
                return x;
              } else {
                return parseDouble(_args[1]);
              }
            }();
            result = DsvgAffineMatrixMultiply(
              left: DsvgAffineMatrixSet(a: x, b: 0.0, c: 0.0, d: y, e: 0.0, f: 0.0),
              right: result,
            );
            break;
          case 'rotate':
            final _args = args!.split(_valueSeparator);
            assert(
              _args.length <= 3,
              "There must be 1, 2 or 3 arguments.",
            );
            final a = _radians(parseDouble(_args[0]));
            final rotate = DsvgAffineMatrixSet(a: cos(a), b: sin(a), c: -sin(a), d: cos(a), e: 0.0, f: 0.0);
            if (_args.length > 1) {
              final x = parseDouble(_args[1]);
              final y = () {
                if (_args.length == 3) {
                  return parseDouble(_args[2]);
                } else {
                  return x;
                }
              }();
              result = DsvgAffineMatrixMultiply(
                left: DsvgAffineMatrixMultiply(
                  left: DsvgAffineMatrixMultiply(
                    left: DsvgAffineMatrixSet(a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: x, f: y),
                    right: result,
                  ),
                  right: rotate,
                ),
                right: DsvgAffineMatrixSet(a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: -x, f: -y),
              );
            } else {
              result = DsvgAffineMatrixMultiply(
                left: rotate,
                right: result,
              );
            }
            break;
          case 'skewX':
            final x = parseDouble(args!);
            result = DsvgAffineMatrixMultiply(
              left: DsvgAffineMatrixSet(
                a: 1.0,
                b: 0.0,
                c: tan(x),
                d: 1.0,
                e: 0.0,
                f: 0.0,
              ),
              right: result,
            );
            break;
          case 'skewY':
            final y = parseDouble(args!);
            result = DsvgAffineMatrixMultiply(
              left: DsvgAffineMatrixSet(a: 1.0, b: tan(y), c: 0.0, d: 1.0, e: 0.0, f: 0.0),
              right: result,
            );
            break;
          default:
            throw StateError('Unsupported transform: ' + command);
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
const double _degrees2Radians = pi / 180.0;
double _radians(
  final double degrees,
) => degrees * _degrees2Radians;
