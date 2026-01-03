import 'dart:io';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';

/// A debug session for a single Flux program
class DapSession {
  final int id;
  final String programPath;
  
  VM? _vm;
  FluxDebugger? _debugger;
  String _source = '';
  
  DapSession(this.id, this.programPath);
  
  /// Launch the Flux program
  Future<void> launch() async {
    final file = File(programPath);
    if (!await file.exists()) {
      throw Exception('Program not found: $programPath');
    }
    
    _source = await file.readAsString();
    
    // Compile the source
    final compiler = Compiler();
    final chunk = compiler.compile(_source, programPath);
    
    // Create VM and debugger
    _vm = VM();
    _debugger = FluxDebugger(_vm!);
    _debugger!.attach();
    
    // Load the chunk
    _vm!.run(chunk);
  }
  
  /// Set breakpoints and return verification status
  List<bool> setBreakpoints(String source, List<int> lines) {
    if (_debugger == null) return lines.map((_) => false).toList();
    
    // Clear existing breakpoints for this source
    _debugger!.clearBreakpoints();
    
    // Set new breakpoints
    return lines.map((line) {
      try {
        _debugger!.setBreakpoint(source, line);
        return true;
      } catch (_) {
        return false;
      }
    }).toList();
  }
  
  /// Start execution
  void run() {
    _debugger?.continue_();
  }
  
  /// Continue execution
  void continue_() {
    _debugger?.continue_();
  }
  
  /// Step over
  void stepOver() {
    _debugger?.stepOver();
  }
  
  /// Step into
  void stepInto() {
    _debugger?.stepInto();
  }
  
  /// Step out
  void stepOut() {
    _debugger?.stepOut();
  }
  
  /// Get stack trace
  List<Map<String, dynamic>> getStackTrace() {
    if (_debugger == null) return [];
    
    final frames = _debugger!.getCallStack();
    return frames.asMap().entries.map((entry) {
      final frame = entry.value;
      return {
        'id': entry.key,
        'name': frame.functionName,
        'source': {'path': frame.source},
        'line': frame.line,
        'column': 0,
      };
    }).toList();
  }
  
  /// Get variables for a scope reference
  List<Map<String, dynamic>> getVariables(int reference) {
    if (_debugger == null) return [];
    
    if (reference == 1) {
      // Globals
      final globals = _vm?.globals ?? {};
      return globals.entries.map((e) => {
        'name': e.key,
        'value': _formatValue(e.value),
        'variablesReference': 0,
      }).toList();
    } else {
      // Locals for frame
      final frameIndex = reference - 1000;
      final locals = _debugger!.getLocals(frameIndex);
      return locals.entries.map((e) => {
        'name': e.key,
        'value': _formatValue(e.value),
        'variablesReference': 0,
      }).toList();
    }
  }
  
  /// Evaluate expression
  Future<Object?> evaluate(String expression, {int? frameId}) async {
    if (_debugger == null) return null;
    return _debugger!.evaluate(expression, frameIndex: frameId ?? 0);
  }
  
  /// Terminate session
  void terminate() {
    _debugger?.detach();
    _vm = null;
    _debugger = null;
  }
  
  String _formatValue(Object? value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    if (value is List) return 'List(${value.length})';
    if (value is Map) return 'Map(${value.length})';
    return value.toString();
  }
}
