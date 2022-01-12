import '../dsl/dsvg.dart';
import '../parser/parse_double.dart';

/// Converts a SVG Color String (either a # prefixed color string
/// or a named color) to a [DsvgColor].
DsvgColor? svgColorStringToColor(
  String? colorString,
) {
  if (colorString == null || colorString.isEmpty) {
    return null;
  } else if (colorString == 'none') {
    return null;
  } else if (colorString.toLowerCase() == 'currentcolor') {
    return null;
  } else {
    // handle hex colors e.g. #fff or #ffffff.  This supports #RRGGBBAA
    if (colorString[0] == '#') {
      if (colorString.length == 4) {
        final String r = colorString[1];
        final String g = colorString[2];
        final String b = colorString[3];
        // ignore: parameter_assignments
        colorString = '#$r$r$g$g$b$b';
      }
      int color = int.parse(colorString.substring(1), radix: 16);
      if (colorString.length == 7) {
        return DsvgColor(color |= 0xFF000000);
      } else if (colorString.length == 9) {
        return DsvgColor(color);
      }
    }
    // handle rgba() colors e.g. rgba(255, 255, 255, 1.0)
    if (colorString.toLowerCase().startsWith('rgba')) {
      final List<String> rawColorElements = colorString
          .substring(colorString.indexOf('(') + 1, colorString.indexOf(')'))
          .split(',')
          .map((String rawColor) => rawColor.trim())
          .toList();
      final double opacity = parseDouble(rawColorElements.removeLast())!;
      final List<int> rgb = rawColorElements.map((String rawColor) => int.parse(rawColor)).toList();
      return DsvgColor.fromRGBO(rgb[0], rgb[1], rgb[2], opacity);
    }
    // Conversion code from: https://github.com/MichaelFenwick/Color, thanks :)
    if (colorString.toLowerCase().startsWith('hsl')) {
      final List<int> values = colorString
          .substring(colorString.indexOf('(') + 1, colorString.indexOf(')'))
          .split(',')
          .map((String rawColor) {
        rawColor = rawColor.trim();
        if (rawColor.endsWith('%')) {
          rawColor = rawColor.substring(0, rawColor.length - 1);
        }
        if (rawColor.contains('.')) {
          return (parseDouble(rawColor)! * 2.55).round();
        } else {
          return int.parse(rawColor);
        }
      }).toList();
      final double hue = values[0] / 360 % 1;
      final double saturation = values[1] / 100;
      final double luminance = values[2] / 100;
      final int alpha = () {
        if (values.length > 3) {
          return values[3];
        } else {
          return 255;
        }
      }();
      List<double> rgb = <double>[0, 0, 0];
      if (hue < 1 / 6) {
        rgb[0] = 1;
        rgb[1] = hue * 6;
      } else if (hue < 2 / 6) {
        rgb[0] = 2 - hue * 6;
        rgb[1] = 1;
      } else if (hue < 3 / 6) {
        rgb[1] = 1;
        rgb[2] = hue * 6 - 2;
      } else if (hue < 4 / 6) {
        rgb[1] = 4 - hue * 6;
        rgb[2] = 1;
      } else if (hue < 5 / 6) {
        rgb[0] = hue * 6 - 4;
        rgb[2] = 1;
      } else {
        rgb[0] = 1;
        rgb[2] = 6 - hue * 6;
      }
      rgb = rgb.map((double val) => val + (1 - saturation) * (0.5 - val)).toList();
      if (luminance < 0.5) {
        rgb = rgb.map((double val) => luminance * 2 * val).toList();
      } else {
        rgb = rgb.map((double val) => luminance * 2 * (1 - val) + 2 * val - 1).toList();
      }
      rgb = rgb.map((double val) => val * 255).toList();
      return DsvgColor.fromARGB(alpha, rgb[0].round(), rgb[1].round(), rgb[2].round());
    } else {
      // handle rgb() colors e.g. rgb(255, 255, 255)
      if (colorString.toLowerCase().startsWith('rgb')) {
        final List<int> rgb = colorString
            .substring(colorString.indexOf('(') + 1, colorString.indexOf(')'))
            .split(',')
            .map((String rawColor) {
          rawColor = rawColor.trim();
          if (rawColor.endsWith('%')) {
            rawColor = rawColor.substring(0, rawColor.length - 1);
            return (parseDouble(rawColor)! * 2.55).round();
          }
          return int.parse(rawColor);
        }).toList();
        // rgba() isn't really in the spec, but Firefox supported it at one point so why not.
        final int a = () {
          if (rgb.length > 3) {
            return rgb[3];
          } else {
            return 255;
          }
        }();
        return DsvgColor.fromARGB(a, rgb[0], rgb[1], rgb[2]);
      } else {
        // handle named colors ('red', 'green', etc.).
        final DsvgColor? namedColor = _namedColors[colorString];
        if (namedColor != null) {
          return namedColor;
        } else {
          throw StateError('Could not parse "$colorString" as a color.');
        }
      }
    }
  }
}

