import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flux_dap/src/dap_session.dart';

/// Debug Adapter Protocol Server for Flux
///
/// Implements the DAP specification for VSCode debugging integration.
/// Communicates via stdin/stdout using JSON-RPC protocol.
class DapServer {
  final Map<int, DapSession> _sessions = {};
  int _nextSessionId = 1;

  /// Start the DAP server listening on stdin/stdout
  Future<void> run() async {
    final input = stdin.transform(utf8.decoder);

    await for (final data in input) {
      try {
        final message = _parseMessage(data);
        if (message != null) {
          await _handleMessage(message);
        }
      } catch (e) {
        _sendError(-1, 'Parse error: $e');
      }
    }
  }

  Map<String, dynamic>? _parseMessage(String data) {
    // DAP messages are prefixed with Content-Length header
    final lines = data.split('\r\n');
    int? contentLength;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('Content-Length:')) {
        contentLength = int.tryParse(line.substring(15).trim());
      }
      if (line.isEmpty && contentLength != null) {
        final body = lines.sublist(i + 1).join('\r\n');
        if (body.length >= contentLength) {
          return jsonDecode(body.substring(0, contentLength))
              as Map<String, dynamic>;
        }
      }
    }

    // Try parsing as raw JSON (for testing)
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleMessage(Map<String, dynamic> message) async {
    final type = message['type'] as String?;
    final command = message['command'] as String?;
    final seq = message['seq'] as int? ?? 0;
    final args = message['arguments'] as Map<String, dynamic>? ?? {};

    if (type == 'request' && command != null) {
      await _handleRequest(seq, command, args);
    }
  }

  Future<void> _handleRequest(
      int seq, String command, Map<String, dynamic> args) async {
    switch (command) {
      case 'initialize':
        _sendResponse(seq, command, body: {
          'supportsConfigurationDoneRequest': true,
          'supportsEvaluateForHovers': true,
          'supportsStepInTargetsRequest': false,
          'supportsConditionalBreakpoints': true,
          'supportsLogPoints': false,
        });
        _sendEvent('initialized');
        break;

      case 'launch':
        final program = args['program'] as String?;
        if (program == null) {
          _sendError(seq, 'launch requires "program" argument');
          return;
        }

        final sessionId = _nextSessionId++;
        final session = DapSession(sessionId, program);
        _sessions[sessionId] = session;

        await session.launch();
        _sendResponse(seq, command);
        break;

      case 'setBreakpoints':
        final source = args['source'] as Map<String, dynamic>;
        final path = source['path'] as String;
        final breakpoints = args['breakpoints'] as List? ?? [];

        final session = _sessions.values.firstOrNull;
        if (session != null) {
          final verified = session.setBreakpoints(
            path,
            breakpoints.map((b) => (b as Map)['line'] as int).toList(),
          );
          _sendResponse(seq, command, body: {
            'breakpoints': verified.map((v) => {'verified': v}).toList(),
          });
        } else {
          _sendResponse(seq, command, body: {'breakpoints': []});
        }
        break;

      case 'configurationDone':
        final session = _sessions.values.firstOrNull;
        session?.run();
        _sendResponse(seq, command);
        break;

      case 'threads':
        _sendResponse(seq, command, body: {
          'threads': [
            {'id': 1, 'name': 'main'}
          ],
        });
        break;

      case 'stackTrace':
        final session = _sessions.values.firstOrNull;
        final frames = await session?.getStackTrace() ?? [];
        _sendResponse(seq, command, body: {
          'stackFrames': frames,
          'totalFrames': frames.length,
        });
        break;

      case 'scopes':
        final frameId = args['frameId'] as int? ?? 0;
        _sendResponse(seq, command, body: {
          'scopes': [
            {
              'name': 'Locals',
              'variablesReference': frameId + 1000,
              'expensive': false
            },
            {'name': 'Globals', 'variablesReference': 1, 'expensive': false},
          ],
        });
        break;

      case 'variables':
        final ref = args['variablesReference'] as int? ?? 0;
        final session = _sessions.values.firstOrNull;
        final variables = await session?.getVariables(ref) ?? [];
        _sendResponse(seq, command, body: {'variables': variables});
        break;

      case 'continue':
        final session = _sessions.values.firstOrNull;
        session?.continue_();
        _sendResponse(seq, command, body: {'allThreadsContinued': true});
        break;

      case 'next': // stepOver
        final session = _sessions.values.firstOrNull;
        session?.stepOver();
        _sendResponse(seq, command);
        break;

      case 'stepIn':
        final session = _sessions.values.firstOrNull;
        session?.stepInto();
        _sendResponse(seq, command);
        break;

      case 'stepOut':
        final session = _sessions.values.firstOrNull;
        session?.stepOut();
        _sendResponse(seq, command);
        break;

      case 'evaluate':
        final expression = args['expression'] as String? ?? '';
        final frameId = args['frameId'] as int?;
        final session = _sessions.values.firstOrNull;

        if (session != null) {
          final result = await session.evaluate(expression, frameId: frameId);
          _sendResponse(seq, command, body: {
            'result': result.toString(),
            'variablesReference': 0,
          });
        } else {
          _sendError(seq, 'No active session');
        }
        break;

      case 'disconnect':
        for (final session in _sessions.values) {
          session.terminate();
        }
        _sessions.clear();
        _sendResponse(seq, command);
        exit(0);

      default:
        _sendError(seq, 'Unknown command: $command');
    }
  }

  int _responseSeq = 1;

  void _sendResponse(int requestSeq, String command,
      {Map<String, dynamic>? body}) {
    _send({
      'seq': _responseSeq++,
      'type': 'response',
      'request_seq': requestSeq,
      'success': true,
      'command': command,
      if (body != null) 'body': body,
    });
  }

  void _sendError(int requestSeq, String message) {
    _send({
      'seq': _responseSeq++,
      'type': 'response',
      'request_seq': requestSeq,
      'success': false,
      'message': message,
    });
  }

  void _sendEvent(String event, {Map<String, dynamic>? body}) {
    _send({
      'seq': _responseSeq++,
      'type': 'event',
      'event': event,
      if (body != null) 'body': body,
    });
  }

  void _send(Map<String, dynamic> message) {
    final json = jsonEncode(message);
    final content = 'Content-Length: ${json.length}\r\n\r\n$json';
    stdout.write(content);
  }
}
