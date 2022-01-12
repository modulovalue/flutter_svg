import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_svg/svg.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          svgPictureFromAsset(
            assetName: 'assets/wikimedia/Ghostscript_Tiger.svg',
          ),
          const CircularProgressIndicator(),
        ],
      ),
    ),
  );
}
