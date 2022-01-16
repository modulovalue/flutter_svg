// ignore_for_file: prefer_asserts_with_message

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dart_svg/dsl/dsvg.dart';
import 'package:dart_svg/parser/parser_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'error_delegate_flutter_error.dart';
import 'io/file/file.dart';
import 'io/http/http.dart';

/// A widget that displays a [dart:ui.Picture] directly.
@immutable
class RawPicture extends LeafRenderObjectWidget {
  /// Creates a new [RawPicture] object.
  const RawPicture(
    this.picture, {
    Key? key,
    this.matchTextDirection = false,
    this.allowDrawingOutsideViewBox = false,
  }) : super(key: key);

  /// The picture to paint.
  final PictureInfo? picture;

  /// Whether this picture should match the ambient [TextDirection] or not.
  final bool matchTextDirection;

  /// Whether to allow this picture to draw outside of its specified
  /// [PictureInfo.viewport]. Caution should be used here, as this may lead to
  /// greater memory usage than intended.
  final bool allowDrawingOutsideViewBox;

  @override
  RenderPicture createRenderObject(
    final BuildContext context,
  ) =>
      RenderPicture(
        picture: picture,
        matchTextDirection: matchTextDirection,
        textDirection: () {
          if (matchTextDirection) {
            return Directionality.of(context);
          } else {
            return null;
          }
        }(),
        allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      );

  @override
  void updateRenderObject(
    final BuildContext context,
    final RenderPicture renderObject,
  ) =>
      renderObject
        ..picture = picture
        ..matchTextDirection = matchTextDirection
        ..allowDrawingOutsideViewBox = allowDrawingOutsideViewBox
        ..textDirection = () {
          if (matchTextDirection) {
            return Directionality.of(context);
          } else {
            return null;
          }
        }();
}

/// A picture in the render tree.
///
/// The render picture will draw based on its parents dimensions maintaining
/// its aspect ratio.
///
/// If `matchTextDirection` is true, the picture will be flipped horizontally in
/// [TextDirection.rtl] contexts.  If `allowDrawingOutsideViewBox` is true, the
/// picture will be allowed to draw beyond the constraints of its viewbox; this
/// flag should be used with care, as it may result in unexpected effects or
/// additional memory usage.
class RenderPicture extends RenderBox {
  /// Creates a new [RenderPicture].
  RenderPicture({
    PictureInfo? picture,
    bool matchTextDirection = false,
    TextDirection? textDirection,
    bool? allowDrawingOutsideViewBox,
  })  : _matchTextDirection = matchTextDirection,
        _textDirection = textDirection,
        _allowDrawingOutsideViewBox = allowDrawingOutsideViewBox {
    this.picture = picture;
  }

  /// Whether to paint the picture in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the picture will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// pictures); and in [TextDirection.rtl] contexts, the picture will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with pictures in right-to-left environments, for
  /// pictures that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip pictures with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is set to true, [textDirection] must not be null.
  bool get matchTextDirection => _matchTextDirection;
  bool _matchTextDirection;

  set matchTextDirection(bool value) {
    if (value != _matchTextDirection) {
      _matchTextDirection = value;
      markNeedsPaint();
    }
  }

  bool get _flipHorizontally => _matchTextDirection && _textDirection == TextDirection.rtl;

  /// The text direction with which to resolve alignment.
  ///
  /// This may be changed to null, but only after the alignment and
  /// [matchTextDirection] properties have been changed to values that do not
  /// depend on the direction.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;

  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsPaint();
  }

  /// The information about the picture to draw.
  PictureInfo? get picture => _picture;
  PictureInfo? _picture;

  set picture(PictureInfo? val) {
    if (val == picture) {
      return;
    }
    _picture = val;
    _pictureHandle.layer = _picture?.createLayer();
    assert(() {
      if (_pictureHandle.layer != null) {
        assert(_pictureHandle.layer!.isComplexHint, "");
        assert(!_pictureHandle.layer!.willChangeHint, "");
      }
      return true;
    }(), "");
    markNeedsPaint();
  }

  /// Whether to allow the rendering of this picture to exceed the
  /// [PictureInfo.viewport] bounds.
  ///
  /// Caution should be used around setting this parameter to true, as it
  /// may result in greater memory usage during rasterization.
  bool? get allowDrawingOutsideViewBox => _allowDrawingOutsideViewBox;
  bool? _allowDrawingOutsideViewBox;

  set allowDrawingOutsideViewBox(bool? val) {
    if (val == _allowDrawingOutsideViewBox) {
      return;
    } else {
      _allowDrawingOutsideViewBox = val;
      markNeedsPaint();
    }
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.smallest;

  @override
  bool get isRepaintBoundary => true;

  final LayerHandle<TransformLayer> _transformHandle = LayerHandle<TransformLayer>();

  final LayerHandle<ClipRectLayer> _clipHandle = LayerHandle<ClipRectLayer>();

  final LayerHandle<PictureLayer> _pictureHandle = LayerHandle<PictureLayer>();

  void _addPicture(PaintingContext context, Offset offset) {
    assert(picture != null, "Picture can't be null.");
    assert(_pictureHandle.layer != null, "The picutres layer can't be null.");
    if (allowDrawingOutsideViewBox != true) {
      final Rect viewportRect = Offset.zero & _picture!.viewport.size;
      _clipHandle.layer = context.pushClipRect(
        needsCompositing,
        offset,
        viewportRect,
        (PaintingContext context, Offset offset) {
          context.addLayer(_pictureHandle.layer!);
        },
        oldLayer: _clipHandle.layer,
      );
    } else {
      _clipHandle.layer = null;
      context.addLayer(_pictureHandle.layer!);
    }
  }

  @override
  void dispose() {
    _transformHandle.layer = null;
    super.dispose();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (picture == null || size == Size.zero) {
      return;
    } else {
      bool needsTransform = false;
      final Matrix4 transform = Matrix4.identity();
      if (_flipHorizontally) {
        needsTransform = true;
        transform
          ..translate(size.width, 0.0)
          ..scale(-1.0, 1.0);
      }
      if (scaleCanvasToViewBox(
        transform,
        size,
        _picture!.viewport,
        _picture!.size,
      )) {
        needsTransform = true;
      }
      if (needsTransform) {
        _transformHandle.layer = context.pushTransform(
          needsCompositing,
          offset,
          transform,
          _addPicture,
          oldLayer: _transformHandle.layer,
        );
      } else {
        _transformHandle.layer = null;
        _addPicture(context, offset);
      }
      // this is sometimes useful for debugging, e.g. to draw
      // a thin red border around the drawing.
      assert(
        () {
          if (renderPictureDebugRectColor != null && renderPictureDebugRectColor!.alpha > 0) {
            context.canvas.drawRect(
                Offset.zero & size,
                Paint()
                  ..color = renderPictureDebugRectColor!
                  ..style = PaintingStyle.stroke);
          }
          return true;
        }(),
      );
    }
  }
}

