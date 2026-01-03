
import 'dart:async' as async;
import 'dart:isolate';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';


/// Command to send to the worker
class DapCommand {
  final String type;
  final dynamic body;
  
  DapCommand(this.type, [this.body]);
}

/// Message from the worker
class DapEvent {
  final String type;
  final dynamic body;
  
  DapEvent(this.type, [this.body]);
}

/// Entry point for the DAP worker isolate
void dapWorker(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  
  final worker = _DapWorker(sendPort, receivePort);
  worker.run();
}

class _DapWorker {
  final SendPort _sendPort;
  final ReceivePort _receivePort;
  
  VM? _vm;
  FluxDebugger? _debugger;
  
  _DapWorker(this._sendPort, this._receivePort);
  
  void run() async {
    await for (final message in _receivePort) {
      if (message is Map) {
        final type = message['type'] as String;
        final body = message['body'];
        final id = message['id'] as int?;
        await _handleCommand(type, body, id);
      }
    }
  }
  
  Chunk? _chunk; // Stored chunk for deferred execution
  
  Future<void> _handleCommand(String type, dynamic body, int? id) async {
    switch (type) {
      case 'launch':
        await _launch(body as Map);
        if (id != null) _sendResponse(id, {});
        break;
      case 'configurationDone':
        _configurationDone();
        if (id != null) _sendResponse(id, {});
        break;
      case 'setBreakpoints':
        _setBreakpoints(body as Map, id);
        break;
      case 'continue':
        _debugger?.continue_();
        if (id != null) _sendResponse(id, {});
        _sendEvent('continued');
        _resumeVM();
        break;
      case 'pause':
        _debugger?.pause();
        if (id != null) _sendResponse(id, {});
        // Pausing is tricky if VM is running synchronously. 
        // But VM checks checks debugger.isPaused in loop.
        // It will return InterpreResult.paused.
        break;
      case 'stepInto':
        _debugger?.stepInto();
        if (id != null) _sendResponse(id, {});
        _resumeVM();
        break;
      case 'stepOver':
        _debugger?.stepOver();
        if (id != null) _sendResponse(id, {});
        _resumeVM();
        break;
      case 'stepOut':
        _debugger?.stepOut();
        if (id != null) _sendResponse(id, {});
        _resumeVM();
        break;
      case 'getStackTrace':
        _getStackTrace(id);
        break;
      case 'getScopes':
        _getScopes(body as int? ?? 0, id);
        break;
      case 'getVariables':
        _getVariables(body as int, id);
        break;
      case 'evaluate':
        _evaluate(body as Map, id);
        break;
      case 'terminate':
        _receivePort.close();
        break;
    }
  }
  
  Future<void> _launch(Map args) async {
    final program = args['program'] as String;
    final enableInlineCaching = args['enableInlineCaching'] as bool? ?? true;
    
    // Create VM with inline caching option
    _vm = VM(enableInlineCaching: enableInlineCaching);
    _debugger = FluxDebugger(_vm!);
    
    // Listen to debug events
    _debugger!.addListener((event, context) {
      String eventType;
      switch (event) {
        case DebugEvent.breakpoint:
          eventType = 'stopped';
          break;
        case DebugEvent.step:
          eventType = 'stopped';
          break;
        case DebugEvent.error:
          eventType = 'stopped'; // treat error as stop
          break;
        case DebugEvent.resumed:
           // Typically DAP doesn't need explicit resumed event if response sent?
           // But 'continued' event is useful.
           // We might not need to send this if 'continue' command response handles it.
           // However, if paused by breakpoint, then resumed, we might want to know.
          return; 
        case DebugEvent.completed:
          eventType = 'terminated';
          break;
      }
      
      _sendEvent(eventType, {
        'reason': event == DebugEvent.step ? 'step' : 'breakpoint',
        'description': context.errorMessage,
        'threadId': 1,
      });
    });
    
    _debugger!.attach();
    
    try {
      final lexer = Lexer(args['source'] as String);
      final tokens = lexer.tokenize();
      
      final parser = Parser(tokens);
      final unit = parser.parse();
      
      final compiler = Compiler(unit: unit, moduleName: program);
      _chunk = compiler.chunk;
      
      _sendEvent('initialized');
      
      // Execution deferred to configurationDone
      
    } catch (e) {
      _sendEvent('output', {'category': 'stderr', 'output': 'Launch error: $e\n'});
      _sendEvent('terminated');
    }
  }
  
