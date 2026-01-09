/// Flux Language - Closure and Upvalue Support
///
/// Based on Crafting Interpreters closure implementation.

import 'package:flux_compiler/flux_compiler.dart';

/// Represents a captured upvalue (closed-over variable)
class ObjUpvalue {
  /// If closed, this holds the actual value
  Object? closed;

  /// Stack index when still on stack (before closing)
  int location;

  /// Pointer to next upvalue in linked list (for open upvalues)
  ObjUpvalue? next;

  /// Whether this upvalue has been closed (moved to heap)
  bool isClosed = false;

  ObjUpvalue(this.location);

  /// Get the value - either from stack or closed value
  Object? getValue(List<Object?> stack) {
    if (isClosed) {
      return closed;
    }
    return stack[location];
  }

  /// Set the value - either in stack or closed value
  void setValue(List<Object?> stack, Object? value) {
    if (isClosed) {
      closed = value;
    } else {
      stack[location] = value;
    }
  }

  /// Close this upvalue - move value from stack to heap
  void close(List<Object?> stack) {
    if (!isClosed) {
      closed = stack[location];
      isClosed = true;
    }
  }

  @override
  String toString() =>
      isClosed ? 'Upvalue(closed: $closed)' : 'Upvalue(loc: $location)';
}

/// Represents a closure - a function with its captured environment
class ObjClosure {
  /// The underlying compiled function
  final CompiledFunction function;

  /// The captured upvalues
  final List<ObjUpvalue> upvalues;

  ObjClosure(this.function, this.upvalues);

  @override
  String toString() => '<closure ${function.name}>';
}

/// Upvalue info stored during compilation
class UpvalueInfo {
  /// Index in enclosing function's locals or upvalues
  final int index;

  /// True if capturing a local, false if capturing an upvalue
  final bool isLocal;

  UpvalueInfo(this.index, this.isLocal);
}
