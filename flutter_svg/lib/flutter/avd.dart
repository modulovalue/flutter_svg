import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dart_svg/dsl/dsvg.dart';
import 'package:dart_svg/parser/parse_color.dart';
import 'package:dart_svg/parser/parse_double.dart';
import 'package:dart_svg/parser/parser_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:xml/xml.dart';

import 'interpret.dart';
import 'render_picture.dart';
import 'util.dart';

/// A [PictureInfoDecoder] for [Uint8List]s that will clip to the viewBox.
final PictureInfoDecoder<Uint8List> avdByteDecoder =
    (Uint8List bytes, ColorFilter? colorFilter, SvgErrorDelegate errorDelegate) =>
        _avdPictureDecoder(bytes, false, colorFilter, errorDelegate);

/// A [PictureInfoDecoder] for strings that will clip to the viewBox.
final PictureInfoDecoder<String> avdStringDecoder =
    (String data, ColorFilter? colorFilter, SvgErrorDelegate errorDelegate) =>
        _avdPictureStringDecoder(data, false, colorFilter, errorDelegate);

/// A [PictureInfoDecoder] for [Uint8List]s that will not clip to the viewBox.
final PictureInfoDecoder<Uint8List> avdByteDecoderOutsideViewBox =
    (Uint8List bytes, ColorFilter? colorFilter, SvgErrorDelegate errorDelegate) =>
        _avdPictureDecoder(bytes, true, colorFilter, errorDelegate);

/// A [PictureInfoDecoder] for [String]s that will not clip to the viewBox.
final PictureInfoDecoder<String> avdStringDecoderOutsideViewBox =
    (String data, ColorFilter? colorFilter, SvgErrorDelegate errorDelegate) =>
        _avdPictureStringDecoder(data, true, colorFilter, errorDelegate);

/// A widget that draws Android Vector Drawable data into a [Picture] using a
/// [PictureProvider].
///
/// Support for AVD is incomplete and experimental at this time.
class AvdPicture extends StatefulWidget {
  /// Instantiates a widget that renders an AVD picture using the `pictureProvider`.
  ///
  /// If `matchTextDirection` is set to true, the picture will be flipped
  /// horizontally in [TextDirection.rtl] contexts.
  ///
  /// The `allowDrawingOutsideOfViewBox` parameter should be used with caution -
  /// if set to true, it will not clip the canvas used internally to the view box,
  /// meaning the picture may draw beyond the intended area and lead to undefined
  /// behavior or additional memory overhead.
  ///
  /// A custom `placeholderBuilder` can be specified for cases where decoding or
  /// acquiring data may take a noticeably long time, e.g. for a network picture.
  const AvdPicture({
    required final this.pictureProvider,
    required final Key? key,
    required final this.matchTextDirection,
    required final this.allowDrawingOutsideViewBox,
    required final this.placeholderBuilder,
    required final this.colorFilter,
  }) : super(
          key: key,
        );

  /// The [PictureProvider] used to resolve the AVD.
  final PictureProvider pictureProvider;

  /// The placeholder to use while fetching, decoding, and parsing the AVD data.
  final WidgetBuilder? placeholderBuilder;

  /// If true, will horizontally flip the picture in [TextDirection.rtl] contexts.
  final bool matchTextDirection;

  /// If true, will allow the AVD to be drawn outside of the clip boundary of its
  /// viewBox.
  final bool allowDrawingOutsideViewBox;

  /// The color filter, if any, to apply to this widget.
  final ColorFilter? colorFilter;

  @override
  State<StatefulWidget> createState() => _AvdPictureState();
}

class _AvdPictureState extends State<AvdPicture> {
  PictureInfo? _picture;
  PictureStream? _pictureStream;
  bool _isListeningToStream = false;

