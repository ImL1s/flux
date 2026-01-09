// Flux Debugger Module
//
// Provides debugging capabilities for Flux scripts including breakpoints,
// step execution, variable inspection, and profiling.

import 'vm.dart';
import 'closure.dart';
import 'package:flux_compiler/flux_compiler.dart';

/// Debugger event types
enum DebugEvent {
  /// Execution paused at a breakpoint
  breakpoint,

  /// Execution paused due to step command
  step,

  /// Execution paused due to error
  error,

  /// Execution resumed
  resumed,

  /// Execution completed
  completed,
}

/// A breakpoint in Flux code
class Breakpoint {
  /// Unique identifier for this breakpoint
  final int id;

  /// Source file or identifier
  final String source;

  /// Line number (1-indexed)
  final int line;

  /// Whether this breakpoint is enabled
  bool enabled;

  /// Optional condition expression
  final String? condition;

  /// Hit count
  int hitCount = 0;

  Breakpoint({
    required this.id,
    required this.source,
    required this.line,
    this.enabled = true,
    this.condition,
  });

  @override
  String toString() => 'Breakpoint($id @ $source:$line)';
}

/// Information about a stack frame
class StackFrame {
  /// Frame index (0 = current frame)
  final int index;

  /// Function name
  final String functionName;

  /// Source location
  final String source;

  /// Line number in source
  final int line;

  /// Local variables in this frame
  final Map<String, Object?> locals;

  StackFrame({
    required this.index,
    required this.functionName,
    required this.source,
    required this.line,
    required this.locals,
  });

  @override
  String toString() => '#$index $functionName ($source:$line)';
}

/// Debug listener callback
typedef DebugListener = void Function(DebugEvent event, DebugContext context);

/// Debug context provided with each debug event
class DebugContext {
  /// Current source location
  final String source;

  /// Current line number
  final int line;

  /// Stack frames
  final List<StackFrame> stackFrames;

  /// The breakpoint that was hit (if applicable)
  final Breakpoint? breakpoint;

  /// Error message (if event is error)
  final String? errorMessage;

  DebugContext({
    required this.source,
    required this.line,
    required this.stackFrames,
    this.breakpoint,
    this.errorMessage,
  });
}

/// Step execution mode
enum StepMode {
  /// Step to the next instruction
  stepInto,

  /// Step over function calls
  stepOver,

  /// Step out of the current function
  stepOut,

  /// Continue execution
  continue_,
}

/// Debugger for Flux VM
class FluxDebugger {
  final VM vm;

  /// All breakpoints
  final Map<int, Breakpoint> _breakpoints = {};
  int _nextBreakpointId = 1;

  /// Debug listeners
  final List<DebugListener> _listeners = [];

  /// Whether the debugger is attached
  bool _attached = false;

  /// Whether execution is currently paused
  bool _paused = false;

  /// Current step mode
  StepMode? _stepMode;

  /// Step target depth (for stepOver/stepOut)
  int? _stepTargetDepth;

  /// Current step mode
  StepMode? get stepMode => _stepMode;

  /// Target depth for stepping
  int? get stepTargetDepth => _stepTargetDepth;

  FluxDebugger(this.vm);

  /// Attach the debugger to the VM
  void attach() {
    if (_attached) return;
    _attached = true;
    vm.debugger = this;
  }

  /// Detach the debugger from the VM
  void detach() {
    _attached = false;
    _paused = false;
    _stepMode = null;
    _stepTargetDepth = null;
  }

  /// Add a debug listener
  void addListener(DebugListener listener) {
    _listeners.add(listener);
  }

  /// Remove a debug listener
  void removeListener(DebugListener listener) {
    _listeners.remove(listener);
  }

  /// Set a breakpoint
  Breakpoint setBreakpoint(String source, int line, {String? condition}) {
    final bp = Breakpoint(
      id: _nextBreakpointId++,
      source: source,
      line: line,
      condition: condition,
    );
    _breakpoints[bp.id] = bp;
    return bp;
  }

  /// Remove a breakpoint by ID
  bool removeBreakpoint(int id) {
    return _breakpoints.remove(id) != null;
  }

  /// Remove a breakpoint by source and line
  bool removeBreakpointAt(String source, int line) {
    int? toRemove;
    for (final bp in _breakpoints.values) {
      if (bp.source == source && bp.line == line) {
        toRemove = bp.id;
        break;
      }
    }
    if (toRemove != null) {
      _breakpoints.remove(toRemove);
      return true;
    }
    return false;
  }

  /// Get all breakpoints
  List<Breakpoint> get breakpoints => _breakpoints.values.toList();

  /// Get a breakpoint by ID
  Breakpoint? getBreakpoint(int id) => _breakpoints[id];

