import 'package:xml/xml_events.dart';

import '../dsl/dsvg.dart';
import '../parser/parse_element.dart';
import '../parser/parse_iri.dart';
import '../parser/parse_path.dart';
import '../parser/parse_style.dart';
import '../parser/parse_transform.dart';
import '../parser/parser_state.dart';
import '../util/event_to_source_location.dart';
import 'parse_attribute.dart';
import 'parse_iri.dart';

// TODO take a look at https://github.com/wasabia/three_dart/blob/90438acb0b8bcc4eeda63f79beab7db6d2fe8298/lib/three3d/loaders/SVGLoaderParser.dart
DsvgParseResult parseSvg({
  required final String xml,
  required final DsvgTheme theme,
  required final SvgErrorDelegate errorDelegate,
}) {
  final state = _SvgParserStateImpl(
    eventIterator: parseEvents(
      xml,
    ).iterator,
    errorDelegate: errorDelegate,
  );
  return DsvgParseResult(
    root: () {
      // Drive the [XmlTextReader] to EOF and produce a [DsvgDrawableRoot].
      for (final event in state.readSubtree()) {
        if (event is XmlStartElementEvent) {
          if (event.name == 'defs') {
            // We won't get a call to `endElement()` if we're in a '<defs/>'
            state.inDefs = !event.isSelfClosing;
          } else {
            final pathFunc = parsePath(
              pathName: event.name,
              attributes: state.currentAttributes.typedGet,
              xHeight: theme.xHeight,
              fontSize: theme.fontSize,
            );
            if (pathFunc != null) {
              final parent = state.current!;
              final parentStyle = parent.matchParent(
                root: (final a) => a.groupData.style,
                group: (final a) => a.groupData.style,
              );
              final dsvgPath = pathFunc();
              final drawable = DsvgDrawableStyleable(
                styleable: DsvgDrawableShape(
                  sourceLocation: xmlEventToDsvgSourceLocation(
                    event: event,
                  ),
                  id: getAttribute(
                    state.currentAttributes.typedGet,
                    'id',
                    def: '',
                  ),
                  path: dsvgPath,
                  style: parseStyle(
                    errorDelegate,
                    state.currentAttributes.typedGet,
                    state.definitions,
                    parentStyle,
                    defaultFillColor: const DsvgColor(0xFF000000),
                    currentColor: parent.matchParent(
                      root: (final a) => a.groupData.color,
                      group: (final a) => a.groupData.color,
                    ),
                    fontSize: theme.fontSize,
                    xHeight: theme.xHeight,
                  ),
                  transform: parseTransform(
                    getAttribute(
                      state.currentAttributes.typedGet,
                      'transform',
                      def: '',
                    ),
                  ),
                ),
              );
              final isIri = state.checkForIri(drawable);
              if (!state.inDefs || !isIri) {
                parent
                    .matchParent(
                      root: (final a) => a.groupData.children,
                      group: (final a) => a.groupData.children,
                    )
                    .add(drawable);
              }
            } else {
              final element = parseElement(
                event: event,
                errorDelegate: errorDelegate,
                parserState: state,
                theme: theme,
              );
              if (element == null) {
                if (!event.isSelfClosing) {
                  state._discardSubtree();
                }
                assert(() {
                  errorDelegate.reportUnhandledElement(event.name);
                  return true;
                }(), "");
              }
            }
          }
        } else if (event is XmlEndElementEvent) {
          if (event.name == state.currentGroupName) {
            state.pop();
          }
          if (event.name == 'defs') {
            state.inDefs = false;
          }
        }
      }
      if (state.absoluteRoot == null) {
        throw StateError('Invalid SVG data');
      } else {
        return state.absoluteRoot!;
      }
    }(),
    definitions: state.definitions,
  );
}

class DsvgParseResult {
  final DsvgParentRoot root;
  final DsvgDrawableDefinitionRegistryView definitions;

  const DsvgParseResult({
    required final this.root,
    required final this.definitions,
  });
}

class _SvgParserStateImpl implements SvgParserState {
  _SvgParserStateImpl({
    required final this.eventIterator,
    required final this.errorDelegate,
  })  : definitions = _DsvgDrawableDefinitionRegistryImpl(),
        parentDrawables2 = <ParentDrawable>[],
        inDefs = false,
        depth = 0;

  final Iterator<XmlEvent> eventIterator;
  @override
  final SvgErrorDelegate errorDelegate;
  @override
  final DsvgDrawableDefinitionRegistry definitions;
  final List<ParentDrawable> parentDrawables2;
  @override
  DsvgParentRoot? absoluteRoot;
  @override
  bool inDefs;
  @override
  late Map<String, String> currentAttributes;
  @override
  XmlStartElementEvent? currentStartElement;
  int depth;

  @override
  DsvgParent? get current => parentDrawables2.last.drawable;

  String? get currentGroupName => parentDrawables2.last.name;

  void pop() => parentDrawables2.removeLast();

