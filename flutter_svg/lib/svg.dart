import 'dart:io';
import 'dart:typed_data';

import 'package:dart_svg/dsl/dsvg_theme.dart';
import 'package:flutter/material.dart';

import 'flutter/render_picture.dart';
import 'flutter/svg.dart';
import 'flutter/util.dart';

/// Creates a widget that displays a [PictureStream] obtained from a [Uint8List].
///
/// The [bytes] argument must not be null.
///
/// Either the [width] and [height] arguments should be specified, or the
/// widget should be placed in a context that sets tight layout constraints.
/// Otherwise, the image dimensions will change as the image is loaded, which
/// will result in ugly layout changes.
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
/// acquiring data may take a noticeably long time.
///
/// The `color` and `colorBlendMode` arguments, if specified, will be used to set a
/// [ColorFilter] on any [Paint]s created for this drawing.
///
/// The `theme` argument, if provided, will override the default theme
/// used when parsing SVG elements.
///
/// If [excludeFromSemantics] is true, then [semanticLabel] will be ignored.
SvgPicture svgPictureFromMemory(
  final Uint8List bytes, {
  final Key? key,
  final double? width,
  final double? height,
  final BoxFit fit = BoxFit.contain,
  final Alignment alignment = Alignment.center,
  final bool matchTextDirection = false,
  final bool allowDrawingOutsideViewBox = false,
  final WidgetBuilder? placeholderBuilder,
  final Color? color,
  final BlendMode colorBlendMode = BlendMode.srcIn,
  final String? semanticsLabel,
  final bool excludeFromSemantics = false,
  final Clip clipBehavior = Clip.hardEdge,
  final bool cacheColorFilter = false,
  final DsvgTheme? theme,
}) =>
    SvgPicture(
      alignment: alignment,
      matchTextDirection: matchTextDirection,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      clipBehavior: clipBehavior,
      cacheColorFilter: cacheColorFilter,
      placeholderBuilder: placeholderBuilder,
      excludeFromSemantics: excludeFromSemantics,
      key: key,
      fit: fit,
      semanticsLabel: semanticsLabel,
      width: width,
      height: height,
      theme: theme,
      pictureProvider: MemoryPicture(
        () {
          if (allowDrawingOutsideViewBox == true) {
            return svgByteDecoderOutsideViewBoxBuilder;
          } else {
            return svgByteDecoderBuilder;
          }
        }(),
        bytes,
        colorFilter: () {
          if (cacheColorFilterOverride ?? cacheColorFilter) {
            return getColorFilter(color, colorBlendMode);
          } else {
            return null;
          }
        }(),
      ),
      colorFilter: getColorFilter(color, colorBlendMode),
    );

/// Creates a widget that displays a [PictureStream] obtained from a [String].
///
/// The [bytes] argument must not be null.
///
/// Either the [width] and [height] arguments should be specified, or the
/// widget should be placed in a context that sets tight layout constraints.
/// Otherwise, the image dimensions will change as the image is loaded, which
/// will result in ugly layout changes.
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
/// acquiring data may take a noticeably long time.
///
/// The `color` and `colorBlendMode` arguments, if specified, will be used to set a
/// [ColorFilter] on any [Paint]s created for this drawing.
///
/// The `theme` argument, if provided, will override the default theme
/// used when parsing SVG elements.
///
/// If [excludeFromSemantics] is true, then [semanticLabel] will be ignored.
SvgPicture svgPictureFromString({
  required final String string,
  final Key? key,
  final double? width,
  final double? height,
  final BoxFit fit = BoxFit.contain,
  final AlignmentGeometry alignment = Alignment.center,
  final bool matchTextDirection = false,
  final bool allowDrawingOutsideViewBox = false,
  final WidgetBuilder? placeholderBuilder,
  final Color? color,
  final BlendMode colorBlendMode = BlendMode.srcIn,
  final String? semanticsLabel,
  final bool excludeFromSemantics = false,
  final Clip clipBehavior = Clip.hardEdge,
  final bool cacheColorFilter = false,
  final DsvgTheme? theme,
}) =>
    SvgPicture(
      key: key,
      width: width,
      height: height,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      matchTextDirection: matchTextDirection,
      fit: fit,
      alignment: alignment,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      clipBehavior: clipBehavior,
      cacheColorFilter: cacheColorFilter,
      theme: theme,
      pictureProvider: StringPicture(
        () {
          if (allowDrawingOutsideViewBox == true) {
            return svgStringDecoderBuilderOutsideViewBoxBuilder;
          } else {
            return svgStringDecoderBuilder;
          }
        }(),
        string,
        colorFilter: () {
          if (cacheColorFilterOverride ?? cacheColorFilter) {
            return getColorFilter(color, colorBlendMode);
          } else {
            return null;
          }
        }(),
      ),
      colorFilter: getColorFilter(color, colorBlendMode),
    );

