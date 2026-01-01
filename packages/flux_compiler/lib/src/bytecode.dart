/// Flux Language - Bytecode Definitions
/// 
/// Defines the instruction set and bytecode structure for the Flux VM.

/// Operation codes for the Flux VM
enum OpCode {
  // Constant loading
  constant, // [const_index] -> Push constant[index] to stack
  nil,      // -> Push null
  true_,    // -> Push true
  false_,   // -> Push false

  // Stack manipulation
  pop,      // Pop top of stack
  noOp,     // No operation (placeholder for optimizations)

  // Arithmetic
  add,      // Pop a, b, push a + b
  sub,      // Pop a, b, push a - b
  mul,      // Pop a, b, push a * b
  div,      // Pop a, b, push a / b
  mod,      // Pop a, b, push a % b
  negate,   // Pop a, push -a

  // Logical / Comparison
  not,      // Pop a, push !a
  equal,    // Pop a, b, push a == b
  greater,  // Pop a, b, push a > b
  less,     // Pop a, b, push a < b
  greaterEqual, // Pop a, b, push a >= b
  lessEqual,    // Pop a, b, push a <= b

  // Variables
  print,      // Pop a, print a
  popScope,   // Pop count values from stack (exit scope)
  
  // Locals (stack based)
  getLocal,  // [slot_index] -> Push stack[slot]
  setLocal,  // [slot_index] -> stack[slot] = top (peek)

  // Globals (name based)
  getGlobal, // [name_index] -> Push global[constants[name_index]]
  setGlobal, // [name_index] -> global[constants[name_index]] = top (peek)

  // Control Flow
  jump,       // [offset] -> ip += offset
  jumpIfFalse,// [offset] -> if top is false, ip += offset
  jumpIfTrue, // [offset] -> if top is true, ip += offset
  loop,       // [offset] -> ip -= offset

  // Functions
  call,       // [arg_count] -> call function with arg_count
  return_,    // Return from function
  
  // Closures
  closure,        // [const_index, upvalue_count, (isLocal, index)*] -> Create closure
  getUpvalue,     // [upvalue_index] -> Push upvalue to stack
  setUpvalue,     // [upvalue_index] -> Set upvalue from stack top
  closeUpvalue,   // Close upvalues for variables going out of scope

  // Widget State Management
  defineState,  // [name_index, initial_value on stack] -> create state variable
  getState,     // [name_index] -> push state value to stack
  setState,     // [name_index, value on stack] -> set state and trigger rebuild
  
  // Async/Await
  await_,       // Pop future from stack, suspend until complete, push result
  
  // List operations
  newList,      // [count] -> Pop count elements, push new List
  listGet,      // Pop index, pop list, push list[index]
  listSet,      // Pop value, pop index, pop list, set list[index] = value
  
  // Map operations  
  newMap,       // [count] -> Pop count*2 elements (key,value pairs), push new Map
  mapGet,       // Pop key, pop map, push map[key]
  mapSet,       // Pop value, pop key, pop map, set map[key] = value
  
  // Index operations (generic)
  getIndex,     // Pop index, pop object, push object[index]
  setIndex,     // Pop value, pop index, pop object, object[index] = value
  
  // Exception handling
  try_,         // [catch_offset, finally_offset] -> Begin try block
  catch_,       // Begin catch block
  throw_,       // Pop exception from stack, throw it
  endTry,       // End try/catch/finally block
  
  // Widgets
  buildWidget, // [name_index, prop_count] -> properties are on stack
  
  // Module system
  import_,     // [path_index] -> load and execute module
  
  // Named calls
  callNamed,   // [pos_count, named_count] -> call with named arguments
  
  // Class system
  class_,      // [class_index] -> define class
  instance,    // [class_ref] -> create instance
  getProperty, // [name_index] -> get property from instance
  setProperty, // [name_index, value on stack] -> set property on instance
  invoke,      // [name_index, arg_count] -> invoke method on instance
}

/// A chunk of bytecode instructions and constants
class Chunk {
  final List<int> code = [];
  final List<Object?> constants = [];
  
  // RLE encoded lines: [count, line, count, line, ...]
  final List<int> lines = []; 

  void write(int byte, int line) {
    code.add(byte);
    
    if (lines.isEmpty) {
      lines.add(1);
      lines.add(line);
    } else {
      // Check if we can coalesce
      if (lines.last == line) {
        // Increment count (2nd to last element)
        lines[lines.length - 2]++;
      } else {
        lines.add(1);
        lines.add(line);
      }
    }
  }

  void writeOp(OpCode op, int line) {
    write(op.index, line);
  }

  int addConstant(Object? value) {
    constants.add(value);
    return constants.length - 1;
  }
  
  /// Get line number for a given bytecode offset
  int getLine(int offset) {
    int currentOffset = 0;
    for (int i = 0; i < lines.length; i += 2) {
      final count = lines[i];
      final line = lines[i+1];
      
      currentOffset += count;
      if (currentOffset > offset) {
        return line;
      }
    }
    return -1; // Should not happen if offset is valid
  }
}