  /// Enable or disable a breakpoint
  void setBreakpointEnabled(int id, bool enabled) {
    _breakpoints[id]?.enabled = enabled;
  }

  /// Clear all breakpoints
  void clearBreakpoints() {
    _breakpoints.clear();
  }

  /// Check if we're paused
  bool get isPaused => _paused;

  /// Check if a breakpoint should hit at the given location
  Breakpoint? shouldBreakAt(String source, int line) {
    if (!_attached) return null;

    for (final bp in _breakpoints.values) {
      if (bp.enabled && bp.source == source && bp.line == line) {
        bp.hitCount++;
        return bp;
      }
    }
    return null;
  }

  /// Pause execution
  void pause() {
    _paused = true;
    _notifyListeners(DebugEvent.breakpoint, _createContext());
  }

  /// Resume execution
  void continue_() {
    if (!_paused) return;
    _paused = false;
    _clearRegistry();
    _stepMode = null;
    _stepTargetDepth = null;
    _notifyListeners(DebugEvent.resumed, _createContext());
  }

  /// Current step source line
  int? _stepSourceLine;
  int? get stepSourceLine => _stepSourceLine;

  /// Step into the next instruction or function
  void stepInto() {
    if (!_paused) return;
    _paused = false;
    _clearRegistry();
    _stepMode = StepMode.stepInto;
    _stepTargetDepth = _getCurrentDepth();
    final frame = vm.frames.last;
    _stepSourceLine = frame.chunk.getLine(frame.ip);
    _notifyListeners(DebugEvent.resumed, _createContext());
  }

  /// Step over the current line
  void stepOver() {
    if (!_paused) return;
    _paused = false;
    _clearRegistry();
    _stepMode = StepMode.stepOver;
    _stepTargetDepth = _getCurrentDepth();
    final frame = vm.frames.last;
    _stepSourceLine = frame.chunk.getLine(frame.ip);
    _notifyListeners(DebugEvent.resumed, _createContext());
  }

  /// Step out of the current function
  void stepOut() {
    if (!_paused) return;
    _paused = false;
    _clearRegistry();
    _stepMode = StepMode.stepOut;
    _stepTargetDepth = _getCurrentDepth() - 1;
    _stepSourceLine = -1; // Not needed for stepOut but for consistency
    _notifyListeners(DebugEvent.resumed, _createContext());
  }