  @override
  bool checkForIri(
    final DsvgDrawableStyleable? drawable,
  ) {
    final iri = parseUrlIri(
      attributes: currentAttributes.typedGet,
    );
    if (iri != 'url(#)') {
      definitions.addDrawable(iri, drawable!);
      return true;
    } else {
      return false;
    }
  }

  @override
  void push(
    final String eventName,
    final DsvgParent? drawable,
  ) {
    parentDrawables2.add(
      _ParentDrawableImpl(
        name: eventName,
        drawable: drawable,
      ),
    );
    checkForIri(
      () {
        if (drawable == null) {
          return null;
        } else {
          return DsvgDrawableStyleable(
            styleable: DsvgDrawableParent(
              parent: drawable,
            ),
          );
        }
      }(),
    );
  }

  void _discardSubtree() {
    final subtreeStartDepth = depth;
    while (eventIterator.moveNext()) {
      final event = eventIterator.current;
      if (event is XmlStartElementEvent && !event.isSelfClosing) {
        depth += 1;
      } else if (event is XmlEndElementEvent) {
        depth -= 1;
        assert(
          depth >= 0,
          "The depth must be greater than zero.",
        );
      }
      currentAttributes = <String, String>{};
      currentStartElement = null;
      if (depth < subtreeStartDepth) {
        return;
      }
    }
  }

  @override
  Iterable<XmlEvent> readSubtree() sync* {
    final subtreeStartDepth = depth;
    while (eventIterator.moveNext()) {
      final event = eventIterator.current;
      bool isSelfClosing = false;
      if (event is XmlStartElementEvent) {
        final attributeMap = <String, String>{
          for (final attribute in event.attributes)
            attribute.localName: attribute.value.trim(),
        };
        if (getAttribute(attributeMap.typedGet, 'display', def: '') == 'none' ||
            getAttribute(attributeMap.typedGet, 'visibility', def: '') == 'hidden') {
          print(
            'SVG Warning: Discarding:\n\n  $event\n\n'
            'and any children it has since it is not visible.\n'
            'If that element is meant to be visible, the `display` or '
            '`visibility` attributes should be removed.\n'
            'If that element is not meant to be visible, it would be better '
            'to remove it from the SVG file.',
          );
          if (!event.isSelfClosing) {
            depth += 1;
            _discardSubtree();
          }
          continue;
        } else {
          currentAttributes = attributeMap;
          currentStartElement = event;
          depth += 1;
          isSelfClosing = event.isSelfClosing;
        }
      }
      yield event;
      if (isSelfClosing || event is XmlEndElementEvent) {
        depth -= 1;
        assert(
          depth >= 0,
          "The depth must be greater than zero.",
        );
        currentAttributes = <String, String>{};
        currentStartElement = null;
      }
      if (depth < subtreeStartDepth) {
        return;
      }
    }
  }
}

class _DsvgDrawableDefinitionRegistryImpl implements DsvgDrawableDefinitionRegistry {
  _DsvgDrawableDefinitionRegistryImpl()
      : _gradients = <String, DsvgGradient>{},
        _clipPaths = <String, List<DsvgPath>>{},
        _drawables = <String, DsvgDrawableStyleable>{};

  final Map<String, DsvgGradient> _gradients;
  final Map<String, List<DsvgPath>> _clipPaths;
  final Map<String, DsvgDrawableStyleable> _drawables;

  @override
  Iterable<MapEntry<String, DsvgDrawableStyleable>> get allDrawables => _drawables.entries;

  @override
  DsvgDrawableStyleable getDrawable(
    final String id,
  ) {
    final value = _drawables[id];
    if (value == null) {
      throw StateError(
        'Expected to find Drawable with id $id.\nHave ids: ${_drawables.keys}',
      );
    } else {
      return value;
    }
  }

  @override
  void addDrawable(
    final String id,
    final DsvgDrawableStyleable drawable,
  ) {
    assert(
      id != 'url(#)',
      "The id can't be an empty id",
    );
    _drawables[id] = drawable;
  }

  @override
  DsvgGradient? getShader(
    final String id,
  ) {
    final srv = _gradients[id];
    if (srv != null) {
      return srv;
    } else {
      return null;
    }
  }

  @override
  T? getGradient<T extends DsvgGradient?>(
    final String id,
  ) =>
      _gradients[id] as T?;

  @override
  void addGradient(
    final String id,
    final DsvgGradient gradient,
  ) =>
      _gradients[id] = gradient;

  @override
  List<DsvgPath>? getClipPath(
    final String id,
  ) =>
      _clipPaths[id];

  @override
  void addClipPath(
    final String id,
    final List<DsvgPath> paths,
  ) =>
      _clipPaths[id] = paths;
}

class _ParentDrawableImpl implements ParentDrawable {
  const _ParentDrawableImpl({
    required final this.name,
    required final this.drawable,
  });

  @override
  final String name;
  @override
  final DsvgParent? drawable;
}