SvgPicture svgPictureFromAsset({
  required final String assetName,
  final Key? key,
  final bool matchTextDirection = false,
  final AssetBundle? bundle,
  final String? package,
  final double? width,
  final double? height,
  final BoxFit fit = BoxFit.contain,
  final AlignmentGeometry alignment = Alignment.center,
  final bool allowDrawingOutsideViewBox = false,
  final WidgetBuilder? placeholderBuilder,
  final Color? color,
  final BlendMode colorBlendMode = BlendMode.srcIn,
  final String? semanticsLabel,
  final bool excludeFromSemantics = false,
  final Clip clipBehavior = Clip.hardEdge,
  final bool cacheColorFilter = false,
  final DsvgTheme? theme,
}) =>
    SvgPicture(
      matchTextDirection: matchTextDirection,
      placeholderBuilder: placeholderBuilder,
      alignment: alignment,
      fit: fit,
      width: width,
      height: height,
      excludeFromSemantics: excludeFromSemantics,
      semanticsLabel: semanticsLabel,
      clipBehavior: clipBehavior,
      theme: theme,
      cacheColorFilter: cacheColorFilter,
      pictureProvider: ExactAssetPicture(
        () {
          if (allowDrawingOutsideViewBox == true) {
            return svgStringDecoderBuilderOutsideViewBoxBuilder;
          } else {
            return svgStringDecoderBuilder;
          }
        }(),
        assetName,
        bundle: bundle,
        package: package,
        colorFilter: () {
          if (cacheColorFilterOverride ?? cacheColorFilter) {
            return getColorFilter(color, colorBlendMode);
          } else {
            return null;
          }
        }(),
      ),
      key: key,
      colorFilter: getColorFilter(color, colorBlendMode),
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
    );

SvgPicture svgPictureFromNetwork({
  required final String url,
  final Key? key,
  final Map<String, String>? headers,
  final double? width,
  final double? height,
  final BoxFit fit = BoxFit.contain,
  final AlignmentGeometry alignment = Alignment.center,
  final bool matchTextDirection = false,
  final bool allowDrawingOutsideViewBox = false,
  final WidgetBuilder? placeholderBuilder,
  final Color? color,
  final BlendMode colorBlendMode = BlendMode.srcIn,
  final String? semanticsLabel,
  final bool excludeFromSemantics = false,
  final Clip clipBehavior = Clip.hardEdge,
  final bool cacheColorFilter = false,
  final DsvgTheme? theme,
}) =>
    SvgPicture(
      fit: fit,
      width: width,
      height: height,
      matchTextDirection: matchTextDirection,
      alignment: alignment,
      key: key,
      theme: theme,
      cacheColorFilter: cacheColorFilter,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      excludeFromSemantics: excludeFromSemantics,
      placeholderBuilder: placeholderBuilder,
      pictureProvider: NetworkPicture(
        () {
          if (allowDrawingOutsideViewBox == true) {
            return svgByteDecoderOutsideViewBoxBuilder;
          } else {
            return svgByteDecoderBuilder;
          }
        }(),
        url,
        headers: headers,
        colorFilter: () {
          if (cacheColorFilterOverride ?? cacheColorFilter) {
            return getColorFilter(color, colorBlendMode);
          } else {
            return null;
          }
        }(),
      ),
      semanticsLabel: semanticsLabel,
      clipBehavior: clipBehavior,
      colorFilter: getColorFilter(color, colorBlendMode),
    );

SvgPicture svgPictureFromFile({
  required final File file,
  final Key? key,
  final double? width,
  final double? height,
  final BoxFit fit = BoxFit.contain,
  final AlignmentGeometry alignment = Alignment.center,
  final bool matchTextDirection = false,
  final bool allowDrawingOutsideViewBox = false,
  final WidgetBuilder? placeholderBuilder,
  final Color? color,
  final BlendMode colorBlendMode = BlendMode.srcIn,
  final String? semanticsLabel,
  final bool excludeFromSemantics = false,
  final Clip clipBehavior = Clip.hardEdge,
  final bool cacheColorFilter = false,
  final DsvgTheme? theme,
}) =>
    SvgPicture(
      key: key,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      matchTextDirection: matchTextDirection,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      clipBehavior: clipBehavior,
      cacheColorFilter: cacheColorFilter,
      theme: theme,
      pictureProvider: FilePicture(
        () {
          if (allowDrawingOutsideViewBox == true) {
            return svgByteDecoderOutsideViewBoxBuilder;
          } else {
            return svgByteDecoderBuilder;
          }
        }(),
        file,
        colorFilter: () {
          if (cacheColorFilterOverride ?? cacheColorFilter) {
            return getColorFilter(color, colorBlendMode);
          } else {
            return null;
          }
        }(),
      ),
      colorFilter: getColorFilter(color, colorBlendMode),
    );