  /// Evaluate an expression in the context of a specific stack frame
  ///
  /// [expression] is the source code to evaluate.
  /// [frameIndex] is the index of the frame (0 = top/current frame).
  /// Evaluate an expression in the context of a specific stack frame
  ///
  /// [expression] is the source code to evaluate.
  /// [frameIndex] is the index of the frame (0 = top/current frame).
  Object? evaluate(String expression, {int frameIndex = 0}) {
    if (vm.frames.isEmpty) return "Error: VM is not running";
    if (frameIndex >= vm.frames.length) return "Error: Invalid frame index";

    // Get frame from top (index 0 is top)
    final frame = vm.frames[vm.frames.length - 1 - frameIndex];
    final function = frame.closure.function;
    final localNames = function.localNames;

    // Collect all local values from the stack corresponding to localNames
    final values = <Object?>[];
    // Only pass localNames that are actually available on stack
    final availableNames = <String>[];

    for (int i = 0; i < localNames.length; i++) {
      final stackIndex = frame.slotBase + i;
      if (stackIndex < vm.stack.length) {
        values.add(vm.stack[stackIndex]);
        availableNames.add(localNames[i]);
      } else {
        // Stop if we reach end of stack (future locals not yet initialized)
        break;
      }
    }

    try {
      // Compile expression knowing only the AVAILABLE local variable names
      final compiledFn = compileFluxExpression(expression, availableNames);

      // Execute in a separate context
      // We must temporarily unpause the debugger to allow the evaluation to run
      // otherwise the VM will immediately return InterpretResult.paused
      final wasPaused = _paused;
      _paused = false;
      try {
        return vm.executeFunctionInContext(compiledFn, values);
      } finally {
        _paused = wasPaused;
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  /// Get the current call stack
  List<StackFrame> getCallStack() {
    final frames = <StackFrame>[];
    final vmFrames = vm.frames;

    for (int i = vmFrames.length - 1; i >= 0; i--) {
      final frame = vmFrames[i];
      final function = frame.closure.function;
      final line = frame.chunk.getLine(frame.ip);

      frames.add(StackFrame(
        index: vmFrames.length - 1 - i,
        functionName: function.name.isEmpty ? '<script>' : function.name,
        source: function.moduleName ?? '<unknown>',
        line: line,
        locals: _getLocalsForFrame(i),
      ));
    }

    return frames;
  }

  /// Get local variables in the current frame
  Map<String, Object?> getLocals([int frameIndex = 0]) {
    final vmFrames = vm.frames;
    if (vmFrames.isEmpty) return {};

    // Convert frameIndex (0 = top) to actual index in vmFrames (highest = top)
    final actualIndex = vmFrames.length - 1 - frameIndex;
    if (actualIndex < 0 || actualIndex >= vmFrames.length) return {};

    return _getLocalsForFrame(actualIndex);
  }

  /// Internal helper to get locals for a frame by its actual index in vmFrames
  Map<String, Object?> _getLocalsForFrame(int actualFrameIndex) {
    final vmFrames = vm.frames;
    if (actualFrameIndex < 0 || actualFrameIndex >= vmFrames.length) return {};

    final frame = vmFrames[actualFrameIndex];
    final function = frame.closure.function;
    final localNames = function.localNames;
    final stack = vm.stack;

    final locals = <String, Object?>{};

    // Map each local name to its stack value
    for (int i = 0; i < localNames.length; i++) {
      final name = localNames[i];
      if (name.isEmpty) continue; // Skip slot 0 (closure placeholder)

      final stackIndex = frame.slotBase + i;
      if (stackIndex < stack.length) {
        locals[name] = _serializeValue(stack[stackIndex]);
      }
      // Implicitly skip if out of bounds (future locals)
    }

    // Also include globals for top-level visibility
    if (actualFrameIndex == 0) {
      for (final entry in vm.globals.entries) {
        if (!locals.containsKey(entry.key)) {
          locals[entry.key] = _serializeValue(entry.value);
        }
      }
    }

    return locals;
  }

  /// Get the value of a specific variable
  Object? getVariable(String name, [int frameIndex = 0]) {
    return getLocals(frameIndex)[name];
  }

  int _getCurrentDepth() {
    return vm.frames.length;
  }

  DebugContext _createContext() {
    if (vm.frames.isEmpty) {
      return DebugContext(source: '', line: 0, stackFrames: []);
    }
    final frame = vm.frames.last;
    final line = frame.chunk.getLine(frame.ip);
    return DebugContext(
      source: frame.closure.function.moduleName ?? '',
      line: line,
      stackFrames: getCallStack(),
    );
  }

  /// Object registry for deep inspection (valid only while paused)
  final Map<int, Object> _objectRegistry = {};
  int _nextHandleId = 1;

  void _clearRegistry() {
    _objectRegistry.clear();
    _nextHandleId = 1;
  }

  int _registerObject(Object obj) {
    final handle = _nextHandleId++;
    _objectRegistry[handle] = obj;
    return handle;
  }

  /// Get object details by handle
  Map<String, dynamic>? getObject(int handle) {
    if (!_objectRegistry.containsKey(handle)) return null;
    final obj = _objectRegistry[handle];

    if (obj is List) {
      final elements = <Map<String, dynamic>>[];
      for (var i = 0; i < obj.length; i++) {
        elements.add({
          'index': i,
          'value': _serializeValue(obj[i]),
        });
      }
      return {
        'kind': 'List',
        'length': obj.length,
        'elements': elements,
      };
    } else if (obj is Map) {
      final entries = <Map<String, dynamic>>[];
      for (final entry in obj.entries) {
        entries.add({
          'key': _serializeValue(entry.key),
          'value': _serializeValue(entry.value),
        });
      }
      return {
        'kind': 'Map',
        'length': obj.length,
        'entries': entries,
      };
    } else if (obj is FluxInstance) {
      final fields = <String, Map<String, dynamic>>{};
      obj.fields.forEach((key, value) {
        fields[key] = _serializeValue(value);
      });
      return {
        'kind': 'Instance',
        'class': obj.klass.name,
        'fields': fields,
      };
    } else if (obj is ObjClosure) {
      return {
        'kind': 'Closure',
        'name': obj.function.name,
        'arity': obj.function.arity,
      };
    }

    return {
      'kind': 'Unknown',
      'value': obj.toString(),
    };
  }

  /// Get deep value by handle (alias for getObject)
  ///
  /// This is the public API for deep object inspection.
  /// Returns detailed structure of complex objects like Lists, Maps, and Instances.
  Map<String, dynamic>? getValue(int handle) => getObject(handle);

  Map<String, dynamic> _serializeValue(Object? value) {
    if (value == null) {
      return {'type': 'primitive', 'kind': 'Null', 'value': 'null'};
    }
    if (value is bool || value is num || value is String) {
      return {
        'type': 'primitive',
        'kind': value.runtimeType.toString(),
        'value': value.toString()
      };
    }

    // Complex object
    final handle = _registerObject(value);
    String preview;
    if (value is List) {
      preview = 'List(${value.length})';
    } else if (value is Map) {
      preview = 'Map(${value.length})';
    } else if (value is FluxInstance) {
      preview = value.klass.name;
    } else if (value is ObjClosure) {
      preview = 'Closure(${value.function.name})';
    } else {
      preview = value.runtimeType.toString();
    }

    return {
      'type': 'ref',
      'kind': value.runtimeType.toString(),
      'handle': handle,
      'preview': preview,
    };
  }

  void _notifyListeners(DebugEvent event, DebugContext context) {
    for (final listener in _listeners) {
      listener(event, context);
    }
  }
}

/// Profiler for Flux VM
class FluxProfiler {
  final Map<String, FunctionProfile> _profiles = {};
  bool _enabled = false;
  DateTime? _startTime;
  DateTime? _endTime;
  int _totalInstructions = 0;

  /// Start profiling
  void start() {
    _enabled = true;
    _startTime = DateTime.now();
    _profiles.clear();
    _totalInstructions = 0;
  }

  /// Stop profiling
  void stop() {
    _enabled = false;
    _endTime = DateTime.now();
  }

  /// Record a function call
  void recordFunctionEntry(String name) {
    if (!_enabled) return;

    _profiles.putIfAbsent(name, () => FunctionProfile(name));
    _profiles[name]!.callCount++;
    _profiles[name]!._entryTime = DateTime.now();
  }

  /// Record a function return
  void recordFunctionExit(String name) {
    if (!_enabled) return;

    final profile = _profiles[name];
    if (profile != null && profile._entryTime != null) {
      final duration = DateTime.now().difference(profile._entryTime!);
      profile.totalTime += duration;
      profile._entryTime = null;
    }
  }

  /// Record an instruction execution
  void recordInstruction() {
    if (!_enabled) return;
    _totalInstructions++;
  }

  /// Get all function profiles
  List<FunctionProfile> getProfiles() {
    final list = _profiles.values.toList();
    list.sort((a, b) => b.totalTime.compareTo(a.totalTime));
    return list;
  }

  /// Get the total execution time
  Duration get totalExecutionTime {
    if (_startTime == null) return Duration.zero;
    final end = _endTime ?? DateTime.now();
    return end.difference(_startTime!);
  }

  /// Get total instructions executed
  int get totalInstructions => _totalInstructions;

  /// Generate a profiling report
  ProfileReport generateReport() {
    return ProfileReport(
      totalTime: totalExecutionTime,
      totalInstructions: _totalInstructions,
      functionProfiles: getProfiles(),
    );
  }
}

/// Profile data for a single function
class FunctionProfile {
  final String name;
  int callCount = 0;
  Duration totalTime = Duration.zero;
  DateTime? _entryTime;

  FunctionProfile(this.name);

  /// Average time per call
  Duration get averageTime {
    if (callCount == 0) return Duration.zero;
    return Duration(microseconds: totalTime.inMicroseconds ~/ callCount);
  }

  @override
  String toString() =>
      '$name: $callCount calls, ${totalTime.inMilliseconds}ms total';
}

/// Profiling report
class ProfileReport {
  final Duration totalTime;
  final int totalInstructions;
  final List<FunctionProfile> functionProfiles;

  ProfileReport({
    required this.totalTime,
    required this.totalInstructions,
    required this.functionProfiles,
  });

  /// Generate a human-readable report
  String toReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Flux Profiler Report ===');
    buffer.writeln('Total Time: ${totalTime.inMilliseconds}ms');
    buffer.writeln('Total Instructions: $totalInstructions');
    buffer.writeln();
    buffer.writeln('Top Functions:');

    for (final profile in functionProfiles.take(10)) {
      final percent = totalTime.inMicroseconds > 0
          ? (profile.totalTime.inMicroseconds / totalTime.inMicroseconds * 100)
              .toStringAsFixed(1)
          : '0.0';
      buffer.writeln('  ${profile.name}');
      buffer.writeln('    Calls: ${profile.callCount}');
      buffer.writeln(
          '    Total: ${profile.totalTime.inMilliseconds}ms ($percent%)');
      buffer.writeln('    Avg: ${profile.averageTime.inMicroseconds}µs');
    }

    return buffer.toString();
  }

  /// Convert to JSON for tooling
  Map<String, dynamic> toJson() => {
        'totalTimeMs': totalTime.inMilliseconds,
        'totalInstructions': totalInstructions,
        'functions': functionProfiles
            .map((p) => {
                  'name': p.name,
                  'callCount': p.callCount,
                  'totalTimeUs': p.totalTime.inMicroseconds,
                  'averageTimeUs': p.averageTime.inMicroseconds,
                })
            .toList(),
      };
}
