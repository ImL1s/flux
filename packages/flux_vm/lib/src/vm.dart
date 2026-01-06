/// Flux Language - Virtual Machine
/// 
/// Executes Flux bytecode using a stack-based architecture.
/// Based on Crafting Interpreters bytecode VM pattern.

import 'package:flux_compiler/flux_compiler.dart';
import 'stdlib.dart';
import 'closure.dart';
import 'coroutine.dart';
import 'debugger.dart';
import 'inline_cache.dart';
import 'persistence_delegate.dart';

typedef WidgetCallHandler = Object? Function(Object? callee, int argCount, Map<String, dynamic> namedArgs, List<Object?> stack);

enum InterpretResult {
  ok,
  compileError,
  runtimeError,
  awaiting,  // VM is suspended waiting for a Future
  paused,    // VM is suspended by debugger
}

// CallFrame is now defined in coroutine.dart

/// Maximum number of call frames (call depth)
const int framesMax = 64;

/// Maximum stack size
const int stackMax = framesMax * 256;

/// Exception handler for try/catch/finally
class _ExceptionHandler {
  final int frameIndex;    // CallFrame index when handler was registered
  final int stackHeight;   // Stack height when handler was registered
  final int catchOffset;   // IP offset to catch block
  final int finallyOffset; // IP offset to finally block
  
  _ExceptionHandler({
    required this.frameIndex,
    required this.stackHeight,
    required this.catchOffset,
    required this.finallyOffset,
  });
}

/// Represents a class instance at runtime
class FluxInstance {
  final CompiledClass klass;
  final Map<String, Object?> fields = {};
  
  FluxInstance(this.klass);
  
  Object? getProperty(String name) {
    // Check instance fields first
    if (fields.containsKey(name)) {
      return fields[name];
    }
    // Then check for methods
    if (klass.methods.containsKey(name)) {
      return klass.methods[name];
    }
    throw 'Undefined property: ${klass.name}.$name';
  }
  
  void setProperty(String name, Object? value) {
    fields[name] = value;
  }
  
  @override
  String toString() => '<${klass.name} instance>';
}

class VM {
  final Map<String, Object?> _globals = {};
  
  /// Widget state storage (keyed by state field name)
  /// Shared across all coroutines for the current widget instance
  final Map<String, Object?> _widgetState = {};
  
  List<Object?> get _stack => (_pausedCoroutine ?? _currentCoroutine)!.stack;
  List<CallFrame> get _frames => (_pausedCoroutine ?? _currentCoroutine)!.frames;
  
  /// Get current execution stack
  List<Object?> get stack => _stack;
  
  /// Get current call frames
  List<CallFrame> get frames => _frames;
  
  /// Linked list of open upvalues (for closure support)
  ObjUpvalue? _openUpvalues;
  
  /// Callback triggered when setState is called (for Flutter rebuild)
  void Function(String name, Object? value)? onStateChange;
  
  /// Optional widget call handler for FluxRuntime
  WidgetCallHandler? widgetCallHandler;
  
  // Async/await state
  bool _awaitingFuture = false;
  Future<dynamic>? _pendingFuture;
  CallFrame? _pendingFrame;
  
  // Runtime Optimizations
  final InlineCacheManager _inlineCacheManager = InlineCacheManager();
  
  /// Get current inline cache stats for debugging
  Map<String, dynamic> get cacheStats => _inlineCacheManager.getStats();
  
  // Exception handling state
  final List<_ExceptionHandler> _exceptionHandlers = [];
  
  // Coroutine support
  FluxCoroutine? _currentCoroutine;
  FluxCoroutine? _pausedCoroutine; // Saved paused coroutine for debugger
  
  CoroutineResumeCallback? coroutineResumeCallback;
  
  // Debugger and Profiler
  FluxDebugger? debugger;
  FluxProfiler? profiler;
  
  // Module import tracking
  final List<String> _imports = [];
  
  /// Get list of imports encountered during execution
  List<String> get imports => List.unmodifiable(_imports);
  
  /// Callback triggered after a hot swap is applied
  void Function(String scriptName)? onHotSwap;

  /// Delegate for persisting state across app restarts
  PersistenceDelegate? persistenceDelegate;

  /// Current widget name (for persistence keys)
  String? _currentWidgetName;
  
  /// Loaded scripts registry (for hot-swap)
  final Map<String, CompiledFunction> _scripts = {};
  
  /// Register a compiled script for potential hot-swap
  void registerScript(String name, CompiledFunction function) {
    _scripts[name] = function;
  }
  
  /// Register a custom module with the VM (e.g., http, storage)
  void registerModule(FluxModule module) {
    _globals[module.name] = module;
  }
  
  /// Hot-swap a script with a new compiled function
  /// 
  /// Replaces the script's bytecode while preserving:
  /// - Widget state (_widgetState)
  /// - Global variables (_globals)
  /// 
  /// Triggers onHotSwap callback on success.
  void hotSwap(String scriptName, CompiledFunction newFunction) {
    _scripts[scriptName] = newFunction;
    
    // Notify listeners (e.g., FluxWidget to rebuild)
    onHotSwap?.call(scriptName);
  }
  
  /// Get a registered script by name
  CompiledFunction? getScript(String name) => _scripts[name];
  
  // Runtime flags
  final bool enableInlineCaching;

  /// Constructor - initializes standard library
  VM({this.enableInlineCaching = true}) {
    _currentCoroutine = FluxCoroutine('root');
    _initStdlib();
  }
  
  /// Initialize standard library functions
  void _initStdlib() {
    StdLib.init();
    // Register functions as globals
    for (final entry in StdLib.functions.entries) {
      _globals[entry.key] = entry.value;
    }
    // Register modules as globals (json, timer, etc.)
    for (final entry in StdLib.modules.entries) {
      _globals[entry.key] = entry.value;
    }

    // Register built-in print that uses onPrint
    _globals['print'] = NativeFunction('print', 1, (args) {
      onPrint(args[0].toString());
      return null;
    });
  }
  
  /// Get the pending Future (for external await handling)
  Future<dynamic>? get pendingFuture => _pendingFuture;
  
  /// Resume execution after an awaited Future completes
  InterpretResult resumeFromAwait(Object? result) {
    if (!_awaitingFuture || _pendingFrame == null) {
      return InterpretResult.runtimeError;
    }
    
    // Push the result onto the stack
    _stack.add(result);
    
    // Clear awaiting state
    _awaitingFuture = false;
    _pendingFuture = null;
    _pendingFrame = null;
    
    // Continue execution
    return _run();
  }
  
