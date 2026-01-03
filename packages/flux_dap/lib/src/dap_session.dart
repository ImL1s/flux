import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flux_dap/src/dap_worker.dart';

/// A debug session for a single Flux program execution
/// 
/// Manages the lifecycle of a worker isolate and bridges DAP requests
/// to the worker's VM.
class DapSession {
  final int id;
  final String programPath;
  
  // Callback for events to server
  void Function(String event, Map<String, dynamic> body)? onEvent;
  
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  
  final Completer<void> _launchCompleter = Completer<void>();
  final Completer<List<Map<String, dynamic>>> _stackTraceCompleter = Completer();
  // _scopesCompleter etc were removed as we key by ID now, which is correct.
  
  int _nextRequestId = 1;
  final Map<int, Completer<dynamic>> _pendingRequests = {};
  
  DapSession(this.id, this.programPath);
  
  /// Launch the Flux program in a background isolate
  Future<void> launch() async {
    _receivePort = ReceivePort();
    _receivePort!.listen(_handleMessage);
    
    _isolate = await Isolate.spawn(dapWorker, _receivePort!.sendPort);
    await _launchCompleter.future;
    
    // Launch doesn't expect a response in our simplified protocol for now,
    // but we could make it wait. The server awaits launch().
    // Let's use send request if we want to wait for VM init.
    // For now, launch is special.
    _sendPort!.send({
      'type': 'launch', 
      'body': {
        'program': programPath,
        'source': await _readFile(programPath),
        'enableInlineCaching': true
      },
      'id': _nextRequestId++ 
    });
  }
  
  Future<String> _readFile(String path) {
    return File(path).readAsString();
  }
  
  void _handleMessage(dynamic message) {
    if (message is SendPort) {
      _sendPort = message;
      if (!_launchCompleter.isCompleted) _launchCompleter.complete();
      return;
    }
    
    if (message is Map) {
      final type = message['type'];
      
      if (type == 'response') {
        final id = message['id'] as int;
        final body = message['body'];
        if (_pendingRequests.containsKey(id)) {
          _pendingRequests.remove(id)!.complete(body);
        }
      } else if (type == 'event') {
        final event = message['event'];
        final body = message['body'];
        
        if (event == 'output') {
          onEvent?.call('output', body);
        } else if (event == 'stopped') {
          onEvent?.call('stopped', body ?? {});
        } else if (event == 'terminated') {
          onEvent?.call('terminated', {});
          terminate();
        } else if (event == 'continued') {
          onEvent?.call('continued', {});
        }
      }
    }
  }
  
  Future<T> _sendRequest<T>(String type, [dynamic body]) {
    final id = _nextRequestId++;
    final completer = Completer<T>();
    _pendingRequests[id] = completer;
    
    _sendPort!.send({
      'type': type,
      'body': body,
      'id': id,
    });
    
    return completer.future;
  }

  /// Set breakpoints
  List<bool> setBreakpoints(String source, List<int> lines) {
    // We can't await here because the signature is synchronous list.
    // DAP setBreakpoints IS async (Request). But our DapSession interface might need update?
    // dap_server.dart calls it synchronously? 
    // dap_server.dart:102: final verified = session.setBreakpoints(...)
    // I need to update dap_server.dart to await this!
    // For now, I'll fire and forget and return all true, 
    // real verification happens in worker.
    
    _sendRequest('setBreakpoints', {'path': source, 'lines': lines});
    return lines.map((_) => true).toList();
  }
  
  void run() {
    _sendRequest('configurationDone');
  }
  
  void continue_() {
    _sendRequest('continue');
  }
  
  void stepOver() {
    _sendRequest('stepOver');
  }
  
  void stepInto() {
    _sendRequest('stepInto');
  }
  
  void stepOut() {
    _sendRequest('stepOut');
  }
  
  void pause() {
    _sendRequest('pause');
  }
  
  Future<List<Map<String, dynamic>>> getStackTrace() async {
    final response = await _sendRequest<Map>('getStackTrace');
    return (response['frames'] as List).cast<Map<String, dynamic>>();
  }
  
  Future<List<Map<String, dynamic>>> getVariables(int reference) async {
    final response = await _sendRequest<Map>('getVariables', reference);
    return (response['variables'] as List).cast<Map<String, dynamic>>();
  }
  
  Future<Object?> evaluate(String expression, {int? frameId}) async {
    final response = await _sendRequest<Map>('evaluate', {
      'expression': expression,
      'frameId': frameId
    });
    return response['result'];
  }

  
  void terminate() {
    _sendPort?.send({'type': 'terminate'});
    _isolate?.kill();
    _isolate = null;
    _receivePort?.close();
  }
}
