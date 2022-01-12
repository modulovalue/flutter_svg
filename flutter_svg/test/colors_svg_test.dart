import 'package:dart_svg/dsl/dsvg.dart';
import 'package:dart_svg/parser/parse_color.dart';
import 'package:test/test.dart';

void main() {
  const DsvgColor white = DsvgColor(0xFFFFFFFF);
  const DsvgColor black = DsvgColor(0xFF000000);
  test('Color Tests', () {
    expect(svgColorStringToColor('#FFFFFF'), white);
    expect(svgColorStringToColor('white'), white);
    expect(svgColorStringToColor('rgb(255, 255, 255)'), white);
    expect(svgColorStringToColor('rgb(100%, 100%, 100%)'), white);
    expect(svgColorStringToColor('RGB(  100%   ,   100.0% ,  99.9999% )'), white);
    expect(svgColorStringToColor('rGb( .0%,0.0%,.0000001% )'), black);
    expect(svgColorStringToColor('rgba(255,255, 255, 0.0)'), const DsvgColor(0x00FFFFFF));
    expect(svgColorStringToColor('rgba(0,0, 0, 1.0)'), const DsvgColor(0xFF000000));
    expect(svgColorStringToColor('#DDFFFFFF'), const DsvgColor(0xDDFFFFFF));
    expect(svgColorStringToColor(''), null);
    expect(svgColorStringToColor('transparent'), const DsvgColor(0x00FFFFFF));
    expect(svgColorStringToColor('none'), null);
    expect(svgColorStringToColor('hsl(0,0%,0%)'), const DsvgColor(0xFF000000));
    expect(svgColorStringToColor('hsl(0,0%,100%)'), const DsvgColor(0xFFFFFFFF));
    expect(svgColorStringToColor('hsl(136,47%,79%)'), const DsvgColor(0xFFB0E3BE));
    expect(svgColorStringToColor('hsl(136,80%,9%)'), const DsvgColor(0xFF05290E));
    expect(svgColorStringToColor('hsl(17,55%,29%)'), const DsvgColor(0xFF733821));
    expect(svgColorStringToColor('hsl(78,55%,29%)'), const DsvgColor(0xFF5A7321));
    expect(svgColorStringToColor('hsl(192,55%,29%)'), const DsvgColor(0xFF216273));
    expect(svgColorStringToColor('hsl(297,55%,29%)'), const DsvgColor(0xFF6F2173));
    expect(svgColorStringToColor('hsla(0,0%,100%, 0.0)'), const DsvgColor(0x00FFFFFF));
    expect(svgColorStringToColor('currentColor'), null);
    expect(svgColorStringToColor('currentcolor'), null);
    expect(() => svgColorStringToColor('invalid name'), throwsStateError);
  });
}