  /// Suspend current execution and create a coroutine snapshot
  /// 
  /// Called when await encounters a pending Future.
  /// Captures all execution state needed to resume later.
  /// Suspend current execution
  /// 
  /// Simply marks the current coroutine as suspended.
  FluxCoroutine suspendToCoroutine() {
    final coroutine = _currentCoroutine!;
    
    coroutine.state = CoroutineState.suspended;
    coroutine.suspendedAt = DateTime.now();
    
    return coroutine;
  }
  
  /// Resume a suspended coroutine with the await result
  /// 
  /// Called when the awaited Future completes.
  /// Resume a suspended coroutine with the await result
  /// 
  /// Called when the awaited Future completes.
  InterpretResult resumeCoroutine(FluxCoroutine coroutine, Object? result) {
    if (coroutine.state != CoroutineState.suspended) {
      _runtimeError('Cannot resume coroutine in state: ${coroutine.state}');
      return InterpretResult.runtimeError;
    }
    
    // Context Switch: Set the current coroutine
    _currentCoroutine = coroutine;
    
    // Push the await result onto the coroutine's stack
    _stack.add(result);
    
    // Update coroutine state
    coroutine.state = CoroutineState.running;
    
    // Continue execution
    final interpretResult = _run();
    
    // Mark coroutine as completed
    if (interpretResult == InterpretResult.ok) {
      coroutine.state = CoroutineState.completed;
    } else if (interpretResult == InterpretResult.runtimeError) {
      coroutine.state = CoroutineState.error;
    }
    
    return interpretResult;
  }
  
  /// Resume a suspended coroutine with an error
  /// Resume a suspended coroutine with an error
  InterpretResult resumeCoroutineWithError(FluxCoroutine coroutine, Object error) {
    if (coroutine.state != CoroutineState.suspended) {
      _runtimeError('Cannot resume coroutine in state: ${coroutine.state}');
      return InterpretResult.runtimeError;
    }
    
    _currentCoroutine = coroutine;
    coroutine.awaitError = error;
    coroutine.state = CoroutineState.running; // Set to running to handle exception
    
    // Try to handle exception
    if (_handleException(error)) {
      final res = _run();
      if (res == InterpretResult.runtimeError) {
         coroutine.state = CoroutineState.error;
      } else {
         coroutine.state = CoroutineState.completed;
      }
      return res;
    }
    
    coroutine.state = CoroutineState.error;
    _runtimeError('Unhandled async error: $error');
    return InterpretResult.runtimeError;
  }
  

  
  /// Basic output handler
  void Function(String message) onPrint = print;
  
  /// Access to global variables (for FluxRuntime integration)
  Map<String, Object?> get globals => _globals;
  
  /// Access to widget state for FluxRuntime
  Map<String, Object?> get widgetState => _widgetState;
  
  /// Initialize widget state from CompiledWidget
  dynamic initializeState(CompiledWidget widget) {
    _currentWidgetName = widget.name;
    _persistentFields.clear();
    _persistentFields.addAll(widget.persistentFields);
    
    final futures = <Future<void>>[];
    for (int i = 0; i < widget.stateFields.length; i++) {
      final name = widget.stateFields[i];
      final initializer = widget.stateInitializers[i];
      
      bool isPersistent = _persistentFields.contains(name);

      if (isPersistent && persistenceDelegate != null) {
        final key = "flux_state_${widget.name}_$name";
        final future = persistenceDelegate!.load(key);
        if (future is Future<dynamic>) {
          futures.add(future.then((persistedValue) {
            if (persistedValue != null) {
              _widgetState[name] = persistedValue;
            } else {
              // Fallback to initializer if load returns null
              runChunk(initializer.chunk);
              _widgetState[name] = _stack.isNotEmpty ? _stack.removeLast() : null;
            }
          }));
          continue;
        } else {
          // Synchronous load (e.g. from in-memory delegate)
          final persistedValue = future;
          if (persistedValue != null) {
            _widgetState[name] = persistedValue;
            continue;
          }
        }
      }

      // Execute initializer to get initial value
      runChunk(initializer.chunk);
      _widgetState[name] = _stack.isNotEmpty ? _stack.removeLast() : null;
    }
    
    if (futures.isEmpty) return null;
    return Future.wait(futures);
  }
  
  /// Clear state (for new widget instance)
  void clearState() {
    _widgetState.clear();
  }

  /// Interpret source code
  InterpretResult interpret(String source) {
    try {
      final lexer = Lexer(source);
      _globals['push'] = NativeFunction('push', 2, (args) {
      final list = args[0] as List;
      final value = args[1];
      list.add(value);
      print('DEBUG STDLIB: push added $value, list is now $list');
      return list.length;
    });
      final tokens = lexer.tokenize();

      final parser = Parser(tokens);
      final ast = parser.parse();

      if (parser.errors.isNotEmpty) {
        for (final error in parser.errors) {
          _runtimeError(error.toString());
        }
        return InterpretResult.compileError;
      }

      final compiler = Compiler(unit: ast);
      final function = compiler.endCompiler();

      return runChunk(function.chunk);
    } catch (e) {
      _runtimeError(e.toString());
      return InterpretResult.runtimeError;
    }
  }

  /// Run a pre-compiled chunk directly
  InterpretResult runChunk(Chunk chunk) {
    // If we are already running, don't clear the stack!
    // This happens during nested widget construction or state initialization.
    if (_frames.isNotEmpty) {
      final function = CompiledFunction("script", chunk);
      final closure = ObjClosure(function, []);
      return executeClosure(closure);
    }

    // Wrap chunk in a CompiledFunction then a Closure
    final function = CompiledFunction("script", chunk);
    final closure = ObjClosure(function, []);

    // Reset VM state
    _stack.clear();
    _frames.clear();
    _openUpvalues = null; // Clear open upvalues

    // Push the script closure to stack
    _stack.add(closure);

    _callFunction(closure, 0);

    return _run();
  }

