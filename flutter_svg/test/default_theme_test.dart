// ignore_for_file: prefer_const_constructors

import 'package:dart_svg/dsl/dsvg.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/src/default_theme.dart';
import 'package:flutter_svg/src/svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultSvgTheme', () {
    testWidgets('changes propagate to SvgPicture', (WidgetTester tester) async {
      const DsvgTheme svgTheme = DsvgThemeImpl(
        currentColor: DsvgColor(0xFF733821),
        fontSize: 14.0,
        xHeight: 6.0,
      );
      final SvgPicture svgPictureWidget = svgPictureFromString(
        string: '''
<svg viewBox="0 0 10 10">
  <rect x="0" y="0" width="10em" height="10" fill="currentColor" />
</svg>''',
      );
      await tester.pumpWidget(DefaultDsvgTheme(
        theme: svgTheme,
        child: svgPictureWidget,
      ));
      SvgPicture svgPicture = tester.firstWidget(find.byType(SvgPicture));
      expect(svgPicture, isNotNull);
      expect(
        svgPicture.pictureProvider.theme,
        equals(svgTheme),
      );
      const DsvgTheme anotherSvgTheme = DsvgThemeImpl(
        currentColor: DsvgColor(0xFF05290E),
        fontSize: 12.0,
        xHeight: 7.0,
      );
      await tester.pumpWidget(DefaultDsvgTheme(
        theme: anotherSvgTheme,
        child: svgPictureWidget,
      ));
      svgPicture = tester.firstWidget(find.byType(SvgPicture));
      expect(svgPicture, isNotNull);
      expect(
        svgPicture.pictureProvider.theme,
        equals(anotherSvgTheme),
      );
    });
    testWidgets(
        'currentColor from the widget\'s theme takes precedence over '
        'the theme from DefaultSvgTheme', (WidgetTester tester) async {
      const DsvgTheme svgTheme = DsvgThemeImpl(
        currentColor: DsvgColor(0xFF733821),
        fontSize: 14.0,
      );
      final SvgPicture svgPictureWidget = svgPictureFromString(
        string: '''
<svg viewBox="0 0 10 10">
  <rect x="0" y="0" width="10" height="10" fill="currentColor" />
</svg>''',
        theme: DsvgThemeImpl(
          currentColor: DsvgColor(0xFF05290E),
          fontSize: 14.0,
        ),
      );
      await tester.pumpWidget(DefaultDsvgTheme(
        theme: svgTheme,
        child: svgPictureWidget,
      ));
      final SvgPicture svgPicture = tester.firstWidget(find.byType(SvgPicture));
      expect(svgPicture, isNotNull);
      expect(
        svgPicture.pictureProvider.theme.currentColor,
        equals(DsvgColor(0xFF05290E)),
      );
    });
    testWidgets(
        'fontSize from the widget\'s theme takes precedence over '
        'the theme from DefaultSvgTheme', (WidgetTester tester) async {
      const DsvgTheme svgTheme = DsvgThemeImpl(
        fontSize: 14.0,
      );
      final SvgPicture svgPictureWidget = svgPictureFromString(
        string: '''
<svg viewBox="0 0 10 10">
  <rect x="0" y="0" width="10em" height="10em" />
</svg>''',
        theme: DsvgThemeImpl(
          fontSize: 12.0,
        ),
      );
      await tester.pumpWidget(DefaultDsvgTheme(
        theme: svgTheme,
        child: svgPictureWidget,
      ));
      final SvgPicture svgPicture = tester.firstWidget(find.byType(SvgPicture));
      expect(svgPicture, isNotNull);
      expect(
        svgPicture.pictureProvider.theme.fontSize,
        equals(12.0),
      );
    });
    testWidgets(
        'fontSize defaults to the font size from DefaultTextStyle '
        'if no widget\'s theme or DefaultSvgTheme is provided', (WidgetTester tester) async {
      final SvgPicture svgPictureWidget = svgPictureFromString(
        string: '''
<svg viewBox="0 0 10 10">
  <rect x="0" y="0" width="10em" height="10em" />
</svg>''',
      );
      await tester.pumpWidget(
        DefaultTextStyle(
          style: TextStyle(fontSize: 26.0),
          child: svgPictureWidget,
        ),
      );
      final SvgPicture svgPicture = tester.firstWidget(find.byType(SvgPicture));
      expect(svgPicture, isNotNull);
      expect(
        svgPicture.pictureProvider.theme.fontSize,
        equals(26.0),
      );
    });
    testWidgets(
        'fontSize defaults to 14 '
        'if no widget\'s theme, DefaultSvgTheme or DefaultTextStyle is provided',
        (WidgetTester tester) async {
      final SvgPicture svgPictureWidget = svgPictureFromString(
        string: '''
<svg viewBox="0 0 10 10">
  <rect x="0" y="0" width="10em" height="10em" />
</svg>''',
      );
      await tester.pumpWidget(svgPictureWidget);
      final SvgPicture svgPicture = tester.firstWidget(find.byType(SvgPicture));
      expect(svgPicture, isNotNull);
      expect(
        svgPicture.pictureProvider.theme.fontSize,
        equals(14.0),
      );
    });
    testWidgets(
        'xHeight from the widget\'s theme takes precedence over '
        'the theme from DefaultSvgTheme', (WidgetTester tester) async {
      const DsvgTheme svgTheme = DsvgThemeImpl(
        fontSize: 14.0,
        xHeight: 6.5,
      );
      final SvgPicture svgPictureWidget = svgPictureFromString(
        string: '''
<svg viewBox="0 0 10 10">
  <rect x="0" y="0" width="10ex" height="10ex" />
</svg>''',
        theme: DsvgThemeImpl(
          fontSize: 12.0,
          xHeight: 7.0,
        ),
      );
      await tester.pumpWidget(DefaultDsvgTheme(
        theme: svgTheme,
        child: svgPictureWidget,
      ));
      final SvgPicture svgPicture = tester.firstWidget(find.byType(SvgPicture));
      expect(svgPicture, isNotNull);
      expect(
        svgPicture.pictureProvider.theme.xHeight,
        equals(7.0),
      );
    });
    testWidgets(
        'xHeight defaults to the font size divided by 2 (7.0) '
        'if no widget\'s theme or DefaultSvgTheme is provided', (WidgetTester tester) async {
      final SvgPicture svgPictureWidget = svgPictureFromString(
        string: '''
<svg viewBox="0 0 10 10">
  <rect x="0" y="0" width="10ex" height="10ex" />
</svg>''',
      );
      await tester.pumpWidget(svgPictureWidget);
      final SvgPicture svgPicture = tester.firstWidget(find.byType(SvgPicture));
      expect(svgPicture, isNotNull);
      expect(
        svgPicture.pictureProvider.theme.xHeight,
        equals(7.0),
      );
    });
  });
}
