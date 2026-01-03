/// Flux Language Server
/// 
/// Implements the Language Server Protocol for Flux

import 'dart:convert';
import 'dart:io';

import 'protocol.dart';
import 'analysis.dart';
import 'widget_catalog.dart';

/// Flux Language Server implementation
class FluxLanguageServer {
  final FluxAnalyzer _analyzer = FluxAnalyzer();
  final Map<String, String> _documents = {};
  
  bool _initialized = false;
  bool _shutdown = false;
  
  /// Start the server, listening on stdin/stdout
  Future<void> start() async {
    final input = stdin.transform(utf8.decoder);
    
    String buffer = '';
    
    await for (final chunk in input) {
      buffer += chunk;
      
      // Parse LSP messages from buffer
      while (true) {
        final message = _parseMessage(buffer);
        if (message == null) break;
        
        buffer = message.remaining;
        await _handleMessage(message.content);
      }
    }
  }
  
  /// Parse a single LSP message from buffer
  _ParsedMessage? _parseMessage(String buffer) {
    // LSP messages start with Content-Length header
    final headerEnd = buffer.indexOf('\r\n\r\n');
    if (headerEnd == -1) return null;
    
    final headers = buffer.substring(0, headerEnd);
    final contentLengthMatch = RegExp(r'Content-Length: (\d+)').firstMatch(headers);
    if (contentLengthMatch == null) return null;
    
    final contentLength = int.parse(contentLengthMatch.group(1)!);
    final contentStart = headerEnd + 4;
    
    if (buffer.length < contentStart + contentLength) return null;
    
    final content = buffer.substring(contentStart, contentStart + contentLength);
    final remaining = buffer.substring(contentStart + contentLength);
    
    return _ParsedMessage(content, remaining);
  }
  
  /// Handle a parsed JSON-RPC message
  Future<void> _handleMessage(String content) async {
    final json = jsonDecode(content) as Map<String, dynamic>;
    final method = json['method'] as String?;
    final id = json['id'];
    final params = json['params'] as Map<String, dynamic>?;
    
    if (method == null) {
      // Response to our request - ignore for now
      return;
    }
    
    dynamic result;
    dynamic error;
    
    try {
      switch (method) {
        case LspMethod.initialize:
          result = _handleInitialize(params!);
          break;
        case LspMethod.initialized:
          _handleInitialized();
          break;
        case LspMethod.shutdown:
          result = _handleShutdown();
          break;
        case LspMethod.exit:
          _handleExit();
          break;
        case LspMethod.textDocumentDidOpen:
          _handleDidOpen(params!);
          break;
        case LspMethod.textDocumentDidChange:
          _handleDidChange(params!);
          break;
        case LspMethod.textDocumentDidClose:
          _handleDidClose(params!);
          break;
        case LspMethod.textDocumentHover:
          result = await _handleHover(params!);
          break;
        case LspMethod.textDocumentCompletion:
          result = _handleCompletion(params!);
          break;
        case LspMethod.textDocumentDefinition:
          result = await _handleDefinition(params!);
          break;
        case LspMethod.textDocumentReferences:
          result = await _handleReferences(params!);
          break;
        default:
          // Unknown method
          break;
      }
    } catch (e) {
      error = {'code': -32603, 'message': e.toString()};
    }
    
    // Send response if this was a request (has id)
    if (id != null) {
      _sendResponse(id, result, error);
    }
  }
  
  /// Handle initialize request
  Map<String, dynamic> _handleInitialize(Map<String, dynamic> params) {
    _initialized = true;
    
    return {
      'capabilities': {
        'textDocumentSync': {
          'openClose': true,
          'change': 1, // Full sync
        },
        'hoverProvider': true,
        'completionProvider': {
          'triggerCharacters': ['.', '('],
        },
        'definitionProvider': true,
        'referencesProvider': true,
      },
      'serverInfo': {
        'name': 'Flux Language Server',
        'version': '0.1.0',
      },
    };
  }
  
  /// Handle initialized notification
  void _handleInitialized() {
    // Client is ready
  }
  
  /// Handle shutdown request
  dynamic _handleShutdown() {
    _shutdown = true;
    return null;
  }
  
  /// Handle exit notification
  void _handleExit() {
    exit(_shutdown ? 0 : 1);
  }
  
  /// Handle textDocument/didOpen
  void _handleDidOpen(Map<String, dynamic> params) {
    final textDocument = params['textDocument'] as Map<String, dynamic>;
    final uri = textDocument['uri'] as String;
    final text = textDocument['text'] as String;
    
    _documents[uri] = text;
    _publishDiagnostics(uri, text);
  }
  
  /// Handle textDocument/didChange
  void _handleDidChange(Map<String, dynamic> params) {
    final textDocument = params['textDocument'] as Map<String, dynamic>;
    final uri = textDocument['uri'] as String;
    final changes = params['contentChanges'] as List;
    
    // Full sync mode - take the whole text
    if (changes.isNotEmpty) {
      final change = changes.first as Map<String, dynamic>;
      final text = change['text'] as String;
      _documents[uri] = text;
      _publishDiagnostics(uri, text);
    }
  }
  
  /// Handle textDocument/didClose
  void _handleDidClose(Map<String, dynamic> params) {
    final textDocument = params['textDocument'] as Map<String, dynamic>;
    final uri = textDocument['uri'] as String;
    _documents.remove(uri);
    
    // Clear diagnostics
    _sendNotification(LspMethod.textDocumentPublishDiagnostics, {
      'uri': uri,
      'diagnostics': [],
    });
  }
  