  /// Execute a closure with arguments.
  /// Used by FluxRuntime to execute widget builder closures.
  InterpretResult executeClosure(ObjClosure closure, [List<Object?> args = const []]) {
    final coroutine = FluxCoroutine(FluxCoroutine.generateId());
    final prevCoroutine = _currentCoroutine;
    _currentCoroutine = coroutine;
    
    _stack.add(closure);
    for (final arg in args) {
      _stack.add(arg);
    }

    if (!_callValue(closure, args.length)) {
      _currentCoroutine = prevCoroutine;
      return InterpretResult.runtimeError;
    }

    final result = _run();
    
    if (result == InterpretResult.ok) {
      final returnValue = coroutine.stack.isNotEmpty ? coroutine.stack.last : null;
      _currentCoroutine = prevCoroutine;
      _stack.add(returnValue);
    } else if (result == InterpretResult.paused) {
      _pausedCoroutine = coroutine;
      _currentCoroutine = prevCoroutine;
    } else {
      _currentCoroutine = prevCoroutine;
    }
    
    return result;
  }

  InterpretResult resume() {
    if (_pausedCoroutine != null) {
      final prev = _currentCoroutine;
      _currentCoroutine = _pausedCoroutine;
      _pausedCoroutine = null;
      
      if (debugger != null && debugger!.isPaused) {
        debugger!.continue_();
      }
      
      final result = _run();
      
      if (result == InterpretResult.paused) {
        _pausedCoroutine = _currentCoroutine; // Paused again
      }
      
      _currentCoroutine = prev;
      return result;
    }
    return _run();
  }



  /// Execute a closure synchronously on the current stack/coroutine.
  /// Used for callbacks that must happen within the same execution context (e.g. nested widget builds).
  InterpretResult invokeClosure(ObjClosure closure, [List<Object?> args = const []]) {
     if (_currentCoroutine == null) {
       // Fallback to executeClosure if no active coroutine
       return executeClosure(closure, args);
     }

     _stack.add(closure);
     for (final arg in args) {
       _stack.add(arg);
     }
     
     if (!_callValue(closure, args.length)) {
       return InterpretResult.runtimeError;
     }

     // Run until we return to the current frame depth (minus the one we just pushed)
     // _callFunction added a frame, so we want to return when that frame is popped.
     // current frames.length is N (including new frame).
     // We want to run until depth is N-1.
     return _run(_frames.length - 1);
  }

  /// Execute a compiled function/expression in a specific context (isolated)
  /// 
  /// Used for debugger expression evaluation.
  /// Does not affect the current execution state (stack/frames are saved and restored).
  Object? executeFunctionInContext(CompiledFunction function, List<Object?> locals) {
     final closure = ObjClosure(function, []);
     
     // 1. Back up current execution state
     final savedFrames = List<CallFrame>.from(_frames);
     final savedStack = List<Object?>.from(_stack);
     final savedUpvalues = _openUpvalues; 
     
     // 2. Clear state for isolated execution
     _frames.clear();
     _stack.clear();
     _openUpvalues = null;
     
     try {
       // 3. Setup stack with "locals"
       // Slot 0 is the closure itself
       _stack.add(closure); 
       
       // Slots 1..N are the provided locals
       _stack.addAll(locals);
       
       // 4. Create frame manually
       // Slot 0 is at index 0.
       final frame = CallFrame(
         closure,
         slotBase: 0, 
       );
       
       _frames.add(frame);
       
       // 5. Run until frames empty
       final result = _run(0); 
       
       if (result == InterpretResult.ok) {
         // Result is on stack
         if (_stack.isNotEmpty) {
           return _stack.last;
         }
         return null;
       } else {
         // Error occurred
         return "Error: Execution failed with $result"; 
       }
     } catch (e) {
       return "Error: $e";
     } finally {
       // 6. Restore state
       _frames.clear();
       _frames.addAll(savedFrames);
       
       _stack.clear();
       _stack.addAll(savedStack);
       
       _openUpvalues = savedUpvalues; 
     }
  }

  /// Capture an upvalue for the given stack slot
  ObjUpvalue _captureUpvalue(int localIndex) {
    ObjUpvalue? prevUpvalue;
    var upvalue = _openUpvalues;

    // Walk the list to find insertion point or existing upvalue
    while (upvalue != null && upvalue.location > localIndex) {
      prevUpvalue = upvalue;
      upvalue = upvalue.next;
    }

    // Found existing upvalue for this local
    if (upvalue != null && upvalue.location == localIndex) {
      return upvalue;
    }

    // Create new upvalue
    final createdUpvalue = ObjUpvalue(localIndex);
    createdUpvalue.next = upvalue;

    if (prevUpvalue == null) {
      _openUpvalues = createdUpvalue;
    } else {
      prevUpvalue.next = createdUpvalue;
    }

    return createdUpvalue;
  }

  /// Close all upvalues that point to stack slots >= last
  void _closeUpvalues(int last) {
    while (_openUpvalues != null && _openUpvalues!.location >= last) {
      final upvalue = _openUpvalues!;
      // print('DEBUG VM: Closing upvalue at ${upvalue.location} (stack len: ${_stack.length})');
      if (upvalue.location >= _stack.length) {
          // Dangling upvalue (stack popped?) - close with null to avoid crash
          upvalue.closed = null;
          upvalue.location = -1;
      } else {
          upvalue.close(_stack);
      }
      _openUpvalues = upvalue.next;
    }
  }

  bool _isTruthy(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    return true;
  }
  
  void _runtimeError(String message) {
    onPrint("Runtime Error: $message");
    
    for (int i = _frames.length - 1; i >= 0; i--) {
      final frame = _frames[i];
      final function = frame.closure.function;
      final instruction = frame.ip > 0 ? frame.ip - 1 : 0;
      final line = frame.chunk.getLine(instruction);
      onPrint("   at ${function.name}() [line $line]");
    }
    
    // Reset stack on fatal error
    _stack.clear();
  }

