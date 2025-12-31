// Flux Debugger Module
//
// Provides debugging capabilities for Flux scripts including breakpoints,
// step execution, variable inspection, and profiling.

import 'vm.dart';

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
    // Hook into VM execution - in a real implementation, we would
    // intercept the VM's step function
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
    _stepMode = StepMode.stepOut;
    _stepTargetDepth = _getCurrentDepth() - 1;
    _stepSourceLine = -1; // Not needed for stepOut but for consistency
    _notifyListeners(DebugEvent.resumed, _createContext());
  }
  
  /// Get the current call stack
  List<StackFrame> getCallStack() {
    // In a real implementation, we would walk the VM's call frames
    // For now, return a placeholder
    return [];
  }
  
  /// Evaluate an expression in the current context
  Object? evaluate(String expression) {
    // In a real implementation, we would parse and evaluate the expression
    // in the current VM context
    return null;
  }
  
  /// Get local variables in the current frame
  Map<String, Object?> getLocals([int frameIndex = 0]) {
    // In a real implementation, we would return the locals from the specified frame
    return {};
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
  String toString() => '$name: $callCount calls, ${totalTime.inMilliseconds}ms total';
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
          ? (profile.totalTime.inMicroseconds / totalTime.inMicroseconds * 100).toStringAsFixed(1)
          : '0.0';
      buffer.writeln('  ${profile.name}');
      buffer.writeln('    Calls: ${profile.callCount}');
      buffer.writeln('    Total: ${profile.totalTime.inMilliseconds}ms ($percent%)');
      buffer.writeln('    Avg: ${profile.averageTime.inMicroseconds}µs');
    }
    
    return buffer.toString();
  }
  
  /// Convert to JSON for tooling
  Map<String, dynamic> toJson() => {
    'totalTimeMs': totalTime.inMilliseconds,
    'totalInstructions': totalInstructions,
    'functions': functionProfiles.map((p) => {
      'name': p.name,
      'callCount': p.callCount,
      'totalTimeUs': p.totalTime.inMicroseconds,
      'averageTimeUs': p.averageTime.inMicroseconds,
    }).toList(),
  };
}
