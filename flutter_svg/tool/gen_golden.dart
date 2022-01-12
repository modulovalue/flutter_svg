import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dart_svg/dsl/dsvg.dart';
import 'package:dart_svg/parser/parser.dart';
import 'package:flutter_svg/error_delegates/error_delegate_flutter_error.dart';
import 'package:flutter_svg/flutter/interpret.dart';
import 'package:flutter_svg/flutter/util.dart';
import 'package:path/path.dart' as path;

// There's probably some better way to do this, but for now run `flutter test tool/gen_golden.dart
// should exclude files that
// - aren't rendering properly
// - have text (this doesn't render properly in the host setup?)
// The golden files should then be visually compared against Chrome's rendering output for correctness.
// The comparison may have to be made more tolerant if we want to use other sources of rendering for comparison...
Future<Image> getSvgImage(
  final String svgData,
) async {
  final PictureRecorder rec = PictureRecorder();
  final Canvas canvas = Canvas(rec);
  const Size size = Size(200.0, 200.0);
  final DsvgParentRoot svgRoot = parseSvg(
    xml: svgData,
    errorDelegate: const SvgErrorDelegateFlutterWarnImpl(
      key: 'GenGoldenTest',
    ),
    theme: const DsvgThemeImpl(),
  ).root;
  drawableRootScaleCanvasToViewBox(
    svgRoot,
    canvas,
    size,
  );
  drawableRootClipCanvasToViewBox(
    svgRoot,
    canvas,
  );
  canvas.drawPaint(Paint()..color = const Color(0xFFFFFFFF));
  renderDrawable(
    drawable: DsvgDrawableStyleable<DsvgStyleable>(
      styleable: DsvgDrawableParent<DsvgParentRoot>(
        parent: svgRoot,
      ),
    ),
    canvas: canvas,
    bounds: dsvgRectToFlutter(
      svgRoot.viewport.viewBoxRect,
    ),
  );
  final Picture pict = rec.endRecording();
  return await pict.toImage(size.width.toInt(), size.height.toInt());
}

Future<Uint8List> getSvgPngBytes(
  final String svgData,
) async {
  final Image image = await getSvgImage(svgData);
  final ByteData bytes = (await image.toByteData(format: ImageByteFormat.png))!;
  return bytes.buffer.asUint8List();
}

Future<Uint8List> getSvgRgbaBytes(
  final String svgData,
) async {
  final Image image = await getSvgImage(svgData);
  final ByteData bytes = (await image.toByteData(format: ImageByteFormat.rawRgba))!;
  return bytes.buffer.asUint8List();
}

Iterable<File> getSvgFileNames() sync* {
  final Directory dir = Directory('./example/assets');
  for (final FileSystemEntity fe in dir.listSync(recursive: true)) {
    if (fe is File && fe.path.toLowerCase().endsWith('.svg')) {
      // Skip text based tests unless we're on Linux - these have
      // subtle platform specific differences.
      if (fe.path.toLowerCase().contains('text') && !Platform.isLinux) {
        continue;
      }
      yield fe;
    }
  }
}

String getGoldenFileName(
  final String svgAssetPath,
) =>
    svgAssetPath
        .replaceAll('/example\/assets/', '/golden/')
        .replaceAll('\\example\\assets\\', '\\golden\\')
        .replaceAll('.svg', '.png');

Future<void> main() async {
  for (File fe in getSvgFileNames()) {
    final String pathName = getGoldenFileName(fe.path);
    final Directory goldenDir = Directory(path.dirname(pathName));
    if (!goldenDir.existsSync()) {
      goldenDir.createSync(recursive: true);
    }
    final File output = File(pathName);
    print(pathName);
    await output.writeAsBytes(await getSvgPngBytes(await fe.readAsString()));
  }
}