  bool _callValue(Object? callee, int argCount, [Map<String, dynamic> namedArgs = const {}]) {
    // Check if external handler wants to intercept this call
    if (widgetCallHandler != null) {
      final result = widgetCallHandler!(callee, argCount, namedArgs, _stack);
      if (result != null) {
        // Handler has already managed the stack (popped args/callee, pushed result)
        // We just return success
        return true;
      }
    }

    if (callee is ObjClosure) {
      if (profiler != null) profiler!.recordFunctionEntry(callee.function.name);
      final result = _callFunction(callee, argCount, namedArgs);
      if (profiler != null) profiler!.recordFunctionExit(callee.function.name);
      return result;
    }

    // Support calling raw CompiledFunctions by wrapping them (e.g. from tests or old code)
    if (callee is CompiledFunction) {
      final closure = ObjClosure(callee, []);
      // The named arguments were already popped from the stack in OpCode.callNamed
      // so totalArgSlots here only refers to positional arguments still on stack.
      final totalArgSlotsOnStack = argCount;
      _stack[_stack.length - totalArgSlotsOnStack - 1] = closure;
      return _callFunction(closure, argCount, namedArgs);
    }

    if (callee is NativeFunction) {
      final args = _stack.sublist(_stack.length - argCount);
      // Again, named args were already popped, so we just pop positional and the function
      _stack.length -= argCount + 1;
      try {
        final result = callee.call(args);
        // print('DEBUG RUNTIME: NativeFunction ${callee.name} returned $result');
        _stack.add(result);
        return true;
      } catch (e) {
        _runtimeError(e.toString());
        return false;
      }
    }
    
    // Handle async native functions (like timer.delay)
    if (callee is AsyncNativeFunction) {
      final args = _stack.sublist(_stack.length - argCount);
      _stack.length -= argCount + 1;
      
      // Create Future and push it to stack (will be awaited by OpCode.await_)
      final future = callee.call(args);
      _stack.add(future);
      return true;
    }

    if (callee is CompiledClass) {
      // 1. Create the instance
      final instance = FluxInstance(callee);
      
      // 2. Check for 'init' method
      final initMethod = callee.methods['init'];
      if (initMethod != null) {
        // Replace callee with instance on stack
        _stack[_stack.length - argCount - 1] = instance;
        // Call init method
        return _callFunction(ObjClosure(initMethod, []), argCount, namedArgs);
      } else {
        // No init method, just pop args and push instance
        _stack.length -= argCount + 1;
        _stack.add(instance);
        return true;
      }
    }

    if (callee is CompiledWidget) {
      // Widget instantiation - for now just put the widget on stack
      // Pop arguments and the callee itself, then push the widget instance (currently just the declaration)
      _stack.length -= argCount + 1;
      _stack.add(callee);
      return true;
    }

    _runtimeError("Can only call functions, classes, and widgets.");
    return false;
  }

  bool _callFunction(ObjClosure closure, int argCount, [Map<String, dynamic> namedArgs = const {}]) {
    final totalProvided = argCount + namedArgs.length;
    // print('DEBUG RUNTIME: _callFunction: ${closure.function.name}, arity: ${closure.function.arity}, totalProvided: $totalProvided (pos: $argCount, named: ${namedArgs.length})');
    if (totalProvided != closure.function.arity) {
      _runtimeError("Expected ${closure.function.arity} arguments but got $totalProvided. (Closure: ${closure.function.name})");
      return false;
    }

    if (_frames.length == framesMax) {
      _runtimeError("Stack overflow.");
      return false;
    }

    // If we have named arguments, we need to push them onto the stack in the correct slots
    // matching the parameter names.
    if (namedArgs.isNotEmpty) {
      // Positional arguments are already on the stack.
      // We fill the remaining slots with named arguments.
      for (int i = argCount; i < closure.function.arity; i++) {
        final paramName = closure.function.paramNames[i];
        if (namedArgs.containsKey(paramName)) {
          _stack.add(namedArgs[paramName]);
        } else {
          _runtimeError("Missing required argument: $paramName");
          return false;
        }
      }
    }

    final frame = CallFrame(
      closure,
      slotBase: _stack.length - closure.function.arity - 1,
    );
    _frames.add(frame);
    return true;
  }