/// Optional color to use to draw a thin rectangle around the canvas.
///
/// Only applied if asserts are enabled (e.g. debug mode).
Color? renderPictureDebugRectColor;

/// Scales a matrix to the given [viewBox] based on the [desiredSize]
/// of the widget.
///
/// Returns true if the supplied matrix was modified.
bool scaleCanvasToViewBox(
  Matrix4 matrix,
  Size desiredSize,
  Rect viewBox,
  Size pictureSize,
) {
  if (desiredSize == viewBox.size) {
    return false;
  } else {
    final double scale = min(
      desiredSize.width / viewBox.width,
      desiredSize.height / viewBox.height,
    );
    final Size scaledHalfViewBoxSize = viewBox.size * scale / 2.0;
    final Size halfDesiredSize = desiredSize / 2.0;
    final Offset shift = Offset(
      halfDesiredSize.width - scaledHalfViewBoxSize.width,
      halfDesiredSize.height - scaledHalfViewBoxSize.height,
    );
    matrix
      ..translate(shift.dx, shift.dy)
      ..scale(scale, scale);
    return true;
  }
}

/// The signature of a function that can decode raw SVG data into a [Picture].
typedef PictureInfoDecoder<T> = Future<PictureInfo> Function(
  T data,
  ColorFilter? colorFilter,
  SvgErrorDelegate errorDelegate,
);

/// The signature of a builder that returns a [PictureInfoDecoder]
/// based on the provided [theme].
typedef PictureInfoDecoderBuilder<T> = PictureInfoDecoder<T> Function(
  DsvgTheme theme,
);

/// Creates an [PictureConfiguration] based on the given [BuildContext] (and
/// optionally size).
///
/// This is the object that must be passed to [PictureProvider.resolve].
///
/// If this is not called from a build method, then it should be reinvoked
/// whenever the dependencies change, e.g. by calling it from
/// [State.didChangeDependencies], so that any changes in the environment are
/// picked up (e.g. if the device pixel ratio changes).
///
/// See also:
///
///  * [PictureProvider], which has an example showing how this might be used.
PictureConfiguration createLocalPictureConfiguration(
  final BuildContext? context, {
  final Rect? viewBox,
  final ColorFilter? colorFilterOverride,
  final Color? color,
  final BlendMode? colorBlendMode,
}) {
  ColorFilter? filter = colorFilterOverride;
  if (filter == null && color != null) {
    filter = ColorFilter.mode(color, colorBlendMode ?? BlendMode.srcIn);
  }
  return PictureConfiguration(
    bundle: () {
      if (context != null) {
        return DefaultAssetBundle.of(context);
      } else {
        return rootBundle;
      }
    }(),
    locale: () {
      if (context != null) {
        return Localizations.maybeLocaleOf(context);
      } else {
        return null;
      }
    }(),
    textDirection: () {
      if (context != null) {
        return Directionality.maybeOf(context);
      } else {
        return null;
      }
    }(),
    viewBox: viewBox,
    platform: defaultTargetPlatform,
    colorFilter: filter,
  );
}

/// Configuration information passed to the [PictureProvider.resolve] method to
/// select a specific picture.
///
/// See also:
///
///  * [createLocalPictureConfiguration], which creates an [PictureConfiguration]
///    based on ambient configuration in a [Widget] environment.
///  * [PictureProvider], which uses [PictureConfiguration] objects to determine
///    which picture to obtain.
@immutable
class PictureConfiguration {
  /// Creates an object holding the configuration information for an [PictureProvider].
  ///
  /// All the arguments are optional. Configuration information is merely
  /// advisory and best-effort.
  const PictureConfiguration({
    final this.bundle,
    final this.locale,
    final this.textDirection,
    final this.viewBox,
    final this.platform,
    final this.colorFilter,
  });

  /// Creates an object holding the configuration information for an [PictureProvider].
  ///
  /// All the arguments are optional. Configuration information is merely
  /// advisory and best-effort.
  PictureConfiguration copyWith({
    final AssetBundle? bundle,
    final Locale? locale,
    final TextDirection? textDirection,
    final Rect? viewBox,
    final TargetPlatform? platform,
    final ColorFilter? colorFilter,
  }) =>
      PictureConfiguration(
        bundle: bundle ?? this.bundle,
        locale: locale ?? this.locale,
        textDirection: textDirection ?? this.textDirection,
        viewBox: viewBox ?? this.viewBox,
        platform: platform ?? this.platform,
        colorFilter: colorFilter ?? this.colorFilter,
      );

  /// The preferred [AssetBundle] to use if the [PictureProvider] needs one and
  /// does not have one already selected.
  final AssetBundle? bundle;

  /// The language and region for which to select the picture.
  final Locale? locale;

  /// The reading direction of the language for which to select the picture.
  final TextDirection? textDirection;

  /// The size at which the picture will be rendered.
  final Rect? viewBox;

  /// The [TargetPlatform] for which assets should be used. This allows pictures
  /// to be specified in a platform-neutral fashion yet use different assets on
  /// different platforms, to match local conventions e.g. for color matching or
  /// shadows.
  final TargetPlatform? platform;

  /// The [ColorFilter], if any, that was applied to the drawing.
  final ColorFilter? colorFilter;

  @override
  bool operator ==(final dynamic other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is PictureConfiguration &&
        other.bundle == bundle &&
        other.locale == locale &&
        other.textDirection == textDirection &&
        other.viewBox == viewBox &&
        other.platform == platform &&
        other.colorFilter == colorFilter;
  }

  @override
  int get hashCode => Object.hash(
        bundle,
        locale,
        viewBox,
        platform,
        colorFilter,
      );

  @override
  String toString() {
    final StringBuffer result = StringBuffer();
    result.write('PictureConfiguration(');
    bool hasArguments = false;
    if (bundle != null) {
      result.write('bundle: $bundle');
      hasArguments = true;
    }
    if (locale != null) {
      if (hasArguments) {
        result.write(', ');
      }
      result.write('locale: $locale');
      hasArguments = true;
    }
    if (textDirection != null) {
      if (hasArguments) {
        result.write(', ');
      }
      result.write('textDirection: $textDirection');
      hasArguments = true;
    }
    if (viewBox != null) {
      if (hasArguments) {
        result.write(', ');
      }
      result.write('viewBox: $viewBox');
      hasArguments = true;
    }
    if (platform != null) {
      if (hasArguments) {
        result.write(', ');
      }
      result.write('platform: ${describeEnum(platform!)}');
      hasArguments = true;
    }
    if (colorFilter != null) {
      if (hasArguments) {
        result.write(', ');
      }
      result.write('colorFilter: $colorFilter');
      hasArguments = true;
    }
    result.write(')');
    return result.toString();
  }
}