// https://www.w3.org/TR/SVG11/types.html#ColorKeywords
const Map<String, DsvgColor> _namedColors = <String, DsvgColor>{
  'aliceblue': DsvgColor.fromARGB(255, 240, 248, 255),
  'antiquewhite': DsvgColor.fromARGB(255, 250, 235, 215),
  'aqua': DsvgColor.fromARGB(255, 0, 255, 255),
  'aquamarine': DsvgColor.fromARGB(255, 127, 255, 212),
  'azure': DsvgColor.fromARGB(255, 240, 255, 255),
  'beige': DsvgColor.fromARGB(255, 245, 245, 220),
  'bisque': DsvgColor.fromARGB(255, 255, 228, 196),
  'black': DsvgColor.fromARGB(255, 0, 0, 0),
  'blanchedalmond': DsvgColor.fromARGB(255, 255, 235, 205),
  'blue': DsvgColor.fromARGB(255, 0, 0, 255),
  'blueviolet': DsvgColor.fromARGB(255, 138, 43, 226),
  'brown': DsvgColor.fromARGB(255, 165, 42, 42),
  'burlywood': DsvgColor.fromARGB(255, 222, 184, 135),
  'cadetblue': DsvgColor.fromARGB(255, 95, 158, 160),
  'chartreuse': DsvgColor.fromARGB(255, 127, 255, 0),
  'chocolate': DsvgColor.fromARGB(255, 210, 105, 30),
  'coral': DsvgColor.fromARGB(255, 255, 127, 80),
  'cornflowerblue': DsvgColor.fromARGB(255, 100, 149, 237),
  'cornsilk': DsvgColor.fromARGB(255, 255, 248, 220),
  'crimson': DsvgColor.fromARGB(255, 220, 20, 60),
  'cyan': DsvgColor.fromARGB(255, 0, 255, 255),
  'darkblue': DsvgColor.fromARGB(255, 0, 0, 139),
  'darkcyan': DsvgColor.fromARGB(255, 0, 139, 139),
  'darkgoldenrod': DsvgColor.fromARGB(255, 184, 134, 11),
  'darkgray': DsvgColor.fromARGB(255, 169, 169, 169),
  'darkgreen': DsvgColor.fromARGB(255, 0, 100, 0),
  'darkgrey': DsvgColor.fromARGB(255, 169, 169, 169),
  'darkkhaki': DsvgColor.fromARGB(255, 189, 183, 107),
  'darkmagenta': DsvgColor.fromARGB(255, 139, 0, 139),
  'darkolivegreen': DsvgColor.fromARGB(255, 85, 107, 47),
  'darkorange': DsvgColor.fromARGB(255, 255, 140, 0),
  'darkorchid': DsvgColor.fromARGB(255, 153, 50, 204),
  'darkred': DsvgColor.fromARGB(255, 139, 0, 0),
  'darksalmon': DsvgColor.fromARGB(255, 233, 150, 122),
  'darkseagreen': DsvgColor.fromARGB(255, 143, 188, 143),
  'darkslateblue': DsvgColor.fromARGB(255, 72, 61, 139),
  'darkslategray': DsvgColor.fromARGB(255, 47, 79, 79),
  'darkslategrey': DsvgColor.fromARGB(255, 47, 79, 79),
  'darkturquoise': DsvgColor.fromARGB(255, 0, 206, 209),
  'darkviolet': DsvgColor.fromARGB(255, 148, 0, 211),
  'deeppink': DsvgColor.fromARGB(255, 255, 20, 147),
  'deepskyblue': DsvgColor.fromARGB(255, 0, 191, 255),
  'dimgray': DsvgColor.fromARGB(255, 105, 105, 105),
  'dimgrey': DsvgColor.fromARGB(255, 105, 105, 105),
  'dodgerblue': DsvgColor.fromARGB(255, 30, 144, 255),
  'firebrick': DsvgColor.fromARGB(255, 178, 34, 34),
  'floralwhite': DsvgColor.fromARGB(255, 255, 250, 240),
  'forestgreen': DsvgColor.fromARGB(255, 34, 139, 34),
  'fuchsia': DsvgColor.fromARGB(255, 255, 0, 255),
  'gainsboro': DsvgColor.fromARGB(255, 220, 220, 220),
  'ghostwhite': DsvgColor.fromARGB(255, 248, 248, 255),
  'gold': DsvgColor.fromARGB(255, 255, 215, 0),
  'goldenrod': DsvgColor.fromARGB(255, 218, 165, 32),
  'gray': DsvgColor.fromARGB(255, 128, 128, 128),
  'grey': DsvgColor.fromARGB(255, 128, 128, 128),
  'green': DsvgColor.fromARGB(255, 0, 128, 0),
  'greenyellow': DsvgColor.fromARGB(255, 173, 255, 47),
  'honeydew': DsvgColor.fromARGB(255, 240, 255, 240),
  'hotpink': DsvgColor.fromARGB(255, 255, 105, 180),
  'indianred': DsvgColor.fromARGB(255, 205, 92, 92),
  'indigo': DsvgColor.fromARGB(255, 75, 0, 130),
  'ivory': DsvgColor.fromARGB(255, 255, 255, 240),
  'khaki': DsvgColor.fromARGB(255, 240, 230, 140),
  'lavender': DsvgColor.fromARGB(255, 230, 230, 250),
  'lavenderblush': DsvgColor.fromARGB(255, 255, 240, 245),
  'lawngreen': DsvgColor.fromARGB(255, 124, 252, 0),
  'lemonchiffon': DsvgColor.fromARGB(255, 255, 250, 205),
  'lightblue': DsvgColor.fromARGB(255, 173, 216, 230),
  'lightcoral': DsvgColor.fromARGB(255, 240, 128, 128),
  'lightcyan': DsvgColor.fromARGB(255, 224, 255, 255),
  'lightgoldenrodyellow': DsvgColor.fromARGB(255, 250, 250, 210),
  'lightgray': DsvgColor.fromARGB(255, 211, 211, 211),
  'lightgreen': DsvgColor.fromARGB(255, 144, 238, 144),
  'lightgrey': DsvgColor.fromARGB(255, 211, 211, 211),
  'lightpink': DsvgColor.fromARGB(255, 255, 182, 193),
  'lightsalmon': DsvgColor.fromARGB(255, 255, 160, 122),
  'lightseagreen': DsvgColor.fromARGB(255, 32, 178, 170),
  'lightskyblue': DsvgColor.fromARGB(255, 135, 206, 250),
  'lightslategray': DsvgColor.fromARGB(255, 119, 136, 153),
  'lightslategrey': DsvgColor.fromARGB(255, 119, 136, 153),
  'lightsteelblue': DsvgColor.fromARGB(255, 176, 196, 222),
  'lightyellow': DsvgColor.fromARGB(255, 255, 255, 224),
  'lime': DsvgColor.fromARGB(255, 0, 255, 0),
  'limegreen': DsvgColor.fromARGB(255, 50, 205, 50),
  'linen': DsvgColor.fromARGB(255, 250, 240, 230),
  'magenta': DsvgColor.fromARGB(255, 255, 0, 255),
  'maroon': DsvgColor.fromARGB(255, 128, 0, 0),
  'mediumaquamarine': DsvgColor.fromARGB(255, 102, 205, 170),
  'mediumblue': DsvgColor.fromARGB(255, 0, 0, 205),
  'mediumorchid': DsvgColor.fromARGB(255, 186, 85, 211),
  'mediumpurple': DsvgColor.fromARGB(255, 147, 112, 219),
  'mediumseagreen': DsvgColor.fromARGB(255, 60, 179, 113),
  'mediumslateblue': DsvgColor.fromARGB(255, 123, 104, 238),
  'mediumspringgreen': DsvgColor.fromARGB(255, 0, 250, 154),
  'mediumturquoise': DsvgColor.fromARGB(255, 72, 209, 204),
  'mediumvioletred': DsvgColor.fromARGB(255, 199, 21, 133),
  'midnightblue': DsvgColor.fromARGB(255, 25, 25, 112),
  'mintcream': DsvgColor.fromARGB(255, 245, 255, 250),
  'mistyrose': DsvgColor.fromARGB(255, 255, 228, 225),
  'moccasin': DsvgColor.fromARGB(255, 255, 228, 181),
  'navajowhite': DsvgColor.fromARGB(255, 255, 222, 173),
  'navy': DsvgColor.fromARGB(255, 0, 0, 128),
  'oldlace': DsvgColor.fromARGB(255, 253, 245, 230),
  'olive': DsvgColor.fromARGB(255, 128, 128, 0),
  'olivedrab': DsvgColor.fromARGB(255, 107, 142, 35),
  'orange': DsvgColor.fromARGB(255, 255, 165, 0),
  'orangered': DsvgColor.fromARGB(255, 255, 69, 0),
  'orchid': DsvgColor.fromARGB(255, 218, 112, 214),
  'palegoldenrod': DsvgColor.fromARGB(255, 238, 232, 170),
  'palegreen': DsvgColor.fromARGB(255, 152, 251, 152),
  'paleturquoise': DsvgColor.fromARGB(255, 175, 238, 238),
  'palevioletred': DsvgColor.fromARGB(255, 219, 112, 147),
  'papayawhip': DsvgColor.fromARGB(255, 255, 239, 213),
  'peachpuff': DsvgColor.fromARGB(255, 255, 218, 185),
  'peru': DsvgColor.fromARGB(255, 205, 133, 63),
  'pink': DsvgColor.fromARGB(255, 255, 192, 203),
  'plum': DsvgColor.fromARGB(255, 221, 160, 221),
  'powderblue': DsvgColor.fromARGB(255, 176, 224, 230),
  'purple': DsvgColor.fromARGB(255, 128, 0, 128),
  'red': DsvgColor.fromARGB(255, 255, 0, 0),
  'rosybrown': DsvgColor.fromARGB(255, 188, 143, 143),
  'royalblue': DsvgColor.fromARGB(255, 65, 105, 225),
  'saddlebrown': DsvgColor.fromARGB(255, 139, 69, 19),
  'salmon': DsvgColor.fromARGB(255, 250, 128, 114),
  'sandybrown': DsvgColor.fromARGB(255, 244, 164, 96),
  'seagreen': DsvgColor.fromARGB(255, 46, 139, 87),
  'seashell': DsvgColor.fromARGB(255, 255, 245, 238),
  'sienna': DsvgColor.fromARGB(255, 160, 82, 45),
  'silver': DsvgColor.fromARGB(255, 192, 192, 192),
  'skyblue': DsvgColor.fromARGB(255, 135, 206, 235),
  'slateblue': DsvgColor.fromARGB(255, 106, 90, 205),
  'slategray': DsvgColor.fromARGB(255, 112, 128, 144),
  'slategrey': DsvgColor.fromARGB(255, 112, 128, 144),
  'snow': DsvgColor.fromARGB(255, 255, 250, 250),
  'springgreen': DsvgColor.fromARGB(255, 0, 255, 127),
  'steelblue': DsvgColor.fromARGB(255, 70, 130, 180),
  'tan': DsvgColor.fromARGB(255, 210, 180, 140),
  'teal': DsvgColor.fromARGB(255, 0, 128, 128),
  'thistle': DsvgColor.fromARGB(255, 216, 191, 216),
  'tomato': DsvgColor.fromARGB(255, 255, 99, 71),
  'transparent': DsvgColor.fromARGB(0, 255, 255, 255),
  'turquoise': DsvgColor.fromARGB(255, 64, 224, 208),
  'violet': DsvgColor.fromARGB(255, 238, 130, 238),
  'wheat': DsvgColor.fromARGB(255, 245, 222, 179),
  'white': DsvgColor.fromARGB(255, 255, 255, 255),
  'whitesmoke': DsvgColor.fromARGB(255, 245, 245, 245),
  'yellow': DsvgColor.fromARGB(255, 255, 255, 0),
  'yellowgreen': DsvgColor.fromARGB(255, 154, 205, 50),
};
