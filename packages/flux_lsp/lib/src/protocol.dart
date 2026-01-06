/// LSP Protocol message types and constants
/// 
/// Implements a minimal subset of the Language Server Protocol

class LspMethod {
  static const String initialize = 'initialize';
  static const String initialized = 'initialized';
  static const String shutdown = 'shutdown';
  static const String exit = 'exit';
  
  static const String textDocumentDidOpen = 'textDocument/didOpen';
  static const String textDocumentDidChange = 'textDocument/didChange';
  static const String textDocumentDidClose = 'textDocument/didClose';
  static const String textDocumentHover = 'textDocument/hover';
  static const String textDocumentCompletion = 'textDocument/completion';
  static const textDocumentPublishDiagnostics = 'textDocument/publishDiagnostics';
  static const textDocumentDefinition = 'textDocument/definition';
  static const textDocumentReferences = 'textDocument/references';
}

/// Represents a location in a source file
class Location {
  final String uri;
  final Range range;
  
  Location({required this.uri, required this.range});
  
  Map<String, dynamic> toJson() => {
    'uri': uri,
    'range': range.toJson(),
  };
}

class DiagnosticSeverity {
  static const int error = 1;
  static const int warning = 2;
  static const int information = 3;
  static const int hint = 4;
}

class CompletionItemKind {
  static const int text = 1;
  static const int method = 2;
  static const int function = 3;
  static const int constructor = 4;
  static const int field = 5;
  static const int variable = 6;
  static const int classKind = 7;
  static const int interface = 8;
  static const int module = 9;
  static const int property = 10;
  static const int keyword = 14;
  static const int snippet = 15;
}

/// Position in a text document (0-indexed line and character)
class Position {
  final int line;
  final int character;
  
  Position(this.line, this.character);
  
  Map<String, dynamic> toJson() => {
    'line': line,
    'character': character,
  };
  
  factory Position.fromJson(Map<String, dynamic> json) => Position(
    json['line'] as int,
    json['character'] as int,
  );
}

/// Range in a text document
class Range {
  final Position start;
  final Position end;
  
  Range(this.start, this.end);
  
  Map<String, dynamic> toJson() => {
    'start': start.toJson(),
    'end': end.toJson(),
  };
  
  factory Range.fromJson(Map<String, dynamic> json) => Range(
    Position.fromJson(json['start'] as Map<String, dynamic>),
    Position.fromJson(json['end'] as Map<String, dynamic>),
  );
}

/// Diagnostic message
class Diagnostic {
  final Range range;
  final int severity;
  final String message;
  final String? source;
  
  Diagnostic({
    required this.range,
    required this.severity,
    required this.message,
    this.source,
  });
  
  Map<String, dynamic> toJson() => {
    'range': range.toJson(),
    'severity': severity,
    'message': message,
    if (source != null) 'source': source,
  };
}

/// Completion item
class CompletionItem {
  final String label;
  final int kind;
  final String? detail;
  final String? documentation;
  final String? insertText;
  
  CompletionItem({
    required this.label,
    required this.kind,
    this.detail,
    this.documentation,
    this.insertText,
  });
  
  Map<String, dynamic> toJson() => {
    'label': label,
    'kind': kind,
    if (detail != null) 'detail': detail,
    if (documentation != null) 'documentation': documentation,
    if (insertText != null) 'insertText': insertText,
  };
}

/// Hover result
class Hover {
  final String contents;
  final Range? range;
  
  Hover({required this.contents, this.range});
  
  Map<String, dynamic> toJson() => {
    'contents': {'kind': 'markdown', 'value': contents},
    if (range != null) 'range': range!.toJson(),
  };
}

/// Context for code completion
class CompletionContext {
  final bool isWidgetProperty;
  final String? widgetName;
  
  CompletionContext({this.isWidgetProperty = false, this.widgetName});
}