  /// Handle textDocument/hover
  Future<Map<String, dynamic>> _handleHover(Map<String, dynamic> params) async {
    final textDocument = params['textDocument'];
    final uri = textDocument['uri'];
    final position = params['position'];
    
    final pos = Position(position['line'], position['character']);
    
    final doc = _documents[uri];
    if (doc == null) return {'contents': []};
    
    final hover = _analyzer.getHover(doc, pos);
    
    if (hover != null) {
      return {
        'contents': hover.contents,
      };
    }
    
    return {'contents': []};
  }
  
  Future<dynamic> _handleDefinition(Map<String, dynamic> params) async {
    final textDocument = params['textDocument'];
    final uri = textDocument['uri'];
    final position = params['position'];
    
    final pos = Position(position['line'], position['character']);
    
    final doc = _documents[uri];
    if (doc == null) return null;
    
    final location = _analyzer.getDefinition(doc, uri, pos);
    
    if (location != null) {
      return location.toJson();
    }
    
    return null;
  }
  
  Future<dynamic> _handleReferences(Map<String, dynamic> params) async {
    final textDocument = params['textDocument'];
    final uri = textDocument['uri'];
    final position = params['position'];
    
    final pos = Position(position['line'], position['character']);
    
    final doc = _documents[uri];
    if (doc == null) return [];
    
    final locations = _analyzer.getReferences(doc, uri, pos);
    
    if (locations != null) {
      return locations.map((l) => l.toJson()).toList();
    }
    
    return [];
  }
  
  /// Handle textDocument/completion
  List<Map<String, dynamic>> _handleCompletion(Map<String, dynamic> params) {
    final textDocument = params['textDocument'];
    final uri = textDocument['uri'];
    final position = params['position'];
    final doc = _documents[uri];
    
    if (doc == null) return [];

    final items = <Map<String, dynamic>>[];
    
    // Simple context analysis: check if we are inside a widget Map
    // This is a basic implementation for the demo
    final pos = Position(position['line'], position['character']);
    final context = _analyzer.getCompletionContext(doc, pos);
    
    if (context.isWidgetProperty && context.widgetName != null) {
      final properties = WidgetCatalog.getProperties(context.widgetName!);
      if (properties != null) {
        for (final prop in properties) {
          items.add(prop.toCompletionItem());
        }
        return items;
      }
    }
    
    // Global scope completions
    // Add keyword completions
    for (final keyword in _keywords) {
      items.add(CompletionItem(
        label: keyword,
        kind: CompletionItemKind.keyword,
        detail: 'Flux keyword',
      ).toJson());
    }
    
    // Add widget completions
    for (final widget in WidgetCatalog.widgetNames) {
      items.add(CompletionItem(
        label: widget,
        kind: CompletionItemKind.classKind,
        detail: 'Flutter Widget',
      ).toJson());
    }
    
    // Add stdlib completions
    for (final fn in _stdlibFunctions) {
      items.add(CompletionItem(
        label: fn,
        kind: CompletionItemKind.function,
        detail: 'Standard library',
      ).toJson());
    }
    
    return items;
  }
  
  /// Publish diagnostics for a document
  void _publishDiagnostics(String uri, String source) {
    final result = _analyzer.analyze(source, uri);
    
    _sendNotification(LspMethod.textDocumentPublishDiagnostics, {
      'uri': uri,
      'diagnostics': result.diagnostics.map((d) => d.toJson()).toList(),
    });
  }
  
  /// Send a JSON-RPC response
  void _sendResponse(dynamic id, dynamic result, dynamic error) {
    final response = <String, dynamic>{
      'jsonrpc': '2.0',
      'id': id,
    };
    
    if (error != null) {
      response['error'] = error;
    } else {
      response['result'] = result;
    }
    
    _sendMessage(response);
  }
  
  /// Send a JSON-RPC notification
  void _sendNotification(String method, Map<String, dynamic> params) {
    _sendMessage({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    });
  }
  
  /// Send a message to stdout
  void _sendMessage(Map<String, dynamic> message) {
    final content = jsonEncode(message);
    final contentLength = utf8.encode(content).length;
    
    stdout.write('Content-Length: $contentLength\r\n\r\n$content');
  }
  
  // Completion data
  static const _keywords = [
    'widget', 'fn', 'async', 'await', 'var', 'state', 'props', 'build',
    'if', 'else', 'while', 'for', 'return', 'break', 'continue',
    'try', 'catch', 'finally', 'throw', 'class', 'new', 'import',
    'true', 'false', 'null',
  ];
  
  static const _widgets = [
    'Column', 'Row', 'Container', 'Text', 'Button', 'TextField',
    'ListView', 'ListTile', 'Scaffold', 'AppBar', 'Drawer',
    'Card', 'Icon', 'Image', 'Padding', 'Center', 'Expanded',
    'SizedBox', 'Stack', 'Positioned', 'GestureDetector',
  ];
  
  static const _stdlibFunctions = [
    'print', 'http.get', 'http.post', 'json.parse', 'json.stringify',
    'storage.get', 'storage.set', 'timer.delay',
  ];
}

class _ParsedMessage {
  final String content;
  final String remaining;
  
  _ParsedMessage(this.content, this.remaining);
}