  @override
  void didChangeDependencies() {
    _resolveImage();
    if (TickerMode.of(context)) {
      _listenToStream();
    } else {
      _stopListeningToStream();
    }
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(
    final AvdPicture oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (widget.pictureProvider != oldWidget.pictureProvider) {
      _resolveImage();
    }
  }

  @override
  void reassemble() {
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  void _resolveImage() {
    final PictureStream newStream = widget.pictureProvider.resolve(createLocalPictureConfiguration(context));
    assert(newStream != null); // ignore: unnecessary_null_comparison
    _updateSourceStream(newStream);
  }

  void _handleImageChanged(
    final PictureInfo? imageInfo,
    final bool synchronousCall,
  ) {
    setState(
      () => _picture = imageInfo,
    );
  }

  // Update _pictureStream to newStream, and moves the stream listener
  // registration from the old stream to the new stream (if a listener was
  // registered).
  void _updateSourceStream(
    final PictureStream newStream,
  ) {
    if (_pictureStream?.key != newStream.key) {
      if (_isListeningToStream) {
        _pictureStream!.removeListener(_handleImageChanged);
      }
      _pictureStream = newStream;
      if (_isListeningToStream) {
        _pictureStream!.addListener(_handleImageChanged);
      }
    }
  }

  void _listenToStream() {
    if (!_isListeningToStream) {
      _pictureStream!.addListener(_handleImageChanged);
      _isListeningToStream = true;
    }
  }

  void _stopListeningToStream() {
    if (_isListeningToStream) {
      _pictureStream!.removeListener(_handleImageChanged);
      _isListeningToStream = false;
    }
  }

  @override
  void dispose() {
    assert(_pictureStream != null);
    _stopListeningToStream();
    super.dispose();
  }

  @override
  Widget build(
    final BuildContext context,
  ) {
    late Widget child;
    if (_picture != null) {
      final Rect viewport = Offset.zero & _picture!.viewport.size;
      child = SizedBox(
        width: viewport.width,
        height: viewport.height,
        child: FittedBox(
          clipBehavior: Clip.hardEdge,
          child: SizedBox.fromSize(
            size: viewport.size,
            child: RawPicture(
              _picture,
              matchTextDirection: widget.matchTextDirection,
              allowDrawingOutsideViewBox: widget.allowDrawingOutsideViewBox,
            ),
          ),
        ),
      );
      if (widget.pictureProvider.colorFilter == null && widget.colorFilter != null) {
        child = ColorFiltered(
          colorFilter: widget.colorFilter!,
          child: child,
        );
      }
    } else {
      child = _defaultPlaceholderBuilder(context);
    }
    return child;
  }

  @override
  void debugFillProperties(
    final DiagnosticPropertiesBuilder description,
  ) {
    super.debugFillProperties(description);
    description.add(
      DiagnosticsProperty<PictureStream>('stream', _pictureStream),
    );
  }
}

/// Decodes an Android Vector Drawable from a [Uint8List] to a [PictureInfo]
/// object.
Future<PictureInfo> _avdPictureDecoder(
  final Uint8List raw,
  final bool allowDrawingOutsideOfViewBox,
  final ColorFilter? colorFilter,
  final SvgErrorDelegate errorDelegate,
) async {
  final DsvgParentRoot avdRoot = await _avdFromBytes(raw, errorDelegate);
  final Picture pic = await renderDrawableRootToPicture(
    drawableRoot: avdRoot,
    clipToViewBox: () {
      if (allowDrawingOutsideOfViewBox == true) {
        return false;
      } else {
        return true;
      }
    }(),
    size: null,
    colorFilter: colorFilter,
  );
  return PictureInfo(
    picture: pic,
    viewport: dsvgRectToFlutter(
      avdRoot.viewport.viewBoxRect,
    ),
  );
}

/// Decodes an Android Vector Drawable from a [String] to a [PictureInfo]
/// object.
Future<PictureInfo> _avdPictureStringDecoder(
  final String raw,
  final bool allowDrawingOutsideOfViewBox,
  final ColorFilter? colorFilter,
  final SvgErrorDelegate errorDelegate,
) async {
  final DsvgParentRoot avdRoot = _avdFromString(raw, errorDelegate);
  final Picture pic = await renderDrawableRootToPicture(
    drawableRoot: avdRoot,
    clipToViewBox: () {
      if (allowDrawingOutsideOfViewBox == true) {
        return false;
      } else {
        return true;
      }
    }(),
    size: null,
    colorFilter: colorFilter,
  );
  return PictureInfo(
    picture: pic,
    viewport: dsvgRectToFlutter(avdRoot.viewport.viewBoxRect),
    size: dsvgSizeToFlutter(avdRoot.viewport.size),
  );
}

/// Creates a [DsvgDrawable] from an SVG <g> or shape element.  Also handles parsing <defs> and gradients.
///
/// If an unsupported element is encountered, it will be created as a [DrawableNoop].
DsvgDrawable _parseAvdElement(
  final XmlElement el,
  final Rect bounds,
) {
  if (el.name.local == 'path') {
    final String d = _getAttribute(
      el.attributes,
      'pathData',
      def: '',
      namespace: _androidNS,
    )!;
    return DsvgDrawableStyleable<DsvgDrawableShape>(
      styleable: DsvgDrawableShape(
        sourceLocation: null,
        id: _getAttribute(
          el.attributes,
          'id',
          def: '',
        ),
        path: DsvgPathPath(
          d: d,
          fillType: _parsePathFillType(el.attributes),
        ),
        style: DsvgDrawableStyle(
          stroke: _parseStroke(el.attributes),
          fill: _parseFill(el.attributes),
        ),
        transform: null,
      ),
    );
  } else if (el.name.local == 'group') {
    return _parseAvdGroup(el, bounds);
  }
  // TODO(dnfield): clipPath
  print('Unhandled element ${el.name.local}');
  return const DsvgDrawableStyleable<DsvgStyleable>(
    styleable: DsvgDrawableParent<DsvgParentGroup>(
      parent: DsvgParentGroup(
        sourceLocation: null,
        id: '',
        groupData: DsvgGroupData(
          children: <DsvgDrawable>[],
          style: null,
          color: null,
          transform: null,
        ),
      ),
    ),
  );
}

/// Parses an AVD <group> element.
DsvgDrawable _parseAvdGroup(
  final XmlElement el,
  final Rect bounds,
) {
  final List<DsvgDrawable> children = <DsvgDrawable>[];
  for (final XmlNode child in el.children) {
    if (child is XmlElement) {
      final DsvgDrawable el = _parseAvdElement(
        child,
        bounds,
      );
      children.add(el);
    }
  }
  final Matrix4 transform = _parseTransform(el.attributes);
  final DsvgPaint? fill = _parseFill(el.attributes);
  final DsvgPaint? stroke = _parseStroke(el.attributes);
  return DsvgDrawableStyleable<DsvgDrawableParent<DsvgParentGroup>>(
    styleable: DsvgDrawableParent<DsvgParentGroup>(
      parent: DsvgParentGroup(
        sourceLocation: null,
        id: _getAttribute(
          el.attributes,
          'id',
          def: '',
        ),
        groupData: DsvgGroupData(
          children: children,
          style: DsvgDrawableStyle(
            stroke: stroke,
            fill: fill,
            groupOpacity: 1.0,
          ),
          transform: transform.storage,
          color: null,
        ),
      ),
    ),
  );
}

/// The AVD namespace.
const String _androidNS = 'http://schemas.android.com/apk/res/android';

/// A utility method for getting an XML attribute with a default value.
String? _getAttribute(
  final List<XmlAttribute> attributes,
  final String name, {
  required final String? def,
  final String? namespace,
}) {
  for (final XmlAttribute attribute in attributes) {
    if (attribute.name.local == name) {
      return attribute.value;
    }
  }
  return def;
}

/// Parses an AVD @android:viewportWidth and @android:viewportHeight attributes to a [Rect].
DsvgViewport _parseViewBox(
  final List<XmlAttribute> el,
) {
  final String? rawWidth = _getAttribute(el, 'viewportWidth', def: '', namespace: _androidNS);
  final String? rawHeight = _getAttribute(el, 'viewportHeight', def: '', namespace: _androidNS);
  if (rawWidth == '' || rawHeight == '') {
    return const DsvgViewport(DsvgSize(w: 0.0, h: 0.0), DsvgSize(w: 0.0, h: 0.0));
  } else {
    final double width = parseDouble(rawWidth)!;
    final double height = parseDouble(rawHeight)!;
    return DsvgViewport(
      DsvgSize(w: width, h: height),
      DsvgSize(w: width, h: height),
    );
  }
}

/// Parses AVD transform related attributes to a [Matrix4].
Matrix4 _parseTransform(
  final List<XmlAttribute> el,
) {
  final double rotation = parseDouble(_getAttribute(el, 'rotation', def: '0', namespace: _androidNS))!;
  final double pivotX = parseDouble(_getAttribute(el, 'pivotX', def: '0', namespace: _androidNS))!;
  final double pivotY = parseDouble(_getAttribute(el, 'pivotY', def: '0', namespace: _androidNS))!;
  final double? scaleX = parseDouble(_getAttribute(el, 'scaleX', def: '1', namespace: _androidNS));
  final double? scaleY = parseDouble(_getAttribute(el, 'scaleY', def: '1', namespace: _androidNS));
  final double translateX = parseDouble(_getAttribute(el, 'translateX', def: '0', namespace: _androidNS))!;
  final double translateY = parseDouble(_getAttribute(el, 'translateY', def: '0', namespace: _androidNS))!;
  return Matrix4.identity()
    ..translate(pivotX, pivotY)
    ..rotateZ(rotation * pi / 180)
    ..scale(scaleX, scaleY)
    ..translate(-pivotX + translateX, -pivotY + translateY);
}

/// Parses an AVD stroke related attributes to a [DsvgPaint].
DsvgPaint? _parseStroke(
  final List<XmlAttribute> el,
) {
  final String? rawStroke = _getAttribute(
    el,
    'strokeColor',
    def: null,
    namespace: _androidNS,
  );
  if (rawStroke == null) {
    return null;
  } else {
    return DsvgPaint(
      DsvgPaintingStyle.stroke,
      color: svgColorStringToColor(rawStroke)!.withOpacity(
        parseDouble(
          _getAttribute(
            el,
            'strokeAlpha',
            def: '1',
            namespace: _androidNS,
          ),
        )!,
      ),
      strokeWidth: parseDouble(_getAttribute(el, 'strokeWidth', def: '0', namespace: _androidNS)),
      strokeCap: _parseStrokeCap(el),
      strokeJoin: _parseStrokeJoin(el),
      strokeMiterLimit: _parseMiterLimit(el),
    );
  }
}

/// Parses AVD `strokeMiterLimit` to a double.
double? _parseMiterLimit(
  final List<XmlAttribute> el,
) =>
    parseDouble(
      _getAttribute(
        el,
        'strokeMiterLimit',
        def: '4',
        namespace: _androidNS,
      ),
    );

/// Parses AVD `strokeLineJoin` to a [DsvgStrokeJoin].
DsvgStrokeJoin _parseStrokeJoin(
  final List<XmlAttribute> el,
) {
  final String? rawStrokeJoin = _getAttribute(
    el,
    'strokeLineJoin',
    def: 'miter',
    namespace: _androidNS,
  );
  switch (rawStrokeJoin) {
    case 'miter':
      return DsvgStrokeJoin.miter;
    case 'bevel':
      return DsvgStrokeJoin.bevel;
    case 'round':
      return DsvgStrokeJoin.round;
    default:
      return DsvgStrokeJoin.miter;
  }
}

/// Parses the `strokeLineCap` to a [StrokeCap].
DsvgStrokeCap _parseStrokeCap(
  final List<XmlAttribute> el,
) {
  final String? rawStrokeCap = _getAttribute(el, 'strokeLineCap', def: 'butt', namespace: _androidNS);
  switch (rawStrokeCap) {
    case 'butt':
      return DsvgStrokeCap.butt;
    case 'round':
      return DsvgStrokeCap.round;
    case 'square':
      return DsvgStrokeCap.square;
    default:
      return DsvgStrokeCap.butt;
  }
}

/// Parses fill information to a [DsvgPaint].
DsvgPaint? _parseFill(
  final List<XmlAttribute> el,
) {
  final String? rawFill = _getAttribute(el, 'fillColor', def: null, namespace: _androidNS);
  if (rawFill == null) {
    return null;
  }
  return DsvgPaint(
    DsvgPaintingStyle.fill,
    color: svgColorStringToColor(rawFill)!.withOpacity(
      parseDouble(
        _getAttribute(el, 'fillAlpha', def: '1'),
      )!,
    ),
  );
}

/// Turns a `fillType` into a [PathFillType].
DsvgPathFillType _parsePathFillType(
  final List<XmlAttribute> el,
) {
  final String? rawFillType = _getAttribute(
    el,
    'fillType',
    def: 'nonZero',
    namespace: _androidNS,
  );
  if (rawFillType == 'nonZero') {
    return DsvgPathFillType.nonZero;
  } else {
    return DsvgPathFillType.evenOdd;
  }
}

/// The default placeholder for an AVD that may take time to parse or
/// retrieve, e.g. from a network location.
WidgetBuilder _defaultPlaceholderBuilder = (
  final BuildContext ctx,
) =>
    const LimitedBox();

/// Produces a DrawableRoot from a [Uint8List] of AVD byte data (assumes
/// UTF8 encoding).
///
/// The `key` parameter is used for debugging purposes.
Future<DsvgParentRoot> _avdFromBytes(
  final Uint8List raw,
  final SvgErrorDelegate errorDelegate,
) async {
  // TODO(dnfield): do utf decoding in another thread?
  // Might just have to live with potentially slow(ish) decoding, this is causing errors.
  // See: https://github.com/dart-lang/sdk/issues/31954
  // See: https://github.com/flutter/flutter/blob/bf3bd7667f07709d0b817ebfcb6972782cfef637/packages/flutter/lib/src/services/asset_bundle.dart#L66
  // if (raw.lengthInBytes < 20 * 1024) {
  return _avdFromString(
    utf8.decode(raw),
    errorDelegate,
  );
  // } else {
  //   final String str =
  //       await compute(_utf8Decode, raw, debugLabel: 'UTF8 decode for SVG');
  //   return fromSvgString(str);
  // }
}

/// Creates a [DsvgParentRoot] from a string of Android Vector Drawable data.
DsvgParentRoot _avdFromString(
  final String rawSvg,
  final SvgErrorDelegate errorDelegate,
) {
  final XmlElement svg = XmlDocument.parse(rawSvg).rootElement;
  final DsvgViewport viewBox = _parseViewBox(
    svg.attributes,
  );
  final List<DsvgDrawable> children = svg.children
      .whereType<XmlElement>()
      .map(
        (XmlElement child) => _parseAvdElement(
          child,
          dsvgRectToFlutter(
            viewBox.viewBoxRect,
          ),
        ),
      )
      .toList();
  // todo : style on root
  return DsvgParentRoot(
    sourceLocation: null,
    id: _getAttribute(
      svg.attributes,
      'id',
      def: '',
    ),
    viewport: viewBox,
    groupData: DsvgGroupData(
      children: children,
      style: null,
      color: null,
      transform: null,
    ),
  );
}