/// a picture configuration that provides no additional information.
///
/// Useful when resolving an [PictureProvider] without any context.
const PictureConfiguration emptyPictureConfiguration = PictureConfiguration();

/// Identifies a picture without committing to the precise final asset. This
/// allows a set of pictures to be identified and for the precise picture to later
/// be resolved based on the environment, e.g. the device pixel ratio.
///
/// To obtain an [PictureStream] from an [PictureProvider], call [resolve],
/// passing it an [PictureConfiguration] object.
///
/// [PictureProvider] uses the global pictureCache to cache pictures.
///
/// The type argument `T` is the type of the object used to represent a resolved
/// configuration. This is also the type used for the key in the picture cache. It
/// should be immutable and implement the [==] operator and the [hashCode]
/// getter. Subclasses should subclass a variant of [PictureProvider] with an
/// explicit `T` type argument.
///
/// The type argument does not have to be specified when using the type as an
/// argument (where any Picture provider is acceptable).
///
/// The following picture formats are supported: {@macro flutter.dart:ui.pictureFormats}
///
/// ## Sample code
///
/// The following shows the code required to write a widget that fully conforms
/// to the [PictureProvider] and [Widget] protocols. (It is essentially a
/// bare-bones version of the widgets.Picture widget.)
///
/// ```dart
/// class MyPicture extends StatefulWidget {
///   const MyPicture({
///     Key key,
///     @required this.PictureProvider,
///   }) : assert(PictureProvider != null),
///        super(key: key);
///
///   final PictureProvider PictureProvider;
///
///   @override
///   _MyPictureState createState() => _MyPictureState();
/// }
///
/// class _MyPictureState extends State<MyPicture> {
///   PictureStream _PictureStream;
///   PictureInfo _pictureInfo;
///
///   @override
///   void didChangeDependencies() {
///     super.didChangeDependencies();
///     // We call _getPicture here because createLocalPictureConfiguration() needs to
///     // be called again if the dependencies changed, in case the changes relate
///     // to the DefaultAssetBundle, MediaQuery, etc, which that method uses.
///     _getPicture();
///   }
///
///   @override
///   void didUpdateWidget(MyPicture oldWidget) {
///     super.didUpdateWidget(oldWidget);
///     if (widget.PictureProvider != oldWidget.PictureProvider)
///       _getPicture();
///   }
///
///   void _getPicture() {
///     final PictureStream oldPictureStream = _PictureStream;
///     _PictureStream = widget.PictureProvider.resolve(createLocalPictureConfiguration(context));
///     if (_PictureStream.key != oldPictureStream?.key) {
///       // If the keys are the same, then we got the same picture back, and so we don't
///       // need to update the listeners. If the key changed, though, we must make sure
///       // to switch our listeners to the new picture stream.
///       oldPictureStream?.removeListener(_updatePicture);
///       _PictureStream.addListener(_updatePicture);
///     }
///   }
///
///   void _updatePicture(PictureInfo pictureInfo, bool synchronousCall) {
///     setState(() {
///       // Trigger a build whenever the picture changes.
///       _pictureInfo = pictureInfo;
///     });
///   }
///
///   @override
///   void dispose() {
///     _PictureStream.removeListener(_updatePicture);
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return RawPicture(
///       picture: _pictureInfo?.picture, // this is a dart:ui Picture object
///       scale: _pictureInfo?.scale ?? 1.0,
///     );
///   }
/// }
/// ```
// TODO inject the theme?
@optionalTypeArgs
abstract class PictureProvider<T, U> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  PictureProvider(
    final this.colorFilter, {
    required final this.decoderBuilder,
  })  : _theme = const DsvgThemeImpl(),
        decoder = decoderBuilder(const DsvgThemeImpl());

  /// The decoder builder to build a [decoder] when [theme] changes.
  final PictureInfoDecoderBuilder<U> decoderBuilder;

  /// The [PictureInfoDecoder] to use for loading this picture.
  PictureInfoDecoder<U> decoder;

  /// The color filter to apply to the picture, if any.
  final ColorFilter? colorFilter;

  /// The default theme used when parsing SVG elements.
  DsvgTheme get theme => _theme;
  DsvgTheme _theme;

  /// Sets the [_theme] to [theme].
  ///
  /// A theme is used when parsing SVG elements. Changing the theme
  /// rebuilds a [decoder] using [decoderBuilder] and the new theme.
  /// This will make the decoded SVG picture use properties from
  /// the new theme.
  set theme(DsvgTheme theme) {
    if (_theme == theme) {
      return;
    }
    decoder = decoderBuilder(theme);
    _theme = theme;
    if (_lastKey != null) {
      pictureCacheSingleton.evict(_lastKey!);
      _lastKey = null;
    }
  }

  T? _lastKey;

  /// Resolves this Picture provider using the given `configuration`, returning
  /// an [PictureStream].
  ///
  /// This is the public entry-point of the [PictureProvider] class hierarchy.
  ///
  /// Subclasses should implement [obtainKey] and [load], which are used by this
  /// method.
  PictureStream resolve(PictureConfiguration picture, {PictureErrorListener? onError}) {
    // ignore: unnecessary_null_comparison
    assert(picture != null);
    final PictureStream stream = PictureStream();
    obtainKey(picture).then<void>(
      (T key) {
        _lastKey = key;
        stream.setCompleter(
          pictureCacheSingleton.putIfAbsent(
            key!,
            () => load(key, onError: onError),
          ),
        );
      },
    ).catchError((final Object exception, final StackTrace stack) async {
      if (onError != null) {
        onError(exception, stack);
        return;
      }
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'SVG',
          context: ErrorDescription('while resolving a picture'),
          silent: true,
          // could be a network error or whatnot
          informationCollector: () sync* {
            yield DiagnosticsProperty<PictureProvider>('Picture provider', this);
            yield DiagnosticsProperty<T>('Picture key', _lastKey, defaultValue: null);
          },
        ),
      );
    },);
    return stream;
  }

  /// Converts a pictureProvider's settings plus a pictureConfiguration to a key
  /// that describes the precise picture to load.
  ///
  /// The type of the key is determined by the subclass. It is a value that
  /// unambiguously identifies the picture (_including its scale_) that the [load]
  /// method will fetch. Different [PictureProvider]s given the same constructor
  /// arguments and [PictureConfiguration] objects should return keys that are
  /// '==' to each other (possibly by using a class for the key that itself
  /// implements [==]).
  Future<T> obtainKey(PictureConfiguration picture);

  /// Converts a key into an [PictureStreamCompleter], and begins fetching the
  /// picture.
  @protected
  PictureStreamCompleter load(T key, {PictureErrorListener? onError});

  @override
  String toString() => '$runtimeType()';
}

