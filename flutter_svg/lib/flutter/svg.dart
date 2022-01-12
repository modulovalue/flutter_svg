import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Picture;

import 'package:dart_svg/dsl/dsvg.dart';
import 'package:dart_svg/parser/parser.dart';
import 'package:dart_svg/parser/parser_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'default_theme.dart';
import 'interpret.dart';
import 'render_picture.dart';
import 'util.dart';

class SvgPicture extends StatefulWidget {
  const SvgPicture({
    required final this.pictureProvider,
    required final Key? key,
    required final this.width,
    required final this.height,
    required final this.fit,
    required final this.alignment,
    required final this.matchTextDirection,
    required final this.allowDrawingOutsideViewBox,
    required final this.placeholderBuilder,
    required final this.colorFilter,
    required final this.semanticsLabel,
    required final this.excludeFromSemantics,
    required final this.clipBehavior,
    required final this.cacheColorFilter,
    required final this.theme,
  }) : super(
          key: key,
        );

  /// If specified, the width to use for the SVG.  If unspecified, the SVG
  /// will take the width of its parent.
  final double? width;

  /// If specified, the height to use for the SVG.  If unspecified, the SVG
  /// will take the height of its parent.
  final double? height;

  /// How to inscribe the picture into the space allocated during layout.
  /// The default is [BoxFit.contain].
  final BoxFit fit;

  /// How to align the picture within its parent widget.
  ///
  /// The alignment aligns the given position in the picture to the given position
  /// in the layout bounds. For example, an [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while a
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// picture with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then a [TextDirection] must be available
  /// when the picture is painted.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// The [PictureProvider] used to resolve the SVG.
  final PictureProvider pictureProvider;

  /// The placeholder to use while fetching, decoding, and parsing the SVG data.
  final WidgetBuilder? placeholderBuilder;

  /// If true, will horizontally flip the picture in [TextDirection.rtl] contexts.
  final bool matchTextDirection;

  /// If true, will allow the SVG to be drawn outside of the clip boundary of its
  /// viewBox.
  final bool allowDrawingOutsideViewBox;

  /// The [Semantics.label] for this picture.
  ///
  /// The value indicates the purpose of the picture, and will be
  /// read out by screen readers.
  final String? semanticsLabel;

  /// Whether to exclude this picture from semantics.
  ///
  /// Useful for pictures which do not contribute meaningful information to an
  /// application.
  final bool excludeFromSemantics;

  /// The content will be clipped (or not) according to this option.
  ///
  /// See the enum [Clip] for details of all possible options and their common
  /// use cases.
  ///
  /// Defaults to [Clip.hardEdge], and must not be null.
  final Clip clipBehavior;

  /// The color filter, if any, to apply to this widget.
  final ColorFilter? colorFilter;

  /// Whether to cache the picture with the [colorFilter] applied or not.
  ///
  /// This value should be set to true if the same SVG will be rendered with
  /// multiple colors, but false if it will always (or almost always) be
  /// rendered with the same [colorFilter].
  ///
  /// If [Svg.cacheColorFilterOverride] is not null, it will override this value
  /// for all widgets, regardless of what is specified for an individual widget.
  ///
  /// This defaults to false and must not be null.
  final bool cacheColorFilter;

  /// The theme used when parsing SVG elements.
  final DsvgTheme? theme;

  @override
  State<SvgPicture> createState() => _SvgPictureState();
}

class _SvgPictureState extends State<SvgPicture> {
  PictureInfo? _picture;
  PictureStream? _pictureStream;
  bool _isListeningToStream = false;

