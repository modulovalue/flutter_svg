import 'package:xml/xml_events.dart';

import '../dsl/dsvg.dart';

/// Maintains state while constructing the Svg tree.
abstract class SvgParserState {
  SvgErrorDelegate get errorDelegate;

  abstract DsvgParentRoot? absoluteRoot;

  /// The current parent.
  DsvgParent? get current;

  /// Pushes a new parent onto the stack.
  void push(
    final String eventName,
    final DsvgParent? drawable,
  );

  DsvgDrawableDefinitionRegistry get definitions;

  bool get inDefs;

  Map<String, String> get currentAttributes;

  XmlStartElementEvent? get currentStartElement;

  Iterable<XmlEvent> readSubtree();

  /// Whether the given [DsvgDrawableStyleable] belongs
  /// in the [definitions] or not.
  bool checkForIri(
    final DsvgDrawableStyleable? drawable,
  );
}

abstract class ParentDrawable {
  String get name;

  DsvgParent? get drawable;
}

abstract class SvgErrorDelegate {
  /// Warns about nested svg elements.
  void reportUnsupportedNestedSvg();

  /// Reports a missing or undefined `<defs>` element.
  void reportMissingDef(
    final String? href,
    final String methodName,
  );

  /// Prints an error for unhandled elements.
  ///
  /// Will only print an error once for unhandled/unexpected elements, except for
  /// `<style/>`, `<title/>`, and `<desc/>` elements.
  void reportUnhandledElement(
    final String name,
  );

  /// Reports that a clip path child is unsupported.
  void reportUnsupportedClipPathChild(
    final String name,
  );

  void reportUnsupportedUnits(
    final String raw,
  );
}

abstract class DsvgDrawableDefinitionRegistry implements DsvgDrawableDefinitionRegistryView {
  /// Add a [DsvgDrawable] that can later be referred to by [id].
  void addDrawable(
    final String id,
    final DsvgDrawableStyleable drawable,
  );

  /// Add a [DsvgGradient] to the pre-defined collection by [id].
  void addGradient(
    final String id,
    final DsvgGradient gradient,
  );

  /// Add a [List<Path>] of clip paths by [id].
  void addClipPath(
    final String id,
    final List<DsvgPath> paths,
  );
}

abstract class DsvgDrawableDefinitionRegistryView {
  /// Attempt to lookup a [DsvgDrawable] by [id].
  DsvgDrawableStyleable getDrawable(
    final String id,
  );

  /// Attempt to lookup a pre-defined Shader by [id].
  DsvgGradient? getShader(
    final String id,
  );

  /// Retrieve a gradient from the pre-defined [DsvgGradient] collection.
  T? getGradient<T extends DsvgGradient?>(
    final String id,
  );

  /// Get a [List<Path>] of clip paths by [id].
  List<DsvgPath>? getClipPath(
    final String id,
  );

  /// Returns all known drawables.
  Iterable<MapEntry<String, DsvgDrawableStyleable>> get allDrawables;
}
