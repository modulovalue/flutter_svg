import 'package:dart_svg/dsl/dsvg_theme.dart';
import 'package:flutter/material.dart';

import 'flutter/avd.dart';
import 'flutter/render_picture.dart';
import 'flutter/util.dart';

AvdPicture avdPictureFromString({
  required final String bytes,
  final bool matchTextDirection = false,
  final bool allowDrawingOutsideViewBox = false,
  final WidgetBuilder? placeholderBuilder,
  final Color? color,
  final BlendMode colorBlendMode = BlendMode.srcIn,
  final Key? key,
}) =>
    AvdPicture(
      pictureProvider: StringPicture(
        () {
          if (allowDrawingOutsideViewBox == true) {
            return (final DsvgTheme _) => avdStringDecoderOutsideViewBox;
          } else {
            return (final DsvgTheme _) => avdStringDecoder;
          }
        }(),
        bytes,
      ),
      colorFilter: getColorFilter(
        color,
        colorBlendMode,
      ),
      matchTextDirection: matchTextDirection,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      key: key,
    );

AvdPicture avdPictureFromAsset({
  required final String assetName,
  final Key? key,
  final bool matchTextDirection = false,
  final AssetBundle? bundle,
  final String? package,
  final bool allowDrawingOutsideViewBox = false,
  final WidgetBuilder? placeholderBuilder,
  final Color? color,
  final BlendMode colorBlendMode = BlendMode.srcIn,
}) =>
    AvdPicture(
      pictureProvider: ExactAssetPicture(
        () {
          if (allowDrawingOutsideViewBox == true) {
            return (final DsvgTheme _) => avdStringDecoderOutsideViewBox;
          } else {
            return (final DsvgTheme _) => avdStringDecoder;
          }
        }(),
        assetName,
        bundle: bundle,
        package: package,
      ),
      colorFilter: getColorFilter(
        color,
        colorBlendMode,
      ),
      matchTextDirection: matchTextDirection,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      key: key,
    );