  InterpretResult _run([int minDepth = 0]) {
    bool firstInstruction = true;
    try {
      while (true) {
        if (_frames.length <= minDepth) {
          return InterpretResult.ok;
        }
        CallFrame frame = _frames.last;

        // Debugger hooks
        if (debugger != null) {
          if (debugger!.isPaused) {
            return InterpretResult.paused;
          }

          // Stepping Logic
          if (!firstInstruction) {
            final stepMode = debugger!.stepMode;
            final currentDepth = _frames.length;
            final currentLine = frame.chunk.getLine(frame.ip);
            
            if (stepMode == StepMode.stepInto) {
              if (currentDepth > (debugger!.stepTargetDepth ?? 0) || 
                  currentLine != debugger!.stepSourceLine) {
                debugger!.pause();
                return InterpretResult.paused;
              }
            } else if (stepMode == StepMode.stepOver) {
              if (currentDepth < (debugger!.stepTargetDepth ?? 0) || 
                  (currentDepth == debugger!.stepTargetDepth && currentLine != debugger!.stepSourceLine)) {
                debugger!.pause();
                return InterpretResult.paused;
              }
            } else if (stepMode == StepMode.stepOut && 
                       debugger!.stepTargetDepth != null) {
              if (currentDepth <= debugger!.stepTargetDepth!) {
                debugger!.pause();
                return InterpretResult.paused;
              }
            }
          }

          // Breakpoints
          final moduleName = frame.closure.function.moduleName;
          if (moduleName != null) {
            final line = frame.chunk.getLine(frame.ip);
            if (line != frame.lastLine) {
              if (debugger!.shouldBreakAt(moduleName, line) != null) {
                frame.lastLine = line;
                debugger!.pause();
                return InterpretResult.paused;
              }
              frame.lastLine = line;
            }
          }
        }
        
        firstInstruction = false;

        // print("DEBUG VM LOOP: IP ${frame.ip}. Stack ${_stack.length}");
        if (frame.ip >= frame.chunk.code.length) {
          // Chunk ended without explicit return - treat as implicit "return nil"
          // This replicates OpCode.return_ logic with nil result
          
          // Close upvalues before cleaning stack
          _closeUpvalues(frame.slotBase);
          
          // Pop the frame
          final endingFrame = _frames.removeLast();
          
          if (_frames.length < minDepth) {
            // Top-level script or nested run() finished
            while (_stack.length > endingFrame.slotBase) {
              _stack.removeLast();
            }
            // Don't push nil for top-level - just exit cleanly
            return InterpretResult.ok;
          }
          
          // Pop all locals (including callee and args) from this frame
          while (_stack.length > endingFrame.slotBase) {
            _stack.removeLast();
          }
          
          // Push nil as implicit return value for caller
          _stack.add(null);
          continue; // Continue in caller's frame
        }

        final instruction = frame.chunk.code[frame.ip];
        final op = OpCode.values[instruction];
        frame.ip++; 
        
        int readByte() {
           final b = frame.chunk.code[frame.ip];
           frame.ip++;
           return b;
        }

        Object? readConstant() {
          final idx = frame.chunk.code[frame.ip];
          frame.ip++;
          return frame.chunk.constants[idx];
        }

        switch (op) {
          case OpCode.constant:
            final constant = readConstant();
            _stack.add(constant);
            break;

          case OpCode.nil:
            _stack.add(null);
            break;
          case OpCode.true_:
            _stack.add(true);
            break;
          case OpCode.false_:
            _stack.add(false);
            break;
          case OpCode.pop:
            if (_stack.isNotEmpty) _stack.removeLast();
            break;
            
          case OpCode.noOp:
            break;

          case OpCode.add:
            final b = _stack.removeLast();
            final a = _stack.removeLast();
            if (a is String || b is String) {
              _stack.add(a.toString() + b.toString());
            } else if (a is num && b is num) {
              _stack.add(a + b);
            } else if (a is List && b is List) {
              _stack.add([...a, ...b]);
            } else {
              throw "Operands must be two numbers, two strings or two lists.";
            }
            break;

          case OpCode.sub:
            final b = _stack.removeLast() as num;
            final a = _stack.removeLast() as num;
            _stack.add(a - b);
            break;

          case OpCode.mul:
            final b = _stack.removeLast() as num;
            final a = _stack.removeLast() as num;
            _stack.add(a * b);
            break;

          case OpCode.div:
            final b = _stack.removeLast() as num;
            final a = _stack.removeLast() as num;
            _stack.add(a / b);
            break;

          case OpCode.mod:
            final b = _stack.removeLast() as num;
            final a = _stack.removeLast() as num;
            _stack.add(a % b);
            break;

          case OpCode.negate:
            final a = _stack.removeLast() as num;
            _stack.add(-a);
            break;

          case OpCode.not:
            final a = _stack.removeLast();
            _stack.add(!_isTruthy(a));
            break;

          case OpCode.less:
            final b = _stack.removeLast() as num;
            final a = _stack.removeLast() as num;
            _stack.add(a < b);
            break;

          case OpCode.greater:
            final b = _stack.removeLast() as num;
            final a = _stack.removeLast() as num;
            _stack.add(a > b);
            break;

          case OpCode.equal:
            final b = _stack.removeLast();
            final a = _stack.removeLast();
            _stack.add(a == b);
            break;

          case OpCode.greaterEqual:
            final b = _stack.removeLast();
            final a = _stack.removeLast();
            if (a is! num || b is! num) {
              _runtimeError("Operands to '>=' must be numbers, got ${a.runtimeType} and ${b.runtimeType}");
              return InterpretResult.runtimeError;
            }
            _stack.add(a >= b);
            break;

          case OpCode.lessEqual:
            final b = _stack.removeLast() as num;
            final a = _stack.removeLast() as num;
            _stack.add(a <= b);
            break;

          case OpCode.print:
            final val = _stack.removeLast();
            onPrint(val.toString());
            break;

          case OpCode.setGlobal:
            final nameIdx = readByte(); // Index in constants
            final nameObj = frame.chunk.constants[nameIdx];
            if (nameObj is! String) {
               _runtimeError("Global name must be a string, got ${nameObj.runtimeType} ($nameObj) at index $nameIdx");
               return InterpretResult.runtimeError;
            }
            final name = nameObj;
            
            // Check if it's a state field first
            if (_widgetState.containsKey(name)) {
              _widgetState[name] = _stack.last;
              onStateChange?.call(name, _stack.last);
            } else {
              _globals[name] = _stack.last;
            }
            break;

          case OpCode.getGlobal:
            final nameIdx = readByte();
            final nameObj = frame.chunk.constants[nameIdx];
             if (nameObj is! String) {
               _runtimeError("Global name must be a string, got ${nameObj.runtimeType} ($nameObj) at index $nameIdx");
               return InterpretResult.runtimeError;
            }
            final name = nameObj;
            
            // Check widget state first, then globals
            if (_widgetState.containsKey(name)) {
              _stack.add(_widgetState[name]);
            } else if (_globals.containsKey(name)) {
              _stack.add(_globals[name]);
            } else {
              throw "Undefined global '$name'.";
            }
            break;

          case OpCode.getLocal:
            final slot = readByte();
            final index = frame.slotBase + slot;
            _stack.add(_stack[index]);
            break;

          case OpCode.setLocal:
            final slot = readByte();
            _stack[frame.slotBase + slot] = _stack.last;
            break;



          case OpCode.popScope:
             // Should not be emitted by compiler anymore, but keep for compatibility
             final count = readByte();
             for(var i=0; i<count; i++) _stack.removeLast();
             break;

          // Control flow
          case OpCode.jumpIfFalse:
            final offsetLow = readByte();
            final offsetHigh = readByte();
            final offset = offsetLow | (offsetHigh << 8);
            final condition = _stack.last;
            if (!_isTruthy(condition)) {
              frame.ip += offset;
            }
            break;

          case OpCode.jumpIfTrue:
            final offsetLow = readByte();
            final offsetHigh = readByte();
            final offset = offsetLow | (offsetHigh << 8);
            final condition = _stack.last;
            if (_isTruthy(condition)) {
              frame.ip += offset;
            }
            break;

          case OpCode.jump:
            final offsetLow = readByte();
            final offsetHigh = readByte();
            final offset = offsetLow | (offsetHigh << 8);
            frame.ip += offset;
            break;

          case OpCode.loop:
            final offset = readByte();
            frame.ip -= offset;
            break;

          // Function calls
          case OpCode.call:
            final argCount = readByte();
            final callee = _stack[_stack.length - 1 - argCount];
            if (!_callValue(callee, argCount)) {
              return InterpretResult.runtimeError;
            }
            // Update frame reference after call returns
            if (_frames.isNotEmpty) {
              frame = _frames.last;
            }
            break;

          case OpCode.callNamed:
            final argCount = readByte();
            final namedCount = readByte();
            final namedArgs = <String, dynamic>{};

            // Pop named arguments (count pairs of key, value)
            for (int i = 0; i < namedCount; i++) {
              final value = _stack.removeLast();
              final nameObj = _stack.removeLast();
              if (nameObj is! String) {
                _runtimeError("type '${nameObj.runtimeType}' (value: $nameObj) is not a subtype of type 'String' in type cast. i=$i, namedCount=$namedCount");
                return InterpretResult.runtimeError;
              }
              namedArgs[nameObj] = value;
            }

            final totalArgSlots = argCount; // positional args only on stack now
            final callee = _stack[_stack.length - 1 - totalArgSlots];

            if (!_callValue(callee, argCount, namedArgs)) {
              return InterpretResult.runtimeError;
            }
            // Update frame reference after call returns
            if (_frames.isNotEmpty) {
              frame = _frames.last;
            }
            break;

          case OpCode.return_:
            final result = _stack.last; // Peek result first

            // Close upvalues for remaining locals in this frame
            _closeUpvalues(frame.slotBase);
            
            // Now remove result
            _stack.removeLast();

            // Pop frame
            final returningFrame = _frames.removeLast();

             if (_frames.length <= minDepth) {
                // Finished execution for this nested run() or top-level script
                // Pop slots up to the closure (slotBase)
            while (_stack.length > returningFrame.slotBase) {
               _stack.removeLast();
            }
               _stack.add(result); // Always push result (including nil)
               return InterpretResult.ok;
            }
            
            // Discard all locals from this frame (including the callee and args)
            while (_stack.length > returningFrame.slotBase) {
               _stack.removeLast();
            }
            
            // Push result back (always, including nil)
            _stack.add(result);
            break; // Continue in caller's frame

          case OpCode.newList:
            final count = readByte();
            final list = <Object?>[];
            // Pop elements in reverse order
            for (int i = 0; i < count; i++) {
              list.insert(0, _stack.removeLast());
            }
            _stack.add(list);
            break;
            
          case OpCode.newMap:
            final count = readByte();
            final map = <Object?, Object?>{};
            // Pop key-value pairs in reverse order
            for (int i = 0; i < count; i++) {
              final value = _stack.removeLast();
              final key = _stack.removeLast();
              map[key] = value;
            }
            _stack.add(map);
            break;
            

            
          case OpCode.closure:
            // Read function index from constants
            final funcIndex = readByte();
            final function = frame.chunk.constants[funcIndex] as CompiledFunction;
            
            // Read upvalue count
            final upvalueCount = readByte();
            final upvalues = <ObjUpvalue>[];
            
            for (int i = 0; i < upvalueCount; i++) {
              final isLocal = readByte() == 1;
              final index = readByte();
              
              if (isLocal) {
                // Capture a local variable from current frame
                final loc = frame.slotBase + index;
                upvalues.add(_captureUpvalue(loc));
              } else {
                // Capture an upvalue from enclosing closure
                upvalues.add(frame.closure.upvalues[index]);
              }
            }
            
            _stack.add(ObjClosure(function, upvalues));
            break;
            
          case OpCode.getUpvalue:
            final index = readByte();
            // Get upvalue from current closure
            final callee = frame.closure;
            if (index < callee.upvalues.length) {
              _stack.add(callee.upvalues[index].getValue(_stack));
            } else {
              throw 'Invalid upvalue access';
            }
            break;
            
          case OpCode.setUpvalue:
            final index = readByte();
            final value = _stack.last;
            // Set upvalue in current closure
            final callee = frame.closure;
            if (index < callee.upvalues.length) {
              callee.upvalues[index].setValue(_stack, value);
            } else {
              throw 'Invalid upvalue access';
            }
            break;
            
          case OpCode.closeUpvalue:
            // Close any open upvalues pointing to the top of the stack
            _closeUpvalues(_stack.length - 1);
            _stack.removeLast();
            break;
            
          case OpCode.try_:
            // Read catch and finally absolute addresses
            final catchAddrLow = readByte();
            final catchAddrHigh = readByte();
            final catchAddr = catchAddrLow | (catchAddrHigh << 8);
            
            final finallyAddrLow = readByte();
            final finallyAddrHigh = readByte();
            final finallyAddr = finallyAddrLow | (finallyAddrHigh << 8);
            
            // Register exception handler with absolute addresses
            _exceptionHandlers.add(_ExceptionHandler(
              frameIndex: _frames.length - 1,
              stackHeight: _stack.length,
              catchOffset: catchAddr,    // Now absolute address
              finallyOffset: finallyAddr, // Now absolute address
            ));
            break;
            
          case OpCode.catch_:
            // Nothing to do here; catch block is entered via exception path
            // The exception value is already on the stack
            break;
            
          case OpCode.throw_:
            final exception = _stack.removeLast();
            if (!_handleException(exception)) {
              // No handler found, propagate to Dart
              throw exception ?? 'Unknown exception';
            }
            // Update frame to the current (potentially new) frame after unwinding
            frame = _frames.last;
            break;
            
          case OpCode.endTry:
            // Pop the exception handler
            if (_exceptionHandlers.isNotEmpty) {
              _exceptionHandlers.removeLast();
            }
            break;
          
          case OpCode.getIndex:
            final index = _stack.removeLast();
            final obj = _stack.removeLast();
            if (obj is List) {
              final idx = (index as num).toInt();
              if (idx < 0 || idx >= obj.length) {
                _runtimeError("Index $idx out of bounds for list of length ${obj.length}.");
                return InterpretResult.runtimeError;
              }
              _stack.add(obj[idx]);
            } else if (obj is Map) {
              _stack.add(obj[index]);
            } else if (obj is String) {
              final idx = (index as num).toInt();
              if (idx < 0 || idx >= obj.length) {
                _runtimeError("Index $idx out of bounds for string of length ${obj.length}.");
                return InterpretResult.runtimeError;
              }
              _stack.add(obj[idx]);
            } else if (obj is FluxModule) {
              // Module property access: json["parse"], timer["delay"] etc.
              final memberName = index as String;
              final member = obj.get(memberName);
              if (member == null) {
                _runtimeError("Module '${obj.name}' has no member '$memberName'.");
                return InterpretResult.runtimeError;
              }
              _stack.add(member);
            } else {
              _runtimeError("Cannot index into ${obj.runtimeType}.");
              return InterpretResult.runtimeError;
            }
            break;
          
          case OpCode.setIndex:
            final value = _stack.removeLast();
            final index = _stack.removeLast();
            final obj = _stack.removeLast();
            if (obj is List) {
              final idx = (index as num).toInt();
              if (idx < 0 || idx >= obj.length) {
                _runtimeError("Index $idx out of bounds for list of length ${obj.length}.");
                return InterpretResult.runtimeError;
              }
              obj[idx] = value;
              _stack.add(value); // Assignment expression returns the value
            } else if (obj is Map) {
              obj[index] = value;
              _stack.add(value);
            } else {
              _runtimeError("Cannot set index on ${obj.runtimeType}.");
              return InterpretResult.runtimeError;
            }
            break;
          
          // Module system
          case OpCode.import_:
            final pathIdx = readByte();
            final path = frame.chunk.constants[pathIdx] as String;
            // Import is handled externally - store path for loader
            _imports.add(path);
            break;
          
          // Class system
          case OpCode.instance:
            final classObj = _stack.removeLast();
            if (classObj is CompiledClass) {
              final instance = FluxInstance(classObj);
              _stack.add(instance);
            } else {
              throw 'Cannot instantiate non-class: $classObj';
            }
            break;
            

          case OpCode.getProperty:
            final nameIdx = readByte();
            final name = frame.chunk.constants[nameIdx] as String;
            final obj = _stack.removeLast();
            if (obj is FluxInstance) {
              // 1. Check fields (Dynamic check, always first)
              if (obj.fields.containsKey(name)) {
                 _stack.add(obj.fields[name]);
                 break;
              }
              
              if (enableInlineCaching) {
                // Cache key is the PC of this instruction
                final callSiteOffset = frame.ip - 2; 
                final cache = _inlineCacheManager.getCache(callSiteOffset, name);
                
                // 2. Inline Cache Path: Check for cached method
                final cachedMethod = cache.lookupMethod(obj.klass);
                if (cachedMethod != null) {
                  _stack.add(cachedMethod);
                  break;
                }
                
                // 3. Slow Path: Look up in class and cache it
                if (obj.klass.methods.containsKey(name)) {
                  final method = obj.klass.methods[name]!;
                  cache.cacheMethod(obj.klass, method);
                  _stack.add(method);
                } else {
                  throw 'Undefined property: ${obj.klass.name}.$name';
                }
              } else {
                // No Inline Caching: Simple lookup
                if (obj.klass.methods.containsKey(name)) {
                  _stack.add(obj.klass.methods[name]!);
                } else {
                  throw 'Undefined property: ${obj.klass.name}.$name';
                }
              }
            } else if (obj is List) {
              if (name == 'length') {
                _stack.add(obj.length);
              } else {
                _stack.add(null);
              }
            } else if (obj is Map) {
              if (name == 'length') {
                _stack.add(obj.length);
              } else {
                _stack.add(obj[name]);
              }
            } else if (obj is FluxModule) {
               final member = obj.get(name);
               if (member != null) {
                 _stack.add(member);
               } else {
                  throw "Undefined member '$name' in module '${obj.name}'";
               }
            } else if (_widgetState.containsKey(name)) { 
               _stack.add(_widgetState[name]);
            } else {
              print('DEBUG VM: getProperty $name on ${obj.runtimeType}');
              throw 'Cannot get property from ${obj.runtimeType}';
            }
            break;
            
          case OpCode.setProperty:
            final nameIdx = readByte();
            final name = frame.chunk.constants[nameIdx] as String;
            final value = _stack.removeLast();
            final obj = _stack.removeLast();
            if (obj is FluxInstance) {
              obj.setProperty(name, value);
              _stack.add(value); // Standardized: Assignment leaves value on stack
            } else if (obj is Map) {
              obj[name] = value;
              _stack.add(value);
            } else {
              throw 'Cannot set property on ${obj.runtimeType}';
            }
            break;

          case OpCode.getState:
            final idx = readByte();
            final name = frame.chunk.constants[idx] as String;
            if (_widgetState.containsKey(name)) {
                _stack.add(_widgetState[name]);
            } else {
                _runtimeError("Undefined state variable '$name'.");
                return InterpretResult.runtimeError;
            }
            break;

          case OpCode.setState: // New opcode for setting widget state
            final idx = readByte();
            final name = frame.chunk.constants[idx] as String;
            final value = _stack.last; // Peek/Assigned value
            if (_widgetState.containsKey(name)) {
               _widgetState[name] = value;
               
               // Persistence check
               final currentWidget = _currentWidgetName;
               if (currentWidget != null && persistenceDelegate != null && _persistentFields.contains(name)) {
                 persistenceDelegate!.save("flux_state_${currentWidget}_$name", value);
               }

               if (onStateChange != null) onStateChange!(name, value);
            } else {
               throw "Undefined state variable '$name'.";
            }
            break;
            
          case OpCode.invoke:
            final nameIdx = readByte();
            final argCount = readByte();
            final name = frame.chunk.constants[nameIdx] as String;
            
            // Get arguments
            final args = <Object?>[];
            for (int i = 0; i < argCount; i++) {
              args.insert(0, _stack.removeLast());
            }
            
            // Get instance
            final instance = _stack.removeLast();
            if (instance is FluxInstance) {
              final method = instance.klass.methods[name];
              if (method != null) {
                // Call method with instance as 'this'
                print('DEBUG VM: Invoking method $name on instance ${instance.runtimeType}');
                _callMethod(instance, method, args);
              } else {
                throw 'Undefined method: ${instance.klass.name}.$name';
              }
            } else if (instance is FluxModule) {
               final member = instance.get(name);
               if (member != null) {
                  // It's a NativeFunction or AsyncNativeFunction.
                  // We need to call it.
                  // _callValue expects the function to be on top of stack?
                  // No, _callValue(callee, argCount).
                  // But here we are in OpCode.invoke.
                  // We have 'instance' and 'args'.
                  // We can just call _callValue(member, argCount) ?
                  // But _callValue pops args from stack. We already popped them into 'args' list in invoke.
                  // This OpCode.invoke implementation is specific for FluxInstance which handles args differently?
                  // Wait, OpCode.invoke implementation in vm.dart lines 1306-1310 POPS args into a List<Object?> named 'args'.
                  // Then it calls _callMethod(instance, method, args).
                  
                  // For NativeFunction, we can just call it directly with 'args'.
                  if (member is NativeFunction) {
                     try {
                        final result = member.call(args);
                        _stack.add(result);
                     } catch (e) {
                        _runtimeError(e.toString());
                        return InterpretResult.runtimeError;
                     }
                  } else if (member is AsyncNativeFunction) {
                      // Async support in invoke?
                      // The current VM seems synchronous for invoke?
                      // _callMethod is synchronous.
                      // If we support async, we need to await. 
                      // For now stdlib json is sync. timer is async but usually not called as method on module?
                      // timer.delay(100) -> FluxModule('timer').get('delay') -> AsyncNativeFunction.
                      
                      // if usage is `await timer.delay(100)`, compiler emits `await` opcode?
                      // If usage is `timer.delay(100)`, it returns a Future.
                      // We should push the specific result.
                      
                      final result = member.call(args); // This returns a Future
                      _stack.add(result);
                  } else {
                     throw 'Member $name in module ${instance.name} is not a function/method';
                  }
               } else {
                 throw 'Undefined method: ${instance.name}.$name';
               }
            } else if (instance is Map) {
                if (instance.containsKey(name)) {
                   final member = instance[name];
                   if (member is NativeFunction) {
                      try {
                        final result = member.call(args);
                        _stack.add(result);
                      } catch (e) {
                         _runtimeError(e.toString());
                         return InterpretResult.runtimeError;
                      }
                   } else if (member is AsyncNativeFunction) {
                      final result = member.call(args);
                      _stack.add(result);
                   } else {
                      throw 'Member $name in Map is not a function';
                   }
                } else {
                   throw 'Undefined field/method: $name on Map';
                }
            } else {
              throw 'Cannot invoke method on ${instance.runtimeType} ($instance)';
            }
            break;

          case OpCode.invokeSuper:
            final nameIdx = readByte();
            final argCount = readByte();
            final name = frame.chunk.constants[nameIdx] as String;
            
            // Get arguments (pop them from stack)
            final args = <Object?>[];
            for (int i = 0; i < argCount; i++) {
              args.insert(0, _stack.removeLast());
            }
            
            // Get instance ('this')
            final instance = _stack.removeLast();
            if (instance is FluxInstance) {
              final superclassName = instance.klass.superclass;
              if (superclassName == null) {
                throw 'Class ${instance.klass.name} has no superclass.';
              }
              
              final superclass = _globals[superclassName];
              if (superclass is CompiledClass) {
                // Find method in superclass or its ancestors
                CompiledFunction? method;
                CompiledClass? currentClass = superclass;
                while (currentClass != null) {
                  method = currentClass.methods[name];
                  if (method != null) break;
                  
                  if (currentClass.superclass != null) {
                    currentClass = _globals[currentClass.superclass] as CompiledClass?;
                  } else {
                    currentClass = null;
                  }
                }
                
                if (method != null) {
                  _callMethod(instance, method, args);
                } else {
                  throw 'Undefined method: $superclassName.$name';
                }
              } else {
                throw 'Superclass $superclassName not found.';
              }
            } else {
              throw 'Cannot invoke super method on ${instance.runtimeType}';
            }
            break;
          
          case OpCode.await_:
            
            // Pop the value to await (should be a Future)
            final value = _stack.removeLast();
            if (value is Future) {
              // Create coroutine snapshot for resumption
              final coroutine = suspendToCoroutine();
              
              // Set legacy flags for compatibility
              _awaitingFuture = true;
              _pendingFuture = value;
              _pendingFrame = frame;
              
              // Register callback for when Future completes
              value.then((result) {
                coroutine.awaitResult = result;
                
                // Notify external handler for resume scheduling
                if (coroutineResumeCallback != null) {
                  coroutineResumeCallback!(coroutine, result, null);
                } else {
                  // Fallback: direct resume (for non-Flutter contexts)
                  _awaitingFuture = false;
                  _pendingFuture = null;
                  _pendingFrame = null;
                  resumeCoroutine(coroutine, result);
                }
              }).catchError((error) {
                coroutine.awaitError = error;
                
                // Notify external handler for error handling
                if (coroutineResumeCallback != null) {
                  coroutineResumeCallback!(coroutine, null, error);
                } else {
                  // Fallback: direct error handling
                  _awaitingFuture = false;
                  _pendingFuture = null;
                  _pendingFrame = null;
                  resumeCoroutineWithError(coroutine, error);
                }
              });
              
              // Return awaiting status - VM loop exits
              return InterpretResult.awaiting;
            } else {
              // Not a Future, just push it back (already resolved)
              _stack.add(value);
            }
            break;
             
          default:
            throw "Unknown opcode $op";
        }
      }
    } catch (e, stack) {
      print('DEBUG VM RUNTIME EXCEPTION: $e');
      print('Stack Trace: $stack');
      if (_frames.isNotEmpty) {
        final frame = _frames.last;
        print('IP: ${frame.ip}');
        if (frame.ip > 0 && frame.ip <= frame.chunk.code.length) {
             try {
                 final opCode = frame.chunk.code[frame.ip - 1]; // -1 as ip was incremented
                 print('Last OpCode: ${OpCode.values[opCode]}');
             } catch (_) {}
        }
      }
      _runtimeError(e.toString());
      return InterpretResult.runtimeError;
    }
    // return InterpretResult.ok; // Unreachable
  }

