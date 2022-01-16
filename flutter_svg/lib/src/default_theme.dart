import 'package:dart_svg/dsl/dsvg.dart';
import 'package:flutter/widgets.dart';

/// The SVG theme to apply to descendant SvgPicture widgets
/// which don't have explicit theme values.
class DefaultDsvgTheme extends InheritedTheme {
  /// Creates a default SVG theme for the given subtree
  /// using the provided [theme].
  const DefaultDsvgTheme({
    required final Widget child,
    required final this.theme,
    final Key? key,
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
  static DefaultDsvgTheme? of(
    final BuildContext context,
  ) =>
      context.dependOnInheritedWidgetOfExactType<DefaultDsvgTheme>();

  @override
  bool updateShouldNotify(
    final DefaultDsvgTheme oldWidget,
  ) =>
      theme != oldWidget.theme;

  @override
  Widget wrap(
    final BuildContext context,
    final Widget child,
  ) =>
      DefaultDsvgTheme(
        theme: theme,
        child: child,
      );
}
