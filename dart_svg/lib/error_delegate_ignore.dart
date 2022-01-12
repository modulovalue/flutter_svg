import 'parser/parser_state.dart';

class SvgErrorDelegateIgnoreImpl implements SvgErrorDelegate {
  const SvgErrorDelegateIgnoreImpl();

  @override
  void reportUnsupportedNestedSvg() {}

  @override
  void reportMissingDef(
    final String? href,
    final String methodName,
  ) {}

  @override
  void reportUnhandledElement(
    final String name,
  ) {}

  @override
  void reportUnsupportedClipPathChild(
    final String name,
  ) {}

  @override
  void reportUnsupportedUnits(
    final String raw,
  ) {}
}