  // Helper method for isAwaiting check (used in tests)
  bool get isAwaiting => _awaitingFuture;
  
  /// Handle an exception by finding and jumping to the appropriate handler
  /// Returns true if handler found, false if exception should propagate to Dart
  bool _handleException(Object? exception) {
    while (_exceptionHandlers.isNotEmpty) {
      final handler = _exceptionHandlers.removeLast();
      
      // Check if we have enough frames to unwind to
      if (handler.frameIndex >= _frames.length) {
        continue; // Invalid handler, skip
      }
      
      // Unwind call frames to the handler's frame
      while (_frames.length > handler.frameIndex + 1) {
        _frames.removeLast();
      }
      
      // Unwind value stack to the handler's stack height
      while (_stack.length > handler.stackHeight) {
        _stack.removeLast();
      }
      
      // Push exception onto stack for catch block
      _stack.add(exception);
      
      // Jump to catch block in the handler's frame
      if (_frames.isNotEmpty) {
        _frames.last.ip = handler.catchOffset;
        return true;
      }
    }
    return false;
  }
  
  /// Call a method on an instance
  void _callMethod(FluxInstance instance, CompiledFunction method, List<Object?> args) {
    // Create closure for method (no upvalues for simple methods)
    final closure = ObjClosure(method, []);
    
    // Push instance as 'this' (slot 0)
    _stack.add(instance);
    
    // Push arguments
    for (final arg in args) {
      _stack.add(arg);
    }
    
    // Create new call frame
    final newFrame = CallFrame(closure, slotBase: _stack.length - args.length - 1);
    _frames.add(newFrame);
  }

  final Set<String> _persistentFields = {};
}