/// The [PictureCache] for [Picture] objects created by [PictureProvider]
/// implementations.
final PictureCache pictureCacheSingleton = PictureCache();

/// An immutable key representing the current state of a [PictureProvider].
@immutable
class PictureKey<T> {
  /// Creates a new immutable key reprenseting the current state of a
  /// [PictureProvider] for the [PictureCache].
  const PictureKey(
    this.keyData, {
    required this.colorFilter,
    required this.theme,
  });

  /// Some unique identifier for the source of this picture, e.g. a file name or
  /// URL.
  ///
  /// If this is an iterable, it is assumed that the iterable will not be
  /// modified after creating this object.
  final T keyData;

  /// The color filter applied when this key was created.
  final ColorFilter? colorFilter;

  /// The theme used when this key was created.
  final DsvgTheme theme;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is PictureKey<T> &&
        keyData == other.keyData &&
        colorFilter == other.colorFilter &&
        theme == other.theme;
  }

  @override
  int get hashCode => hashValues(keyData.hashCode, colorFilter, theme);

  @override
  String toString() => 'PictureKey($keyData, colorFilter: $colorFilter, theme: $theme)';
}

/// Key for the picture obtained by an AssetPicture or [ExactAssetPicture].
///
/// This is used to identify the precise resource in the pictureCache.
@immutable
class AssetBundlePictureKey extends PictureKey<String> {
  /// Creates the key for an AssetPicture or [AssetBundlePictureProvider].
  ///
  /// The arguments must not be null.
  const AssetBundlePictureKey({
    required this.bundle,
    required String name,
    required DsvgTheme theme,
    ColorFilter? colorFilter,
  })  :
        // ignore: unnecessary_null_comparison
        assert(bundle != null),
        // ignore: unnecessary_null_comparison
        assert(name != null),
        super(name, colorFilter: colorFilter, theme: theme);

  /// The bundle from which the picture will be obtained.
  ///
  /// The picture is obtained by calling [AssetBundle.load] on the given [bundle]
  /// using the key given by [name].
  final AssetBundle bundle;

  /// The key to use to obtain the resource from the [bundle]. This is the
  /// argument passed to [AssetBundle.load].
  String get name => keyData;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AssetBundlePictureKey &&
        bundle == other.bundle &&
        name == other.name &&
        colorFilter == other.colorFilter &&
        theme == other.theme;
  }

  @override
  int get hashCode => hashValues(bundle, name, colorFilter, theme);

  @override
  String toString() =>
      '$runtimeType(bundle: $bundle, name: "$name", colorFilter: $colorFilter, theme: $theme)';
}

/// A subclass of [PictureProvider] that knows about [AssetBundle]s.
///
/// This factors out the common logic of [AssetBundle]-based [PictureProvider]
/// classes, simplifying what subclasses must implement to just [obtainKey].
abstract class AssetBundlePictureProvider extends PictureProvider<AssetBundlePictureKey, String> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  AssetBundlePictureProvider(
    final PictureInfoDecoderBuilder<String> decoderBuilder,
    final ColorFilter? colorFilter,
  ) : super(
          colorFilter,
          decoderBuilder: decoderBuilder,
        );

  /// Converts a key into an [PictureStreamCompleter], and begins fetching the
  /// picture using [_loadAsync].
  @override
  PictureStreamCompleter load(
    final AssetBundlePictureKey key, {
    final PictureErrorListener? onError,
  }) {
    return OneFramePictureStreamCompleter(
      _loadAsync(key, onError),
      informationCollector: () sync* {
        yield DiagnosticsProperty<PictureProvider>('Picture provider', this);
        yield DiagnosticsProperty<AssetBundlePictureKey>('Picture key', key);
      },
    );
  }

  /// Fetches the picture from the asset bundle, decodes it, and returns a
  /// corresponding [PictureInfo] object.
  ///
  /// This function is used by [load].
  @protected
  Future<PictureInfo> _loadAsync(AssetBundlePictureKey key, PictureErrorListener? onError) async {
    final String data = await key.bundle.loadString(key.name);
    if (onError != null) {
      return decoder(
        data,
        key.colorFilter,
        SvgErrorDelegateFlutterWarnImpl(key: key.toString()),
      ).catchError((Object error, StackTrace stack) {
        onError(error, stack);
        return Future<PictureInfo>.error(error, stack);
      });
    } else {
      return decoder(
        data,
        key.colorFilter,
        SvgErrorDelegateFlutterWarnImpl(key: key.toString()),
      );
    }
  }
}

/// The [PictureKey.keyData] for a [NetworkPicture].
@immutable
class NetworkPictureKeyData {
  /// Creates [PictureKey.keyData] for a [NetworkPicture].
  const NetworkPictureKeyData({required this.url, required this.headers});

  /// The URL to request.
  final String url;

  /// The headers include in the GET request to [url].
  final Map<String, String>? headers;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is NetworkPictureKeyData && other.url == url && other.headers == headers;
  }

  @override
  int get hashCode => hashValues(url, headers);
}

/// Fetches the given URL from the network, associating it with the given scale.
///
/// The picture will be cached regardless of cache headers from the server.
// TODO(ianh): Find some way to honour cache headers to the extent that when the
// last reference to a picture is released, we proactively evict the picture from
// our cache if the headers describe the picture as having expired at that point.
class NetworkPicture extends PictureProvider<PictureKey<NetworkPictureKeyData>, Uint8List> {
  /// Creates an object that fetches the picture at the given URL.
  ///
  /// The arguments must not be null.
  NetworkPicture(PictureInfoDecoderBuilder<Uint8List> decoderBuilder, this.url,
      {this.headers, ColorFilter? colorFilter})
      :
        // ignore: unnecessary_null_comparison
        assert(url != null),
        super(colorFilter, decoderBuilder: decoderBuilder);

  /// The URL from which the picture will be fetched.
  final String url;

  /// The HTTP headers that will be used with HttpClient.get to fetch picture from network.
  final Map<String, String>? headers;

