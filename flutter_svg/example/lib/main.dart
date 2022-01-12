import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

// TODO restore example
// TODO restore dart.svg
void main() => runApp(
  const _MyApp(),
);

class _MyApp extends StatelessWidget {
  const _MyApp();

  @override
  Widget build(
    final BuildContext context,
  ) =>
      MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          body: InteractiveViewer(
            maxScale: 1000,
            child: svgPictureFromAsset(
              assetName: 'assets/dart.svg',
            ),
          ),
        ),
      );
}
