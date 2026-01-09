/// Flux Language - Coroutine Support
///
/// Implements coroutines for async/await functionality.
/// Based on Lua coroutine pattern with Dart event loop integration.

import 'package:flux_compiler/flux_compiler.dart';
import 'closure.dart';

/// Coroutine execution state
enum CoroutineState {
  /// Coroutine created but not yet started
  created,

  /// Coroutine is currently executing
  running,

  /// Coroutine is suspended (waiting for await)
  suspended,

  /// Coroutine completed successfully
  completed,

  /// Coroutine terminated with error
  error,
}

/// Represents a single active function call
class CallFrame {
  final ObjClosure closure;
  int ip; // Instruction pointer within the function's chunk
  final int slotBase; // Start of this frame's local variables on the stack
  int lastLine = -1; // For debugger debouncing

  CallFrame(this.closure, {this.ip = 0, required this.slotBase});

  Chunk get chunk => closure.function.chunk;

  @override
  String toString() =>
      'CallFrame(fn: ${closure.function.name}, ip: $ip, base: $slotBase)';
}

/// Represents a suspendable/resumable execution context.
///
/// When an `await` expression is encountered and the awaited Future is pending,
/// the VM creates a FluxCoroutine to capture the current execution state.
/// When the Future completes, the coroutine is resumed with the result.
class FluxCoroutine {
  /// Unique identifier for this coroutine
  final String id;

  /// Current state of the coroutine
  CoroutineState state = CoroutineState.created;

  /// Active call frames (execution stack)
  final List<CallFrame> frames = [];

  /// Active value stack
  final List<Object?> stack = [];

  /// Result from awaited Future (set when Future completes)
  Object? awaitResult;

  /// Error from awaited Future (set when Future fails)
  Object? awaitError;

  /// Callback invoked when coroutine completes
  void Function(Object? result)? onComplete;

  /// Callback invoked when coroutine errors
  void Function(Object? error)? onError;

  /// Timestamp when coroutine was created
  final DateTime createdAt;

  /// Timestamp when coroutine was last suspended
  DateTime? suspendedAt;

  FluxCoroutine(this.id) : createdAt = DateTime.now();

  /// Create a unique ID for a new coroutine
  static String generateId() {
    return 'coro_${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  String toString() =>
      'FluxCoroutine($id, state: $state, frames: ${frames.length}, stack: ${stack.length})';
}

/// Callback type for coroutine resume notifications
typedef CoroutineResumeCallback = void Function(
  FluxCoroutine coroutine,
  Object? result,
  Object? error,
);