  @override
  Future<PictureKey<NetworkPictureKeyData>> obtainKey(PictureConfiguration picture) {
    return SynchronousFuture<PictureKey<NetworkPictureKeyData>>(
      PictureKey<NetworkPictureKeyData>(
        NetworkPictureKeyData(url: url, headers: headers),
        colorFilter: colorFilter,
        theme: theme,
      ),
    );
  }

  @override
  PictureStreamCompleter load(PictureKey<NetworkPictureKeyData> key, {PictureErrorListener? onError}) {
    return OneFramePictureStreamCompleter(_loadAsync(key, onError: onError), informationCollector: () sync* {
      yield DiagnosticsProperty<PictureProvider>('Picture provider', this);
      yield DiagnosticsProperty<PictureKey<NetworkPictureKeyData>>(
        'Picture key',
        key,
      );
    });
  }

  Future<PictureInfo> _loadAsync(
    PictureKey<NetworkPictureKeyData> key, {
    PictureErrorListener? onError,
  }) async {
    assert(url == key.keyData.url);
    assert(headers == key.keyData.headers);
    final Uint8List bytes = await httpGet(url, headers: headers);

    if (onError != null) {
      return decoder(
        bytes,
        colorFilter,
        SvgErrorDelegateFlutterWarnImpl(key: key.toString()),
      ).catchError((Object error, StackTrace stack) {
        onError(error, stack);
        return Future<PictureInfo>.error(error, stack);
      });
    }
    return decoder(
      bytes,
      colorFilter,
      SvgErrorDelegateFlutterWarnImpl(key: key.toString()),
    );
  }

  @override
  String toString() => '$runtimeType("$url", headers: $headers, colorFilter: $colorFilter)';
}

/// Decodes the given [File] object as a picture, associating it with the given
/// scale.
class FilePicture extends PictureProvider<PictureKey<String>, Uint8List> {
  /// Creates an object that decodes a [File] as a picture.
  ///
  /// The arguments must not be null.
  FilePicture(PictureInfoDecoderBuilder<Uint8List> decoderBuilder, this.file, {ColorFilter? colorFilter})
      :
        // ignore: unnecessary_null_comparison
        assert(decoderBuilder != null),
        // ignore: unnecessary_null_comparison
        assert(file != null),
        super(colorFilter, decoderBuilder: decoderBuilder);

  /// The file to decode into a picture.
  final File file;

  @override
  Future<PictureKey<String>> obtainKey(PictureConfiguration picture) {
    return SynchronousFuture<PictureKey<String>>(
      PictureKey<String>(
        file.path,
        colorFilter: colorFilter,
        theme: theme,
      ),
    );
  }

  @override
  PictureStreamCompleter load(PictureKey<String> key, {PictureErrorListener? onError}) {
    return OneFramePictureStreamCompleter(_loadAsync(key, onError: onError), informationCollector: () sync* {
      yield DiagnosticsProperty<String>('Path', file.path);
    });
  }

  Future<PictureInfo?> _loadAsync(PictureKey<String> key, {PictureErrorListener? onError}) async {
    assert(key.keyData == file.path);

    final Uint8List data = await file.readAsBytes();
    if (data.isEmpty) {
      return null;
    }
    if (onError != null) {
      return decoder(
        data,
        colorFilter,
        SvgErrorDelegateFlutterWarnImpl(key: key.toString()),
      ).catchError((Object error, StackTrace stack) async {
        onError(error, stack);
        return Future<PictureInfo>.error(error, stack);
      });
    }
    return decoder(
      data,
      colorFilter,
      SvgErrorDelegateFlutterWarnImpl(key: key.toString()),
    );
  }

  @override
  String toString() => '$runtimeType("${file.path}", colorFilter: $colorFilter)';
}

/// Decodes the given [String] buffer as a picture, associating it with the
/// given scale.
///
/// The provided [bytes] buffer should not be changed after it is provided
/// to a [MemoryPicture]. To provide an [PictureStream] that represents a picture
/// that changes over time, consider creating a new subclass of [PictureProvider]
/// whose [load] method returns a subclass of [PictureStreamCompleter] that can
/// handle providing multiple pictures.
class MemoryPicture extends PictureProvider<PictureKey<Uint8List>, Uint8List> {
  /// Creates an object that decodes a [Uint8List] buffer as a picture.
  ///
  /// The arguments must not be null.
  MemoryPicture(PictureInfoDecoderBuilder<Uint8List> decoderBuilder, this.bytes, {ColorFilter? colorFilter})
      :
        // ignore: unnecessary_null_comparison
        assert(bytes != null),
        super(colorFilter, decoderBuilder: decoderBuilder);

  /// The bytes to decode into a picture.
  final Uint8List bytes;

  @override
  Future<PictureKey<Uint8List>> obtainKey(PictureConfiguration picture) {
    return SynchronousFuture<PictureKey<Uint8List>>(
      PictureKey<Uint8List>(
        bytes,
        colorFilter: colorFilter,
        theme: theme,
      ),
    );
  }

  @override
  PictureStreamCompleter load(PictureKey<Uint8List> key, {PictureErrorListener? onError}) {
    return OneFramePictureStreamCompleter(_loadAsync(key, onError: onError));
  }

  Future<PictureInfo> _loadAsync(PictureKey<Uint8List> key, {PictureErrorListener? onError}) async {
    assert(key.keyData == bytes);
    if (onError != null) {
      return decoder(
        bytes,
        colorFilter,
        SvgErrorDelegateFlutterWarnImpl(
          key: key.toString(),
        ),
      ).catchError((final Object error, final StackTrace stack) {
        onError(error, stack);
        return Future<PictureInfo>.error(error, stack);
      });
    }
    return decoder(
      bytes,
      colorFilter,
      SvgErrorDelegateFlutterWarnImpl(
        key: key.toString(),
      ),
    );
  }

  @override
  String toString() => '$runtimeType(${describeIdentity(bytes)})';
}

/// Decodes the given [String] as a picture, associating it with the
/// given scale.
///
/// The provided [String] should not be changed after it is provided
/// to a [StringPicture]. To provide an [PictureStream] that represents a picture
/// that changes over time, consider creating a new subclass of [PictureProvider]
/// whose [load] method returns a subclass of [PictureStreamCompleter] that can
/// handle providing multiple pictures.
class StringPicture extends PictureProvider<PictureKey<String>, String> {
  /// Creates an object that decodes a [Uint8List] buffer as a picture.
  ///
  /// The arguments must not be null.
  StringPicture(
    final PictureInfoDecoderBuilder<String> decoderBuilder,
    final this.string, {
    final ColorFilter? colorFilter,
  }) : super(
          colorFilter,
          decoderBuilder: decoderBuilder,
        );