  void _configurationDone() {
     if (_vm == null || _chunk == null) return;
     _resumeVM(startFresh: true);
  }
  
  void _resumeVM({bool startFresh = false}) {
      // Run in a zone to capture output
      async.runZoned(() {
        try {
          // If startFresh, we run chunk. IF not, we resume.
          final result = startFresh ? _vm!.runChunk(_chunk!) : _vm!.resume();
          
          if (result == InterpretResult.ok) {
             _sendEvent('terminated');
          }
          // If paused, we do nothing (wait for next command)
        } catch (e) {
          _sendEvent('output', {'category': 'stderr', 'output': e.toString() + '\n'});
          _sendEvent('terminated');
        }
      }, zoneSpecification: async.ZoneSpecification(
        print: (self, parent, zone, line) {
           _sendEvent('output', {'category': 'stdout', 'output': line + '\n'});
        }
      ));
  }

  
  void _setBreakpoints(Map args, int? id) {
    if (_debugger == null) {
      if (id != null) _sendResponse(id, {'verified': []});
      return;
    }
    
    final path = args['path'] as String;
    final lines = (args['lines'] as List).cast<int>();
    
    _debugger!.clearBreakpoints(); // Simplify
    
    final verified = <bool>[];
    for (final line in lines) {
      _debugger!.setBreakpoint(path, line);
      verified.add(true);
    }
    
    if (id != null) {
      _sendResponse(id, {'verified': verified});
    }
  }
  
  void _getStackTrace(int? id) {
    if (_debugger == null) {
      if (id != null) _sendResponse(id, {'frames': []});
      return;
    }
    
    final frames = _debugger!.getCallStack();
    final serializedFrames = frames.map((f) => {
      'index': f.index,
      'name': f.functionName,
      'file': f.source,
      'line': f.line,
    }).toList();
    
    if (id != null) {
      _sendResponse(id, {'frames': serializedFrames});
    }
  }
  
  void _getScopes(int frameId, int? id) {
     final scopes = [
         {'name': 'Locals', 'variablesReference': frameId + 1000, 'expensive': false},
         {'name': 'Globals', 'variablesReference': 1, 'expensive': false},
     ];
     
     if (id != null) {
       _sendResponse(id, {'scopes': scopes});
     }
  }
  
  void _getVariables(int ref, int? id) {
    if (_debugger == null) {
      if (id != null) _sendResponse(id, {'variables': []});
      return;
    }
    
    List<Map<String, dynamic>> vars = [];
    
    if (ref == 1) {
      // Globals
      _vm!.globals.forEach((key, value) {
         vars.add({'name': key, 'value': value.toString(), 'variablesReference': 0});
      });
    } else if (ref >= 1000) {
      // Locals
      final frameIndex = ref - 1000;
      final locals = _debugger!.getLocals(frameIndex);
      locals.forEach((key, value) {
        final val = value as Map<String, dynamic>;
        vars.add({
          'name': key,
          'value': val['value'] ?? val['preview'] ?? 'null',
          'variablesReference': val['type'] == 'ref' ? (val['handle'] as int) : 0, 
        });
      });
    }
    
    if (id != null) {
      _sendResponse(id, {'variables': vars});
    }
  }
  
  void _evaluate(Map args, int? id) {
     final expr = args['expression'] as String;
     final frameId = args['frameId'] as int?;
     
     final result = _debugger?.evaluate(expr, frameIndex: frameId ?? 0);
     if (id != null) {
       _sendResponse(id, {'result': result.toString()});
     }
  }
  
  void _sendEvent(String type, [dynamic body]) {
    _sendPort.send({'type': 'event', 'event': type, 'body': body});
  }
  
  void _sendResponse(int id, dynamic body) {
    _sendPort.send({'type': 'response', 'id': id, 'body': body});
  }
}
