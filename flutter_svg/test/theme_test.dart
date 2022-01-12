// ignore_for_file: prefer_const_constructors

import 'package:dart_svg/dsl/dsvg.dart';
import 'package:test/test.dart';

void main() {
  group('SvgTheme', () {
    group('constructor', () {
      test('sets currentColor', () {
        const DsvgColor currentColor = DsvgColor(0xFFB0E3BE);
        expect(
          DsvgThemeImpl(
            currentColor: currentColor,
            fontSize: 14.0,
          ).currentColor,
          equals(currentColor),
        );
      });
      test('sets fontSize', () {
        const double fontSize = 14.0;
        expect(
          DsvgThemeImpl(
            currentColor: DsvgColor(0xFFB0E3BE),
            fontSize: fontSize,
          ).fontSize,
          equals(fontSize),
        );
      });
      test('sets fontSize to 14 by default', () {
        expect(
          DsvgThemeImpl(),
          equals(
            DsvgThemeImpl(fontSize: 14.0),
          ),
        );
      });
      test('sets xHeight', () {
        const double xHeight = 8.0;
        expect(
          DsvgThemeImpl(
            fontSize: 26.0,
            xHeight: xHeight,
          ).xHeight,
          equals(xHeight),
        );
      });
      test('sets xHeight as fontSize divided by 2 by default', () {
        const double fontSize = 16.0;
        expect(
          DsvgThemeImpl(
            fontSize: fontSize,
          ).xHeight,
          equals(fontSize / 2),
        );
      });
    });
    test('supports value equality', () {
      expect(
        DsvgThemeImpl(
          currentColor: DsvgColor(0xFF6F2173),
          fontSize: 14.0,
          xHeight: 6.0,
        ),
        equals(
          DsvgThemeImpl(
            currentColor: DsvgColor(0xFF6F2173),
            fontSize: 14.0,
            xHeight: 6.0,
          ),
        ),
      );
    });
  });
}
