import 'dart:io';

import 'package:dart_svg/dsl/dsvg.dart';
import 'package:dart_svg/error_delegate_ignore.dart';
import 'package:dart_svg/parser/parser.dart';

void main() {
  final parsed = parseSvg(
    xml: File("example/dart.svg").readAsStringSync(),
    theme: const DsvgThemeImpl(),
    errorDelegate: const SvgErrorDelegateIgnoreImpl(),
  );
  print(parsed.root);
}