  /// The string to decode into a picture.
  final String string;

  @override
  Future<PictureKey<String>> obtainKey(PictureConfiguration picture) {
    return SynchronousFuture<PictureKey<String>>(
      PictureKey<String>(
        string,
        colorFilter: colorFilter,
        theme: theme,
      ),
    );
  }

  @override
  PictureStreamCompleter load(PictureKey<String> key, {PictureErrorListener? onError}) {
    return OneFramePictureStreamCompleter(_loadAsync(key, onError: onError));
  }

  Future<PictureInfo> _loadAsync(
    PictureKey<String> key, {
    PictureErrorListener? onError,
  }) {
    assert(key.keyData == string);
    if (onError != null) {
      return decoder(
        string,
        colorFilter,
        SvgErrorDelegateFlutterWarnImpl(key: key.toString()),
      ).catchError((Object error, StackTrace stack) {
        onError(error, stack);
        return Future<PictureInfo>.error(error, stack);
      });
    }
    return decoder(
      string,
      colorFilter,
      SvgErrorDelegateFlutterWarnImpl(key: key.toString()),
    );
  }

  @override
  String toString() => '$runtimeType(${describeIdentity(string)}, colorFilter: $colorFilter)';
}

/// Fetches a picture from an [AssetBundle], associating it with the given scale.
///
/// This implementation requires an explicit final [assetName] and scale on
/// construction, and ignores the device pixel ratio and size in the
/// configuration passed into [resolve]. For a resolution-aware variant that
/// uses the configuration to pick an appropriate picture based on the device
/// pixel ratio and size, see AssetPicture.
///
/// ## Fetching assets
///
/// When fetching a picture provided by the app itself, use the [assetName]
/// argument to name the asset to choose. For instance, consider a directory
/// `icons` with a picture `heart.png`. First, the pubspec.yaml of the project
/// should specify its assets in the `flutter` section:
///
/// ```yaml
/// flutter:
///   assets:
///     - icons/heart.png
/// ```
///
/// Then, to fetch the picture and associate it with scale `1.5`, use
///
/// ```dart
/// AssetPicture('icons/heart.png', scale: 1.5)
/// ```
///
///## Assets in packages
///
/// To fetch an asset from a package, the [package] argument must be provided.
/// For instance, suppose the structure above is inside a package called
/// `my_icons`. Then to fetch the picture, use:
///
/// ```dart
/// AssetPicture('icons/heart.png', scale: 1.5, package: 'my_icons')
/// ```
///
/// Assets used by the package itself should also be fetched using the [package]
/// argument as above.
///
/// If the desired asset is specified in the `pubspec.yaml` of the package, it
/// is bundled automatically with the app. In particular, assets used by the
/// package itself must be specified in its `pubspec.yaml`.
///
/// A package can also choose to have assets in its 'lib/' folder that are not
/// specified in its `pubspec.yaml`. In this case for those pictures to be
/// bundled, the app has to specify which ones to include. For instance a
/// package named `fancy_backgrounds` could have:
///
/// ```
/// lib/backgrounds/background1.png
/// lib/backgrounds/background2.png
/// lib/backgrounds/background3.png
///```
///
/// To include, say the first picture, the `pubspec.yaml` of the app should specify
/// it in the `assets` section:
///
/// ```yaml
///  assets:
///    - packages/fancy_backgrounds/backgrounds/background1.png
/// ```
///
/// Note that the `lib/` is implied, so it should not be included in the asset
/// path.
class ExactAssetPicture extends AssetBundlePictureProvider {
  /// Creates an object that fetches the given picture from an asset bundle.
  ///
  /// The [assetName] and scale arguments must not be null. The scale arguments
  /// defaults to 1.0. The [bundle] argument may be null, in which case the
  /// bundle provided in the [PictureConfiguration] passed to the [resolve] call
  /// will be used instead.
  ///
  /// The [package] argument must be non-null when fetching an asset that is
  /// included in a package. See the documentation for the [ExactAssetPicture] class
  /// itself for details.
  ExactAssetPicture(
    final PictureInfoDecoderBuilder<String> decoderBuilder,
    final this.assetName, {
    final this.bundle,
    final this.package,
    final ColorFilter? colorFilter,
  })  :
        // ignore: unnecessary_null_comparison
        assert(assetName != null),
        super(decoderBuilder, colorFilter);

  /// The name of the asset.
  final String assetName;

  /// The key to use to obtain the resource from the [bundle]. This is the
  /// argument passed to [AssetBundle.load].
  String get keyName {
    if (package == null) {
      return assetName;
    } else {
      return 'packages/$package/$assetName';
    }
  }

  /// The bundle from which the picture will be obtained.
  ///
  /// If the provided [bundle] is null, the bundle provided in the
  /// [PictureConfiguration] passed to the [resolve] call will be used instead. If
  /// that is also null, the [rootBundle] is used.
  ///
  /// The picture is obtained by calling [AssetBundle.load] on the given [bundle]
  /// using the key given by [keyName].
  final AssetBundle? bundle;

  /// The name of the package from which the picture is included. See the
  /// documentation for the [ExactAssetPicture] class itself for details.
  final String? package;

  @override
  Future<AssetBundlePictureKey> obtainKey(PictureConfiguration picture) {
    return SynchronousFuture<AssetBundlePictureKey>(
      AssetBundlePictureKey(
        bundle: bundle ?? picture.bundle ?? rootBundle,
        name: keyName,
        colorFilter: colorFilter,
        theme: theme,
      ),
    );
  }

  @override
  String toString() => '$runtimeType(name: "$keyName", bundle: $bundle, colorFilter: $colorFilter)';
}

const int _kDefaultSize = 1000;

/// A cache for [PictureLayer] objects.
///
/// By default, this caches up to 1000 objects.
class PictureCache {
  final Map<Object, PictureStreamCompleter> _cache = <Object, PictureStreamCompleter>{};

  /// Maximum number of entries to store in the cache.
  ///
  /// Once this many entries have been cached, the least-recently-used entry is
  /// evicted when adding a new entry.
  int get maximumSize => _maximumSize;
  int _maximumSize = _kDefaultSize;

  /// Changes the maximum cache size.
  ///
  /// If the new size is smaller than the current number of elements, the
  /// extraneous elements are evicted immediately. Setting this to zero and then
  /// returning it to its original value will therefore immediately clear the
  /// cache.
  set maximumSize(
    final int value,
  ) {
    assert(value != null); // ignore: unnecessary_null_comparison
    assert(value >= 0);
    if (value == maximumSize) {
      return;
    }
    _maximumSize = value;
    if (maximumSize == 0) {
      clear();
    } else {
      while (_cache.length > maximumSize) {
        _cache.remove(_cache.keys.first)!.cached = false;
      }
    }
  }

