import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dart_svg/dsl/dsvg.dart';
import 'package:dart_svg/parser/parser_state.dart';
import 'package:flutter_svg/src/render_picture.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockPictureInfo extends Mock implements PictureInfo {}

class MockFile extends Mock implements File {}

void main() {
  group('PictureProvider', () {
    DsvgTheme? currentTheme;
    PictureInfoDecoder<T> decoderBuilder<T>(DsvgTheme theme) {
      currentTheme = theme;
      return (T bytes, ColorFilter? colorFilter, SvgErrorDelegate errorDelegate) async => MockPictureInfo();
    }

    group(
        'rebuilds the decoder using decoderBuilder '
        'when the theme changes', () {
      test('NetworkPicture', () async {
        const DsvgColor color = DsvgColor(0xFFB0E3BE);
        final NetworkPicture networkPicture = NetworkPicture(decoderBuilder, 'url')
          ..theme = const DsvgThemeImpl(fontSize: 14.0);
        final PictureInfoDecoder<Uint8List> decoder = networkPicture.decoder;
        const DsvgTheme newTheme = DsvgThemeImpl(
          currentColor: color,
          fontSize: 14.0,
          xHeight: 6.5,
        );
        networkPicture.theme = newTheme;
        expect(networkPicture.decoder, isNotNull);
        expect(networkPicture.decoder, isNot(equals(decoder)));
        expect(currentTheme, equals(newTheme));
      });
      test('FilePicture', () async {
        const DsvgColor color = DsvgColor(0xFFB0E3BE);
        final FilePicture filePicture = FilePicture(decoderBuilder, MockFile())
          ..theme = const DsvgThemeImpl(fontSize: 14.0);
        final PictureInfoDecoder<Uint8List> decoder = filePicture.decoder;
        const DsvgTheme newTheme = DsvgThemeImpl(
          currentColor: color,
          fontSize: 14.0,
          xHeight: 6.5,
        );
        filePicture.theme = newTheme;
        expect(filePicture.decoder, isNotNull);
        expect(filePicture.decoder, isNot(equals(decoder)));
        expect(currentTheme, equals(newTheme));
      });
      test('MemoryPicture', () async {
        const DsvgColor color = DsvgColor(0xFFB0E3BE);
        final MemoryPicture memoryPicture = MemoryPicture(decoderBuilder, Uint8List(0))
          ..theme = const DsvgThemeImpl(fontSize: 14.0);
        final PictureInfoDecoder<Uint8List> decoder = memoryPicture.decoder;
        const DsvgTheme newTheme = DsvgThemeImpl(
          currentColor: color,
          fontSize: 14.0,
          xHeight: 6.5,
        );
        memoryPicture.theme = newTheme;
        expect(memoryPicture.decoder, isNotNull);
        expect(memoryPicture.decoder, isNot(equals(decoder)));
        expect(currentTheme, equals(newTheme));
      });
      test('StringPicture', () async {
        const DsvgColor color = DsvgColor(0xFFB0E3BE);
        final StringPicture stringPicture = StringPicture(decoderBuilder, '')
          ..theme = const DsvgThemeImpl(fontSize: 14.0);
        final PictureInfoDecoder<String> decoder = stringPicture.decoder;
        const DsvgTheme newTheme = DsvgThemeImpl(
          currentColor: color,
          fontSize: 14.0,
          xHeight: 6.5,
        );
        stringPicture.theme = newTheme;
        expect(stringPicture.decoder, isNotNull);
        expect(stringPicture.decoder, isNot(equals(decoder)));
        expect(currentTheme, equals(newTheme));
      });
      test('ExactAssetPicture', () async {
        const DsvgColor color = DsvgColor(0xFFB0E3BE);
        final ExactAssetPicture exactAssetPicture = ExactAssetPicture(decoderBuilder, '')
          ..theme = const DsvgThemeImpl(fontSize: 14.0);
        final PictureInfoDecoder<String> decoder = exactAssetPicture.decoder;
        const DsvgTheme newTheme = DsvgThemeImpl(
          currentColor: color,
          fontSize: 14.0,
          xHeight: 6.5,
        );
        exactAssetPicture.theme = newTheme;
        expect(exactAssetPicture.decoder, isNotNull);
        expect(exactAssetPicture.decoder, isNot(equals(decoder)));
        expect(currentTheme, equals(newTheme));
      });
    });
    test('Evicts from cache when theme changes', () async {
      expect(pictureCacheSingleton.count, 0);
      const DsvgColor color = DsvgColor(0xFFB0E3BE);
      final StringPicture stringPicture = StringPicture(decoderBuilder, '');
      final PictureStream _ = stringPicture.resolve(createLocalPictureConfiguration(null));
      await null;
      expect(pictureCacheSingleton.count, 1);
      stringPicture.theme = const DsvgThemeImpl(currentColor: color);
      expect(pictureCacheSingleton.count, 0);
    });
  });
}
