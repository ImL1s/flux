/// Flux Language - Virtual Machine
/// 
/// Executes Flux bytecode using a stack-based architecture.
/// Based on Crafting Interpreters bytecode VM pattern.

import 'package:flux_compiler/flux_compiler.dart';
import 'stdlib.dart';
import 'closure.dart';
import 'coroutine.dart';

typedef WidgetCallHandler = Object? Function(Object? callee, int argCount, Map<String, dynamic> namedArgs, List<Object?> stack);

enum InterpretResult {
  ok,
  compileError,
  runtimeError,
  awaiting,  // VM is suspended waiting for a Future
}

/// Represents a single active function call
class CallFrame {
  final ObjClosure closure;
  int ip;              // Instruction pointer within the function's chunk
  final int slotBase;  // Start of this frame's local variables on the stack
  
  CallFrame(this.closure, {this.ip = 0, required this.slotBase});
  
  Chunk get chunk => closure.function.chunk;
}

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
  final List<Object?> _stack = [];
  final Map<String, Object?> _globals = {};
  final List<CallFrame> _frames = [];
  
  /// Widget state storage (keyed by state field name)
  final Map<String, Object?> _widgetState = {};
  
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
  
  // Exception handling state
  final List<_ExceptionHandler> _exceptionHandlers = [];
  
  // Coroutine support
  FluxCoroutine? _currentCoroutine;
  CoroutineResumeCallback? coroutineResumeCallback;
  
  // Module import tracking
  final List<String> _imports = [];
  
  /// Get list of imports encountered during execution
  List<String> get imports => List.unmodifiable(_imports);
  
  /// Constructor - initializes standard library
  VM() {
    _initStdlib();
  }
  
  /// Initialize standard library functions
  void _initStdlib() {
    StdLib.init();
    for (final entry in StdLib.functions.entries) {
      _globals[entry.key] = entry.value;
    }
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
  FluxCoroutine suspendToCoroutine() {
    final coroutine = FluxCoroutine(FluxCoroutine.generateId());
    
    // Save all call frames
    for (final frame in _frames) {
      coroutine.savedFrames.add(CoroutineFrame(
        closureConstantIndex: 0, // Not used for direct closure ref
        instructionPointer: frame.ip,
        slotBase: frame.slotBase,
        closureRef: frame.closure,
      ));
    }
    
    // Save stack
    coroutine.savedStack.addAll(_stack);
    
    // Save widget state
    coroutine.savedWidgetState.addAll(_widgetState);
    
    coroutine.state = CoroutineState.suspended;
    coroutine.suspendedAt = DateTime.now();
    
    _currentCoroutine = coroutine;
    return coroutine;
  }
  
  /// Resume a suspended coroutine with the await result
  /// 
  /// Called when the awaited Future completes.
  InterpretResult resumeCoroutine(FluxCoroutine coroutine, Object? result) {
    if (coroutine.state != CoroutineState.suspended) {
      _runtimeError('Cannot resume coroutine in state: ${coroutine.state}');
      return InterpretResult.runtimeError;
    }
    
    // Restore call frames
    _frames.clear();
    for (final savedFrame in coroutine.savedFrames) {
      if (savedFrame.closureRef is ObjClosure) {
        _frames.add(CallFrame(
          savedFrame.closureRef as ObjClosure,
          ip: savedFrame.instructionPointer,
          slotBase: savedFrame.slotBase,
        ));
      }
    }
    
    // Restore stack
    _stack.clear();
    _stack.addAll(coroutine.savedStack);
    
    // Restore widget state
    _widgetState.clear();
    _widgetState.addAll(coroutine.savedWidgetState);
    
    // Push the await result
    _stack.add(result);
    
    // Update coroutine state
    coroutine.state = CoroutineState.running;
    _currentCoroutine = null;
    
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
  InterpretResult resumeCoroutineWithError(FluxCoroutine coroutine, Object error) {
    if (coroutine.state != CoroutineState.suspended) {
      _runtimeError('Cannot resume coroutine in state: ${coroutine.state}');
      return InterpretResult.runtimeError;
    }
    
    coroutine.awaitError = error;
    coroutine.state = CoroutineState.error;
    
    // Restore state for error handling
    _frames.clear();
    for (final savedFrame in coroutine.savedFrames) {
      if (savedFrame.closureRef is ObjClosure) {
        _frames.add(CallFrame(
          savedFrame.closureRef as ObjClosure,
          ip: savedFrame.instructionPointer,
          slotBase: savedFrame.slotBase,
        ));
      }
    }
    _stack.clear();
    _stack.addAll(coroutine.savedStack);
    _widgetState.clear();
    _widgetState.addAll(coroutine.savedWidgetState);
    
    // Try to handle exception
    if (_handleException(error)) {
      return _run();
    }
    
    _runtimeError('Unhandled async error: $error');
    return InterpretResult.runtimeError;
  }
  
  /// Access to the stack for widget building
  List<Object?> get stack => _stack;
  
  /// Basic output handler
  void Function(String message) onPrint = print;
  
  /// Access to global variables (for FluxRuntime integration)
  Map<String, Object?> get globals => _globals;
  
  /// Access to widget state for FluxRuntime
  Map<String, Object?> get widgetState => _widgetState;
  
  /// Initialize widget state from CompiledWidget
  void initializeState(CompiledWidget widget) {
    for (int i = 0; i < widget.stateFields.length; i++) {
      final name = widget.stateFields[i];
      final initializer = widget.stateInitializers[i];
      // Execute initializer to get initial value
      runChunk(initializer.chunk);
      _widgetState[name] = _stack.isNotEmpty ? _stack.removeLast() : null;
    }
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
      return InterpretResult.compileError;
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
     final startDepth = _frames.length;
     _stack.add(closure);
     for (final arg in args) {
       _stack.add(arg);
     }

     if (!_callValue(closure, args.length)) {
       return InterpretResult.runtimeError;
     }

     return _run(startDepth);
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
      upvalue.close(_stack);
      _openUpvalues = upvalue.next;
    }
  }

  bool _isTruthy(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    return true;
  }

  void _runtimeError(String message) {
    String sourceLoc = "";
    if (_frames.isNotEmpty) {
      final frame = _frames.last;
      // ip points to next instruction, so look back one
      final instruction = frame.ip > 0 ? frame.ip - 1 : 0;
      if (instruction < frame.chunk.lines.length) {
        final line = frame.chunk.lines[instruction];
        sourceLoc = " [line $line]";
      }
    }
    print("Runtime Error: $message$sourceLoc");
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
      return _callFunction(callee, argCount, namedArgs);
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
        print('DEBUG RUNTIME: NativeFunction ${callee.name} returned $result');
        _stack.add(result);
        return true;
      } catch (e) {
        _runtimeError(e.toString());
        return false;
      }
    }

    if (callee is CompiledWidget) {
      // Widget instantiation - for now just put the widget on stack
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
    CallFrame frame = _frames.last;

    try {
      while (true) {
        if (frame.ip >= frame.chunk.code.length) {
             // Implicit return if end of chunk reached
             return InterpretResult.ok;
        }

        // Debug
      // print("DEBUG VM: IP: ${frame.ip}, Stack: ${(_stack.length > 5 ? _stack.sublist(_stack.length - 5) : _stack)}");
      // print("DEBUG VM: Instr: ${OpCode.values[frame.chunk.code[frame.ip]].name}");

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

          case OpCode.add:
            final b = _stack.removeLast();
            final a = _stack.removeLast();
            if (a is String || b is String) {
              _stack.add(a.toString() + b.toString());
            } else if (a is num && b is num) {
              _stack.add(a + b);
            } else {
              throw "Operands must be two numbers or two strings.";
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
            final b = _stack.removeLast() as num;
            final a = _stack.removeLast() as num;
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
            final name = frame.chunk.constants[nameIdx] as String;
            _globals[name] = _stack.last;
            break;

          case OpCode.getGlobal:
            final nameIdx = readByte();
            final name = frame.chunk.constants[nameIdx] as String;
            if (_globals.containsKey(name)) {
              _stack.add(_globals[name]);
            } else {
              throw "Undefined global '$name'.";
            }
            break;

          case OpCode.getLocal:
            final slot = readByte();
            _stack.add(_stack[frame.slotBase + slot]);
            break;

          case OpCode.setLocal:
            final slot = readByte();
            _stack[frame.slotBase + slot] = _stack.last;
            break;

          case OpCode.getProperty:
            final name = frame.chunk.constants[readByte()] as String;
            final obj = _stack.removeLast();
            
            if (obj is List) {
              if (name == 'length') {
                _stack.add(obj.length);
              } else {
                _runtimeError("List has no property '$name'.");
                return InterpretResult.runtimeError;
              }
            } else if (obj is Map) {
              if (name == 'length') {
                _stack.add(obj.length);
              } else {
                _stack.add(obj[name]);
              }
            } else {
              _runtimeError("Only lists and maps have properties.");
              return InterpretResult.runtimeError;
            }
            break;

          case OpCode.popScope:
             // Should not be emitted by compiler anymore, but keep for compatibility
             final count = readByte();
             for(var i=0; i<count; i++) _stack.removeLast();
             break;

          // Control flow
          case OpCode.jumpIfFalse:
            final offset = readByte();
            final condition = _stack.last;
            if (!_isTruthy(condition)) {
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
                _runtimeError("type '${nameObj.runtimeType}' is not a subtype of type 'String' in type cast");
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
            final result = _stack.removeLast();

            // Close upvalues for remaining locals in this frame
            _closeUpvalues(frame.slotBase);

            // Pop frame
            final returningFrame = _frames.removeLast();

             if (_frames.length <= minDepth) {
                // Finished execution for this nested run() or top-level script
                // Pop slots up to the closure (slotBase)
                while (_stack.length > returningFrame.slotBase) {
                  _stack.removeLast();
                }

               if (result != null) _stack.add(result);
               return InterpretResult.ok;
            }

            // Discard all locals from this frame (including the callee and args)
            // _closeUpvalues already handled capturing, so we can just wipe stack
            // slotBase pointed to the callee
             while (_stack.length > returningFrame.slotBase) {
               _stack.removeLast();
             }

            // Push return value
            _stack.add(result);

            // Continue in caller's frame
            if (_frames.isNotEmpty) {
              frame = _frames.last;
            }
            break;

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
            
          case OpCode.getIndex:
            final index = _stack.removeLast();
            final object = _stack.removeLast();
            if (object is List) {
              if (index is int && index >= 0 && index < object.length) {
                _stack.add(object[index]);
              } else {
                throw 'List index out of bounds: $index';
              }
            } else if (object is Map) {
              _stack.add(object[index]);
            } else if (object is String) {
              if (index is int && index >= 0 && index < object.length) {
                _stack.add(object[index]);
              } else {
                throw 'String index out of bounds: $index';
              }
            } else {
              throw 'Cannot index into ${object.runtimeType}';
            }
            break;
            
          case OpCode.setIndex:
            final value = _stack.removeLast();
            final index = _stack.removeLast();
            final object = _stack.removeLast();
            if (object is List) {
              if (index is int && index >= 0 && index < object.length) {
                object[index] = value;
                _stack.add(value);
              } else {
                throw 'List index out of bounds: $index';
              }
            } else if (object is Map) {
              object[index] = value;
              _stack.add(value);
            } else {
              throw 'Cannot set index on ${object.runtimeType}';
            }
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
                upvalues.add(_captureUpvalue(frame.slotBase + index));
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
              final value = obj.getProperty(name);
              _stack.add(value);
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
            } else if (_widgetState.containsKey(name)) { 
               _stack.add(_widgetState[name]);
            } else {
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
            } else if (obj is Map) {
              obj[name] = value;
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
                _callMethod(instance, method, args);
              } else {
                throw 'Undefined method: ${instance.klass.name}.$name';
              }
            } else {
              throw 'Cannot invoke method on ${instance.runtimeType}';
            }
            break;
          
          case OpCode.await_:
            // DEBUG: Check for potential stack corruption (Ghost closure duplication)
            // This handles a specific issue where 'this' closure appears duplicated on the stack
            if (_stack.length >= 3) {
                 final peekFuture = _stack.last;
                 final peekSecond = _stack[_stack.length - 2];
                 final peekThird = _stack[_stack.length - 3];
                 // Check if we have [Closure, Closure, Future] pattern
                 // We use runtimeType check and toString or identity
                 if (peekFuture is Future && 
                     peekSecond.runtimeType.toString().contains('ObjClosure') && 
                     peekThird.runtimeType.toString().contains('ObjClosure')) {
                      // Remove the duplicate closure (keep Future)
                      _stack.removeAt(_stack.length - 2);
                 }
            }
            
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
    } catch (e) {
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
}