  /// Evicts all entries from the cache.
  ///
  /// This is useful if, for instance, the root asset bundle has been updated
  /// and therefore new images must be obtained.
  void clear() {
    for (final PictureStreamCompleter completer in _cache.values) {
      assert(completer.cached);
      completer.cached = false;
    }
    _cache.clear();
  }

  /// Evicts a single entry from the cache, returning true if successful.
  bool evict(
    final Object key,
  ) =>
      _cache.remove(key) != null;

  /// Returns the previously cached [PictureStream] for the given key, if available;
  /// if not, calls the given callback to obtain it first. In either case, the
  /// key is moved to the "most recently used" position.
  ///
  /// The arguments must not be null. The `loader` cannot return null.
  PictureStreamCompleter putIfAbsent(
    final Object key,
    final PictureStreamCompleter Function() loader,
  ) {
    PictureStreamCompleter? result = _cache[key];
    if (result != null) {
      // Remove the provider from the list so that we can put it back in below
      // and thus move it to the end of the list.
      _cache.remove(key);
    } else {
      if (_cache.length == maximumSize && maximumSize > 0) {
        _cache.remove(_cache.keys.first)!.cached = false;
      }
      result = loader();
    }
    if (maximumSize > 0) {
      assert(_cache.length < maximumSize);
      _cache[key] = result;
      result.cached = true;
    }
    assert(_cache.length <= maximumSize);
    return result;
  }

  /// The number of entries in the cache.
  int get count => _cache.length;
}

/// The signature of a method that listens for errors on picture stream resolution.
typedef PictureErrorListener = void Function(
  Object exception,
  StackTrace stackTrace,
);

@immutable
class _PictureListenerPair {
  const _PictureListenerPair(
    final this.listener,
    final this.errorListener,
  );

  final PictureListener listener;
  final PictureErrorListener? errorListener;
}

/// Represents information about a ui.Picture to be drawn on a canvas.
class PictureInfo {
  /// Creates a new PictureInfo object.
  PictureInfo({
    required Picture picture,
    required this.viewport,
    this.size = Size.infinite,
  })  :
        // ignore: unnecessary_null_comparison
        assert(picture != null),
        // ignore: unnecessary_null_comparison
        assert(viewport != null),
        // ignore: unnecessary_null_comparison
        assert(size != null),
        _picture = picture;

  /// The raw picture.
  ///
  /// This picture's lifecycle will be managed by the provider. It will be
  /// reused as long as the picture does not change, and disposed when the
  /// provider loses all of its listeners or it is unset. Once it has been
  /// disposed, it will return null.
  Picture? get picture => _picture;
  Picture? _picture;

  /// The viewport enclosing the coordinates used in the picture.
  final Rect viewport;

  /// The requested size for this picture, which may be different than the
  /// viewport.targetSize.
  final Size size;

  /// Creates a [PictureLayer] that will suitably manage the lifecycle of the
  /// [picture].
  PictureLayer createLayer() {
    return _NonOwningPictureLayer(viewport)
      ..picture = picture
      ..isComplexHint = true;
  }

  void _dispose() {
    assert(_picture != null);
    _picture!.dispose();
    _picture = null;
  }
}

/// Signature for callbacks reporting that an image is available.
///
/// Used by [PictureStream].
///
/// The `synchronousCall` argument is true if the listener is being invoked
/// during the call to addListener. This can be useful if, for example,
/// [PictureStream.addListener] is invoked during a frame, so that a new rendering
/// frame is requested if the call was asynchronous (after the current frame)
/// and no rendering frame is requested if the call was synchronous (within the
/// same stack frame as the call to [PictureStream.addListener]).
typedef PictureListener = void Function(PictureInfo? image, bool synchronousCall);

/// A handle to an image resource.
///
/// PictureStream represents a handle to a [dart:ui.Image] object and its scale
/// (together represented by an [ImageInfo] object). The underlying image object
/// might change over time, either because the image is animating or because the
/// underlying image resource was mutated.
///
/// PictureStream objects can also represent an image that hasn't finished
/// loading.
///
/// PictureStream objects are backed by [PictureStreamCompleter] objects.
///
/// See also:
///
///  * [PictureProvider], which has an example that includes the use of an
///    [PictureStream] in a [Widget].
class PictureStream with Diagnosticable {
  /// Create an initially unbound image stream.
  ///
  /// Once an [PictureStreamCompleter] is available, call [setCompleter].
  PictureStream();

  /// The completer that has been assigned to this image stream.
  ///
  /// Generally there is no need to deal with the completer directly.
  PictureStreamCompleter? get completer => _completer;
  PictureStreamCompleter? _completer;

  List<_PictureListenerPair>? _listeners;

  /// Assigns a particular [PictureStreamCompleter] to this [PictureStream].
  ///
  /// This is usually done automatically by the [PictureProvider] that created the
  /// [PictureStream].
  ///
  /// This method can only be called once per stream. To have an [PictureStream]
  /// represent multiple images over time, assign it a completer that
  /// completes several images in succession.
  void setCompleter(PictureStreamCompleter value) {
    assert(
      _completer == null,
      "Completer must have not been set before.",
    );
    _completer = value;
    if (_listeners != null) {
      final List<_PictureListenerPair> initialListeners = _listeners!;
      _listeners = null;
      for (final _PictureListenerPair pair in initialListeners) {
        _completer!.addListener(pair.listener, onError: pair.errorListener);
      }
    }
  }

  /// Adds a listener callback that is called whenever a new concrete [ImageInfo]
  /// object is available. If a concrete image is already available, this object
  /// will call the listener synchronously.
  ///
  /// If the assigned [completer] completes multiple images over its lifetime,
  /// this listener will fire multiple times.
  ///
  /// The listener will be passed a flag indicating whether a synchronous call
  /// occurred. If the listener is added within a render object paint function,
  /// then use this flag to avoid calling [RenderObject.markNeedsPaint] during
  /// a paint.
  void addListener(PictureListener listener, {PictureErrorListener? onError}) {
    if (_completer != null) {
      return _completer!.addListener(listener, onError: onError);
    }
    _listeners ??= <_PictureListenerPair>[];
    _listeners!.add(_PictureListenerPair(listener, onError));
  }