  @override
  void didChangeDependencies() {
    _updatePictureProvider();
    _resolveImage();
    _listenToStream();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(
    final SvgPicture oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (widget.pictureProvider != oldWidget.pictureProvider) {
      _updatePictureProvider();
      _resolveImage();
    }
  }

  @override
  void reassemble() {
    _updatePictureProvider();
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  /// Updates the `currentColor` of the picture provider based on
  /// either the widget's [DsvgTheme] or an inherited [DefaultSvgTheme].
  ///
  /// Updates the `fontSize` of the picture provider based on
  /// either the widget's [DsvgTheme], an inherited [DefaultSvgTheme]
  /// or an inherited [DefaultTextStyle]. If the property does not exist,
  /// then the font size defaults to 14.
  void _updatePictureProvider() {
    final DsvgTheme? defaultSvgTheme = DefaultSvgTheme.of(context)?.theme;
    final TextStyle defaultTextStyle = DefaultTextStyle.of(context).style;
    final DsvgColor? currentColor = widget.theme?.currentColor ?? defaultSvgTheme?.currentColor;
    final double fontSize = widget.theme?.fontSize ??
        defaultSvgTheme?.fontSize ??
        defaultTextStyle.fontSize ??
        // Fallback to the default font size if a font size is missing in DefaultTextStyle.
        // See: https://api.flutter.dev/flutter/painting/TextStyle/fontSize.html
        14.0;
    final double xHeight = widget.theme?.xHeight ??
        defaultSvgTheme?.xHeight ??
        // Fallback to the font size divided by 2.
        fontSize / 2;
    widget.pictureProvider.theme = DsvgThemeImpl(
      currentColor: currentColor,
      fontSize: fontSize,
      xHeight: xHeight,
    );
  }

  void _resolveImage() {
    final PictureStream newStream = widget.pictureProvider.resolve(createLocalPictureConfiguration(context));
    assert(newStream != null); // ignore: unnecessary_null_comparison
    _updateSourceStream(newStream);
  }

  void _handleImageChanged(
    final PictureInfo? imageInfo,
    final bool synchronousCall,
  ) =>
      setState(
        () => _picture = imageInfo,
      );

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
      double? width = widget.width;
      double? height = widget.height;
      if (width == null && height == null) {
        width = viewport.width;
        height = viewport.height;
      } else if (height != null) {
        width = height / viewport.height * viewport.width;
      } else if (width != null) {
        height = width / viewport.width * viewport.height;
      }
      child = SizedBox(
        width: width,
        height: height,
        child: FittedBox(
          fit: widget.fit,
          alignment: widget.alignment,
          clipBehavior: widget.clipBehavior,
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
      if (widget.placeholderBuilder == null) {
        child = _getDefaultPlaceholder(context, widget.width, widget.height);
      } else {
        child = widget.placeholderBuilder!(context);
      }
    }
    if (!widget.excludeFromSemantics) {
      child = Semantics(
        container: widget.semanticsLabel != null,
        image: true,
        label: () {
          if (widget.semanticsLabel == null) {
            return '';
          } else {
            return widget.semanticsLabel;
          }
        }(),
        child: child,
      );
    }
    return child;
  }

  Widget _getDefaultPlaceholder(
    final BuildContext context,
    final double? width,
    final double? height,
  ) {
    if (width != null || height != null) {
      return SizedBox(width: width, height: height);
    } else {
      return _defaultPlaceholderBuilder(context);
    }
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

bool? cacheColorFilterOverride;

Future<PictureInfo> svgPictureStringDecoder(
  final String raw,
  final bool allowDrawingOutsideOfViewBox,
  final ColorFilter? colorFilter,
  final SvgErrorDelegate errorDelegate, {
  final DsvgTheme theme = const DsvgThemeImpl(),
}) async {
  final DsvgParentRoot svgRoot = parseSvg(
    xml: raw,
    errorDelegate: errorDelegate,
    theme: theme,
  ).root;
  final Picture pic = await renderDrawableRootToPicture(
    drawableRoot: svgRoot,
    clipToViewBox: () {
      if (allowDrawingOutsideOfViewBox == true) {
        return false;
      } else {
        return true;
      }
    }(),
    colorFilter: colorFilter,
    size: dsvgSizeToFlutter(
      svgRoot.viewport.viewBox,
    ),
  );
  return PictureInfo(
    picture: pic,
    viewport: dsvgRectToFlutter(
      svgRoot.viewport.viewBoxRect,
    ),
    size: dsvgSizeToFlutter(
      svgRoot.viewport.size,
    ),
  );
}

Future<void> precachePicture(
  final PictureProvider provider,
  final BuildContext? context, {
  final Rect? viewBox,
  final ColorFilter? colorFilterOverride,
  final Color? color,
  final BlendMode? colorBlendMode,
  final PictureErrorListener? onError,
}) {
  final PictureConfiguration config = createLocalPictureConfiguration(
    context,
    viewBox: viewBox,
    colorFilterOverride: colorFilterOverride,
    color: color,
    colorBlendMode: colorBlendMode,
  );
  final Completer<void> completer = Completer<void>();
  PictureStream? stream;
  void listener(
    final PictureInfo? picture,
    final bool synchronous,
  ) {
    completer.complete();
    stream?.removeListener(listener);
  }

  void errorListener(
    final Object exception,
    final StackTrace stackTrace,
  ) {
    if (onError != null) {
      onError(exception, stackTrace);
    } else {
      FlutterError.reportError(FlutterErrorDetails(
        context: ErrorDescription('picture failed to precache'),
        library: 'SVG',
        exception: exception,
        stack: stackTrace,
        silent: true,
      ));
    }
    completer.complete();
    stream?.removeListener(listener);
  }

  stream = provider.resolve(
    config,
    onError: errorListener,
  )..addListener(
      listener,
      onError: errorListener,
    );
  return completer.future;
}

/// The default placeholder for a SVG that may take time to parse or
/// retrieve, e.g. from a network location.
final WidgetBuilder _defaultPlaceholderBuilder = (final BuildContext ctx) => const LimitedBox();

/// A [PictureInfoDecoderBuilder] for [Uint8List]s that will clip to the viewBox.
final PictureInfoDecoderBuilder<Uint8List> svgByteDecoderBuilder =
    _svgByteDecoderIsOutsideViewBoxBuilder(false);

/// A [PictureInfoDecoderBuilder] for [Uint8List]s that will not clip to the viewBox.
final PictureInfoDecoderBuilder<Uint8List> svgByteDecoderOutsideViewBoxBuilder =
    _svgByteDecoderIsOutsideViewBoxBuilder(true);

/// A [PictureInfoDecoderBuilder] for strings that will clip to the viewBox.
final PictureInfoDecoderBuilder<String> svgStringDecoderBuilder =
    _svgStringDecoderIsOutsideViewBoxBuilder(false);

/// A [PictureInfoDecoderBuilder] for strings that will not clip to the viewBox.
final PictureInfoDecoderBuilder<String> svgStringDecoderBuilderOutsideViewBoxBuilder =
    _svgStringDecoderIsOutsideViewBoxBuilder(false);

/// A [PictureInfoDecoderBuilder] for [Uint8List]s that will not clip to the viewBox.
PictureInfoDecoderBuilder<Uint8List> _svgByteDecoderIsOutsideViewBoxBuilder(
  final bool outsideViewBox,
) =>
    (final DsvgTheme theme) => (
          final Uint8List bytes,
          final ColorFilter? colorFilter,
          final SvgErrorDelegate errorDelegate,
        ) =>
            svgPictureStringDecoder(
              // TODO(dnfield): do utf decoding in another isolate?
              // Might just have to live with potentially slow(ish) decoding, this is causing errors.
              // See: https://github.com/dart-lang/sdk/issues/31954
              // See: https://github.com/flutter/flutter/blob/bf3bd7667f07709d0b817ebfcb6972782cfef637/packages/flutter/lib/src/services/asset_bundle.dart#L66
              utf8.decode(bytes),
              outsideViewBox,
              colorFilter,
              errorDelegate,
              theme: theme,
            );

/// A [PictureInfoDecoderBuilder] for [String]s.
PictureInfoDecoderBuilder<String> _svgStringDecoderIsOutsideViewBoxBuilder(
  final bool outsideViewBox,
) =>
    (final DsvgTheme theme) => (
          final String str,
          final ColorFilter? colorFilter,
          final SvgErrorDelegate errorDelegate,
        ) =>
            svgPictureStringDecoder(
              str,
              outsideViewBox,
              colorFilter,
              errorDelegate,
              theme: theme,
            );
