/// Flux Language - Virtual Machine
/// 
/// Executes Flux bytecode using a stack-based architecture.
/// Based on Crafting Interpreters bytecode VM pattern.

import 'package:flux_compiler/flux_compiler.dart';
import 'stdlib.dart';
import 'closure.dart';

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
  
  // Async/await state
  bool _awaitingFuture = false;
  Future<dynamic>? _pendingFuture;
  CallFrame? _pendingFrame;
  
  // Exception handling state
  final List<_ExceptionHandler> _exceptionHandlers = [];
  
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
  
  /// Access to global variables (for FluxRuntime integration)
  Map<String, Object?> get globals => _globals;
  
  /// Access to widget state for FluxRuntime
  Map<String, Object?> get widgetState => _widgetState;
  
  /// Access to the stack for widget building
  List<Object?> get stack => _stack;
  
  /// Basic output handler
  void Function(String message) onPrint = print;
  
  /// Optional widget call handler for FluxRuntime
  /// Called when a function call is made and returns non-null to intercept
  /// Parameters: (callee, argCount, stack) => handled result or null
  Object? Function(Object? callee, int argCount, List<Object?> stack)? widgetCallHandler;
  
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
    print("Runtime Error: $message");
  }

  bool _callValue(Object? callee, int argCount) {
    // Check if external handler wants to intercept this call
    if (widgetCallHandler != null) {
      final result = widgetCallHandler!(callee, argCount, _stack);
      if (result != null) {
        // Handler processed the call, result is already on stack
        return true;
      }
    }
    
    if (callee is ObjClosure) {
      return _callFunction(callee, argCount);
    }
    
    // Support calling raw CompiledFunctions by wrapping them (e.g. from tests or old code)
    if (callee is CompiledFunction) {
      final closure = ObjClosure(callee, []);
      _stack[_stack.length - argCount - 1] = closure; // Replace function on stack with closure
      return _callFunction(closure, argCount);
    }
    
    if (callee is NativeFunction) {
      final args = _stack.sublist(_stack.length - argCount);
      _stack.length -= argCount + 1; // Pop args and function
      try {
        final result = callee.call(args);
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

  bool _callFunction(ObjClosure closure, int argCount) {
    if (argCount != closure.function.arity) {
      _runtimeError("Expected ${closure.function.arity} arguments but got $argCount.");
      return false;
    }
    
    if (_frames.length == framesMax) {
      _runtimeError("Stack overflow.");
      return false;
    }
    
    final frame = CallFrame(
      closure,
      slotBase: _stack.length - argCount,
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
        // print("IP: ${frame.ip}, Stack: $_stack");
        // print("Instr: ${OpCode.values[frame.chunk.code[frame.ip]].name}");
        
        final instruction = frame.chunk.code[frame.ip];
        frame.ip++;
        
        final op = OpCode.values[instruction];
        
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
            if (!_globals.containsKey(name)) {
              throw "Undefined variable '$name'.";
            }
            _stack.add(_globals[name]);
            break;
            
          case OpCode.getLocal:
            final slot = readByte();
            _stack.add(_stack[frame.slotBase + slot]);
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
             
          case OpCode.return_:
            final result = _stack.removeLast();
            
            // Close upvalues for remaining locals in this frame
            _closeUpvalues(frame.slotBase);
            
            // Pop frame
            final returningFrame = _frames.removeLast();
            
            if (_frames.length == minDepth) {
               // Finished execution for this nested run()
               // Pop slots up to the closure (slotBase - 1)
               while (_stack.length > returningFrame.slotBase - 1) {
                 _stack.removeLast();
               }
               
               if (result != null) _stack.add(result);
               return InterpretResult.ok;
            }
            
            if (_frames.isEmpty) {
              // Top-level script finished
              _stack.removeLast(); // Pop script closure
              if (result != null) _stack.add(result); // Keep result for caller
              return InterpretResult.ok;
            }
            
            // Discard all locals from this frame (including the callee and args)
            // _closeUpvalues already handled capturing, so we can just wipe stack
            // We need to pop back to just before the callee was pushed
            // slotBase pointed to the first arg, so callee is at slotBase - 1
            while (_stack.length > frame.slotBase - 1) { // Wait, frame is gone, use popped frame reference? 
              // Actually we popped frame, so 'frame' var is the OLD frame.
              // Wait, previous code used `returnSlotBase`.
              // But 'frame' variable still holds the popped frame object.
              _stack.removeLast();
            }
            
            // Push return value
            _stack.add(result);
            
            // Continue in caller's frame
            frame = _frames.last;
            break;
            
          // Widget State Management
          case OpCode.getState:
            final nameIdx = readByte();
            final name = frame.chunk.constants[nameIdx] as String;
            _stack.add(_widgetState[name]);
            break;
            
          case OpCode.setState:
            final nameIdx = readByte();
            final name = frame.chunk.constants[nameIdx] as String;
            final value = _stack.last; // Peek, don't pop (assignment returns value)
            _widgetState[name] = value;
            // Notify Flutter to rebuild
            onStateChange?.call(name, value);
            break;
            
          case OpCode.defineState:
            readByte(); // skip name
            break;
            
          case OpCode.await_:
            // Pop the value to await from stack
            final value = _stack.removeLast();
            
            if (value is Future) {
              // Mark that we're awaiting and store continuation context
              _awaitingFuture = true;
              _pendingFuture = value;
              _pendingFrame = frame;
              // Return to let event loop handle the future
              return InterpretResult.awaiting;
            } else {
              // Not a Future, just push back the value
              _stack.add(value);
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
            } else if (obj is Map) {
              _stack.add(obj[name]);
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