  /// Stop listening for new concrete [PictureInfo] objects.
  void removeListener(PictureListener listener) {
    if (_completer != null) {
      return _completer!.removeListener(listener);
    } else {
      assert(
        _listeners != null,
        "Listener must have been set before.",
      );
      _listeners!.removeWhere(
        (_PictureListenerPair pair) => pair.listener == listener,
      );
    }
  }

  /// Returns an object which can be used with `==` to determine if this
  /// [PictureStream] shares the same listeners list as another [PictureStream].
  ///
  /// This can be used to avoid unregistering and reregistering listeners after
  /// calling [PictureProvider.resolve] on a new, but possibly equivalent,
  /// [PictureProvider].
  ///
  /// The key may change once in the lifetime of the object. When it changes, it
  /// will go from being different than other [PictureStream]'s keys to
  /// potentially being the same as others'. No notification is sent when this
  /// happens.
  Object? get key {
    if (_completer != null) {
      return _completer;
    } else {
      return this;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<PictureStreamCompleter>(
      'completer',
      _completer,
      ifPresent: _completer?.toStringShort(),
      ifNull: 'unresolved',
    ));
    properties.add(ObjectFlagProperty<List<_PictureListenerPair>>(
      'listeners',
      _listeners,
      ifPresent: '${_listeners?.length} listener${() {
        if (_listeners?.length == 1) {
          return "";
        } else {
          return "s";
        }
      }()}',
      ifNull: 'no listeners',
      level: () {
        if (_completer != null) {
          return DiagnosticLevel.hidden;
        } else {
          return DiagnosticLevel.info;
        }
      }(),
    ));
    _completer?.debugFillProperties(properties);
  }
}

/// Base class for those that manage the loading of [dart:ui.Picture] objects for
/// [PictureStream]s.
///
/// PictureStreamListener objects are rarely constructed directly. Generally, an
/// [PictureProvider] subclass will return an [PictureStream] and automatically
/// configure it with the right [PictureStreamCompleter] when possible.
abstract class PictureStreamCompleter with Diagnosticable {
  final List<_PictureListenerPair> _listeners = <_PictureListenerPair>[];
  PictureInfo? _current;

  bool _cached = false;

  /// Whether or not this completer is in the [PictureCache].
  bool get cached => _cached;

  set cached(bool value) {
    if (value != _cached) {
      if (!value && _listeners.isEmpty) {
        _current?._dispose();
        _current = null;
      }
      _cached = value;
    }
  }

  /// Adds a listener callback that is called whenever a new concrete [PictureInfo]
  /// object is available. If a concrete image is already available, this object
  /// will call the listener synchronously.
  ///
  /// If the [PictureStreamCompleter] completes multiple images over its lifetime,
  /// this listener will fire multiple times.
  ///
  /// The listener will be passed a flag indicating whether a synchronous call
  /// occurred. If the listener is added within a render object paint function,
  /// then use this flag to avoid calling [RenderObject.markNeedsPaint] during
  /// a paint.
  void addListener(
    final PictureListener listener, {
    final PictureErrorListener? onError,
  }) {
    _listeners.add(_PictureListenerPair(listener, onError));
    if (_current != null) {
      try {
        listener(_current, true);
      } on Object catch (exception, stack) {
        _handleImageError(
          ErrorDescription('by a synchronously-called image listener'),
          exception,
          stack,
        );
      }
    }
  }

  /// Stop listening for new concrete [PictureInfo] objects.
  void removeListener(
    final PictureListener listener,
  ) {
    _listeners.removeWhere(
      (_PictureListenerPair pair) => pair.listener == listener,
    );
    if (_listeners.isEmpty && !cached) {
      _current?._dispose();
      _current = null;
    }
  }

  /// Calls all the registered listeners to notify them of a new picture.
  @protected
  void setPicture(PictureInfo? picture) {
    _current?._dispose();
    _current = picture;
    if (_listeners.isEmpty) {
      return;
    }
    final List<_PictureListenerPair> localListeners = List<_PictureListenerPair>.from(_listeners);
    for (final _PictureListenerPair listenerPair in localListeners) {
      try {
        listenerPair.listener(picture, false);
      } on Object catch (exception, stack) {
        if (listenerPair.errorListener != null) {
          listenerPair.errorListener!(exception, stack);
        } else {
          _handleImageError(ErrorDescription('by a picture listener'), exception, stack);
        }
      }
    }
  }

  void _handleImageError(
    DiagnosticsNode context,
    Object exception,
    dynamic stack,
  ) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: exception,
      stack: stack as StackTrace,
      library: 'SVG',
      context: context,
    ));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<PictureInfo>(
        'current',
        _current,
        ifNull: 'unresolved',
        showName: false,
      ),
    );
    properties.add(ObjectFlagProperty<List<_PictureListenerPair>>(
      'listeners',
      _listeners,
      ifPresent: '${_listeners.length} listener${() {
        if (_listeners.length == 1) {
          return "";
        } else {
          return "s";
        }
      }()}',
    ));
    properties.add(FlagProperty('cached', value: cached, ifTrue: 'cached'));
  }
}

/// Manages the loading of [dart:ui.Picture] objects for static [PictureStream]s (those
/// with only one frame).
class OneFramePictureStreamCompleter extends PictureStreamCompleter {
  /// Creates a manager for one-frame [PictureStream]s.
  ///
  /// The image resource awaits the given [Future]. When the future resolves,
  /// it notifies the [PictureListener]s that have been registered with
  /// [addListener].
  ///
  /// The [InformationCollector], if provided, is invoked if the given [Future]
  /// resolves with an error, and can be used to supplement the reported error
  /// message (for example, giving the image's URL).
  ///
  /// Errors are reported using [FlutterError.reportError] with the `silent`
  /// argument on [FlutterErrorDetails] set to true, meaning that by default the
  /// message is only dumped to the console in debug mode (see [new
  /// FlutterErrorDetails]).
  OneFramePictureStreamCompleter(
    Future<PictureInfo?> picture, {
    InformationCollector? informationCollector,
  }) {
    picture.then<void>(
      setPicture,
      onError: (Object error, StackTrace stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'SVG',
          context: ErrorDescription('resolving a single-frame picture stream'),
          informationCollector: informationCollector,
          silent: true,
        ));
      },
    );
  }
}

class _NonOwningPictureLayer extends PictureLayer {
  _NonOwningPictureLayer(
    final Rect canvasBounds,
  ) : super(
          canvasBounds,
        );

  @override
  Picture? get picture => _picture;

  Picture? _picture;

  @override
  set picture(Picture? picture) {
    markNeedsAddToScene();
    // Do not dispose the picture, it's owned by the stream/cache.
    _picture = picture;
  }
}
