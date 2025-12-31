/// Flux Language - Coroutine Support
/// 
/// Implements coroutines for async/await functionality.
/// Based on Lua coroutine pattern with Dart event loop integration.

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
  
  /// Saved call frames (execution stack)
  /// Each frame contains: closure, instruction pointer, slot base
  final List<CoroutineFrame> savedFrames = [];
  
  /// Saved value stack
  final List<Object?> savedStack = [];
  
  /// Widget state snapshot (for Flux widgets)
  final Map<String, Object?> savedWidgetState = {};
  
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
  String toString() => 'FluxCoroutine($id, state: $state, frames: ${savedFrames.length})';
}

/// Saved state of a single call frame
class CoroutineFrame {
  /// Index into the closure list (for reconstruction)
  final int closureConstantIndex;
  
  /// Instruction pointer within the frame's chunk
  final int instructionPointer;
  
  /// Base slot index on the stack
  final int slotBase;
  
  /// The actual closure (for simple cases)
  final Object? closureRef;
  
  CoroutineFrame({
    required this.closureConstantIndex,
    required this.instructionPointer,
    required this.slotBase,
    this.closureRef,
  });
  
  @override
  String toString() => 'CoroutineFrame(ip: $instructionPointer, slot: $slotBase)';
}

/// Callback type for coroutine resume notifications
typedef CoroutineResumeCallback = void Function(
  FluxCoroutine coroutine,
  Object? result,
  Object? error,
);
