import 'package:dart_svg/dsl/dsvg.dart';
import 'package:flutter/widgets.dart';

/// The SVG theme to apply to descendant [SvgPicture] widgets
/// which don't have explicit theme values.
class DefaultSvgTheme extends InheritedTheme {
  /// Creates a default SVG theme for the given subtree
  /// using the provided [theme].
  const DefaultSvgTheme({
    final Key? key,
    required final Widget child,
    required final this.theme,
  }) : super(
          key: key,
          child: child,
        );

  /// The SVG theme to apply.
  final DsvgTheme theme;

  /// The closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// DefaultSvgTheme theme = DefaultSvgTheme.of(context);
  /// ```
  static DefaultSvgTheme? of(
    final BuildContext context,
  ) =>
      context.dependOnInheritedWidgetOfExactType<DefaultSvgTheme>();

  @override
  bool updateShouldNotify(
    final DefaultSvgTheme oldWidget,
  ) =>
      theme != oldWidget.theme;

  @override
  Widget wrap(
    final BuildContext context,
    final Widget child,
  ) =>
      DefaultSvgTheme(
        theme: theme,
        child: child,
      );
}
