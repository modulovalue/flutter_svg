import 'package:xml/xml_events.dart';

import '../dsl/dsvg_source_location.dart';

DsvgSourceLocation xmlEventToDsvgSourceLocation({
  required final XmlEvent event,
}) =>
    xmlEventReadRange(
      event: event,
      read: (final offset, final end) => DsvgSourceLocation(
        offset: offset,
        end: end,
      ),
    );

T xmlEventReadRange<T>({
  required final XmlEvent event,
  required final T Function(int offet, int end) read,
}) {
  int? offset;
  int? end;
  event.accept(
    XmlEventVisitorRange(
      (final _offset, final _end) {
        offset = _offset;
        end = _end;
      },
    ),
  );
  return read(
    offset!,
    end!,
  );
}

class XmlEventVisitorRange with XmlEventVisitor {
  final void Function(
    int offset,
    int end,
  ) reportRange;

  const XmlEventVisitorRange(
    final this.reportRange,
  );

  @override
  void visitCDATAEvent(
    final XmlCDATAEvent event,
  ) =>
      reportRange(
        event.sourceRange!.offset,
        event.sourceRange!.end,
      );

  @override
  void visitCommentEvent(
    final XmlCommentEvent event,
  ) =>
      reportRange(
        event.sourceRange!.offset,
        event.sourceRange!.end,
      );

  @override
  void visitDeclarationEvent(
    final XmlDeclarationEvent event,
  ) =>
      reportRange(
        event.sourceRange!.offset,
        event.sourceRange!.end,
      );

  @override
  void visitDoctypeEvent(
    final XmlDoctypeEvent event,
  ) =>
      reportRange(
        event.sourceRange!.offset,
        event.sourceRange!.end,
      );

  @override
  void visitEndElementEvent(
    final XmlEndElementEvent event,
  ) =>
      reportRange(
        event.sourceRange!.offset,
        event.sourceRange!.end,
      );

  @override
  void visitProcessingEvent(
    final XmlProcessingEvent event,
  ) =>
      reportRange(
        event.sourceRange!.offset,
        event.sourceRange!.end,
      );

  @override
  void visitStartElementEvent(
    final XmlStartElementEvent event,
  ) =>
      reportRange(
        event.sourceRange!.offset,
        event.sourceRange!.end,
      );

  @override
  void visitTextEvent(
    final XmlTextEvent event,
  ) =>
      reportRange(
        event.sourceRange!.offset,
        event.sourceRange!.end,
      );
}
