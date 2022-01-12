import 'dart:typed_data';
import 'dart:ui';

import 'package:dart_svg/dsl/dsvg.dart';
import 'package:flutter_svg/error_delegates/error_delegate_flutter_error.dart';
import 'package:flutter_svg/flutter/render_picture.dart';
import 'package:flutter_svg/flutter/svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DrawableRoot can mergeStyle', () {
    const DsvgDrawableStyle styleA = DsvgDrawableStyle(
      groupOpacity: 0.5,
      pathFillType: DsvgPathFillType.evenOdd,
    );
    const DsvgDrawableStyle styleB = DsvgDrawableStyle(
      pathFillType: DsvgPathFillType.nonZero,
    );
    DsvgParentRoot root = const DsvgParentRoot(
      sourceLocation: null,
      id: '', // No id
      viewport: DsvgViewport(
        DsvgSize(w: 100, h: 100),
        DsvgSize(w: 100, h: 100),
      ),
      groupData: DsvgGroupData(
        children: <DsvgDrawable>[],
        style: styleA,
        color: null,
        transform: null,
      ),
    );
    expect(root.groupData.style!.pathFillType, styleA.pathFillType);
    root = mergeStyleable<DsvgDrawableParent<DsvgParentRoot>>(
      DsvgDrawableParent<DsvgParentRoot>(
        parent: root,
      ),
      styleB,
    ).parent;
    expect(root.groupData.style!.pathFillType, styleB.pathFillType);
  });
  test('SvgPictureDecoder uses color filter properly', () async {
    final PictureInfo info = await svgPictureStringDecoder(
      '''
<svg viewBox="0 0 100 100">
  <rect height="100" width="100" fill="blue" />
</svg>
''',
      false,
      const ColorFilter.mode(Color(0xFF00FF00), BlendMode.color),
      const SvgErrorDelegateFlutterWarnImpl(key: 'test'),
    );
    final Image image = await info.picture!.toImage(2, 2);
    final ByteData data = (await image.toByteData())!;
    const List<int> expected = <int>[
      0, 48, 0, 255, //
      0, 48, 0, 255,
      0, 48, 0, 255,
      0, 48, 0, 255,
    ];
    expect(data.buffer.asUint8List(), expected);
  });
  test('SvgPictureDecoder sets isComplexHint', () async {
    final PictureInfo info = await svgPictureStringDecoder(
      '''
<svg viewBox="0 0 100 100">
  <rect height="100" width="100" fill="blue" />
</svg>
''',
      false,
      null,
      const SvgErrorDelegateFlutterWarnImpl(key: 'test'),
    );
    expect(info.createLayer().isComplexHint, true);
  });
}
