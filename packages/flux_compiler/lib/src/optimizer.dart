import 'package:flux_compiler/src/bytecode.dart';

/// Bytecode optimizer for Flux language
class BytecodeOptimizer {
  /// Optimize a chunk by performing constant folding and other optimizations
  static void optimize(Chunk chunk) {
    bool modified = true;
    while (modified) {
      bool constModified = _foldConstants(chunk);
      bool peepModified = _optimizePeephole(chunk);
      bool dceModified = _eliminateDeadCode(chunk);
      modified = constModified || peepModified || dceModified;
    }
  }

  /// Perform dead code elimination
  static bool _eliminateDeadCode(Chunk chunk) {
    if (chunk.code.isEmpty) return false;

    // Pass 1: Identify targets of jumps
    final targets = <int>{0}; // Entry point is always reachable
    int i = 0;
    while (i < chunk.code.length) {
      final op = OpCode.values[chunk.code[i]];
      
      switch (op) {
        case OpCode.jump:
        case OpCode.jumpIfFalse:
        case OpCode.jumpIfTrue:
          // offset is 2 bytes at i+1
          if (i + 2 < chunk.code.length) {
             int offset = chunk.code[i + 1] | (chunk.code[i + 2] << 8);
             int target = i + 3 + offset;
             if (target < chunk.code.length) targets.add(target);
          }
          break;
        case OpCode.loop:
          // Loop jumps backwards.
          // offset is 1 byte at i+1
           if (i + 1 < chunk.code.length) {
             int offset = chunk.code[i + 1];
             int target = i + 2 - offset;
             if (target >= 0) targets.add(target);
          }
          break;
        case OpCode.try_:
          // try_ has 2 uint16 absolute addresses at i+1 and i+3
          if (i + 4 < chunk.code.length) {
            int catchAddr = chunk.code[i + 1] | (chunk.code[i + 2] << 8);
            int finallyAddr = chunk.code[i + 3] | (chunk.code[i + 4] << 8);
            if (catchAddr < chunk.code.length) targets.add(catchAddr);
            if (finallyAddr < chunk.code.length) targets.add(finallyAddr);
          }
          break;
        default:
          break;
      }
      i += _getInstructionSize(chunk, i);
    }
    
    // Pass 2: Mark reachability and eliminate dead code
    bool modified = false;
    bool isReachable = true;
    i = 0;
    
    while (i < chunk.code.length) {
      // If this instruction is a jump target, it becomes reachable
      if (targets.contains(i)) {
        isReachable = true;
      }
      
      final op = OpCode.values[chunk.code[i]];
      final size = _getInstructionSize(chunk, i);
      
      if (!isReachable && op != OpCode.noOp) {
        // Replace with NO_OPs
        for (int k = 0; k < size; k++) {
          chunk.code[i + k] = OpCode.noOp.index;
        }
        modified = true;
      }
      
      if (isReachable) {
        // Check if this instruction terminates the flow
        if (op == OpCode.return_ || 
          op == OpCode.throw_ || 
          op == OpCode.jump ||
          op == OpCode.loop) { // Unconditional jump
         isReachable = false;
      }
      }
      
      i += size;
    }
    
    return modified;
  }

  /// Perform peephole optimization
  /// Returns true if any changes were made.
  static bool _optimizePeephole(Chunk chunk) {
    bool modified = false;
    int i = 0;
    while (i < chunk.code.length) {
      final op = OpCode.values[chunk.code[i]];
      
      // Pattern: NOT + JUMP_IF_FALSE -> NOOP + JUMP_IF_TRUE
    // Pattern: NOT + JUMP_IF_TRUE -> NOOP + JUMP_IF_FALSE
    // Pattern: NOT + NOT -> NOOP + NOOP
    if (op == OpCode.not) {
      int next = _peekNextInstruction(chunk, i);
      if (next < chunk.code.length) {
        final nextOp = OpCode.values[chunk.code[next]];
        if (nextOp == OpCode.jumpIfFalse) {
          chunk.code[i] = OpCode.noOp.index;
          chunk.code[next] = OpCode.jumpIfTrue.index;
          modified = true;
        } else if (nextOp == OpCode.jumpIfTrue) {
          chunk.code[i] = OpCode.noOp.index;
          chunk.code[next] = OpCode.jumpIfFalse.index;
          modified = true;
        } else if (nextOp == OpCode.not) {
          chunk.code[i] = OpCode.noOp.index;
          chunk.code[next] = OpCode.noOp.index;
          modified = true;
        }
      }
    }

    // Pattern: SIDE_EFFECT_FREE + POP -> NOOP + NOOP
    if (_isSideEffectFree(op)) {
       int next = _peekNextInstruction(chunk, i);
       if (next < chunk.code.length && OpCode.values[chunk.code[next]] == OpCode.pop) {
          final sizeCurrent = _getInstructionSize(chunk, i);
          final sizeNext = _getInstructionSize(chunk, next);
          
          for(int k=0; k<sizeCurrent; k++) chunk.code[i+k] = OpCode.noOp.index;
          for(int k=0; k<sizeNext; k++) chunk.code[next+k] = OpCode.noOp.index;
          modified = true;
       }
    }
    
    i += _getInstructionSize(chunk, i);
  }
  return modified;
}

static bool _isSideEffectFree(OpCode op) {
  switch (op) {
    case OpCode.constant:
    case OpCode.nil:
    case OpCode.true_:
    case OpCode.false_:
    case OpCode.getLocal:
    case OpCode.getUpvalue:
    case OpCode.getGlobal:
    case OpCode.noOp:
      return true;
    default:
      return false;
  }
}

  /// Perform constant folding on the chunk
  static bool _foldConstants(Chunk chunk) {
    bool modified = false;
    int i = 0;
    while (i < chunk.code.length) {
      final op = OpCode.values[chunk.code[i]];
      
      if (op == OpCode.noOp) {
         i += _getInstructionSize(chunk, i);
         continue;
      }
      
      if (op == OpCode.constant) {
        final pattern = _matchConstantFolding(chunk, i);
        if (pattern != null) {
          _applyConstantFolding(chunk, i, pattern);
          modified = true;
        }
      }
      
      i += _getInstructionSize(chunk, i);
    }
    return modified;
  }
  
  static int _getInstructionSize(Chunk chunk, int offset) {
    if (offset >= chunk.code.length) return 0;
    
    final op = OpCode.values[chunk.code[offset]];
    
    switch (op) {
      // 1-byte instructions (no args)
      case OpCode.nil:
      case OpCode.true_:
      case OpCode.false_:
      case OpCode.pop:
      case OpCode.noOp:
      case OpCode.add:
      case OpCode.sub:
      case OpCode.mul:
      case OpCode.div:
      case OpCode.mod:
      case OpCode.negate:
      case OpCode.not:
      case OpCode.equal:
      case OpCode.greater:
      case OpCode.less:
      case OpCode.greaterEqual:
      case OpCode.lessEqual:
      case OpCode.print:
      case OpCode.popScope: 
      case OpCode.listGet:
      case OpCode.listSet:
      case OpCode.mapGet:
      case OpCode.mapSet:
      case OpCode.getIndex:
      case OpCode.setIndex:
      case OpCode.catch_:
      case OpCode.throw_: 
      case OpCode.endTry:
      case OpCode.return_:
      case OpCode.closeUpvalue:
      case OpCode.await_:
        return 1;
        
      // 2-byte instructions (1 arg)
      case OpCode.constant:
      case OpCode.getLocal:
      case OpCode.setLocal:
      case OpCode.getGlobal:
      case OpCode.setGlobal:
      case OpCode.getUpvalue:
      case OpCode.setUpvalue:
      case OpCode.call: 
      case OpCode.defineState:
      case OpCode.getState:
      case OpCode.setState:
      case OpCode.newList:
      case OpCode.newMap:
      case OpCode.import_:
      case OpCode.class_:
      case OpCode.instance:
      case OpCode.getProperty:
      case OpCode.setProperty:
         return 2;

      // 3-byte instructions (2 args or 1 uint16 arg)
      case OpCode.jump:
      case OpCode.jumpIfFalse:
      case OpCode.jumpIfTrue:
         return 3; 

      case OpCode.loop:
         return 2;

      case OpCode.invoke: 
      case OpCode.invokeSuper:
      case OpCode.callNamed: 
      case OpCode.buildWidget: 
         return 3;
         
      // 5-byte instructions (2 uint16 args)
      case OpCode.try_: 
         return 5;
         
      // Variable length
      case OpCode.closure:
        if (offset + 2 >= chunk.code.length) return 1; 
        final upvalueCount = chunk.code[offset + 2];
        return 3 + (2 * upvalueCount);
        
      default:
        return 1; 
    }
  }

  static int _peekNextInstruction(Chunk chunk, int offset) {
    int next = offset + _getInstructionSize(chunk, offset);
    while (next < chunk.code.length) {
       if (OpCode.values[chunk.code[next]] != OpCode.noOp) {
         return next;
       }
       next += _getInstructionSize(chunk, next);
    }
    return next;
  }

  static _FoldingPattern? _matchConstantFolding(Chunk chunk, int offset) {
    final constIdx1 = chunk.code[offset + 1];
    final val1 = chunk.constants[constIdx1];

    int offset2 = _peekNextInstruction(chunk, offset);
    if (offset2 >= chunk.code.length) return null;
    final op2 = OpCode.values[chunk.code[offset2]];

    // --- Unary Folding ---
    if (op2 == OpCode.negate || op2 == OpCode.not) {
      Object? result;
      if (op2 == OpCode.negate && val1 is num) {
        result = -val1;
      } else if (op2 == OpCode.not && val1 is bool) {
        result = !val1;
      }

      if (result != null) {
        return _FoldingPattern(result, [offset2]);
      }
      return null;
    }

    // --- Binary Folding ---
    if (op2 != OpCode.constant) return null;

    final constIdx2 = chunk.code[offset2 + 1];
    final val2 = chunk.constants[constIdx2];

    int offset3 = _peekNextInstruction(chunk, offset2);
    if (offset3 >= chunk.code.length) return null;

    final op3Byte = chunk.code[offset3];
    final op3 = OpCode.values[op3Byte];

    Object? result;
    if (val1 is num && val2 is num) {
      switch (op3) {
        case OpCode.add: result = val1 + val2; break;
        case OpCode.sub: result = val1 - val2; break;
        case OpCode.mul: result = val1 * val2; break;
        case OpCode.div: result = val1 / val2; break;
        case OpCode.mod: result = val1 % val2; break;
        case OpCode.equal: result = val1 == val2; break;
        case OpCode.greater: result = val1 > val2; break;
        case OpCode.less: result = val1 < val2; break;
        case OpCode.greaterEqual: result = val1 >= val2; break;
        case OpCode.lessEqual: result = val1 <= val2; break;
        default: return null;
      }
    } else if (val1 is String || val2 is String) {
      if (op3 == OpCode.add) {
        result = val1.toString() + val2.toString();
      } else if (op3 == OpCode.equal) {
        result = val1 == val2;
      } else {
        return null;
      }
    } else if (val1 is bool && val2 is bool) {
      if (op3 == OpCode.equal) result = val1 == val2;
      else return null;
    } else if (val1 == null || val2 == null) {
      if (op3 == OpCode.equal) {
        result = val1 == val2;
      } else {
        return null;
      }
    } else {
      return null;
    }

    if (result != null || (val1 == null && val2 == null && op3 == OpCode.equal)) {
      result ??= (val1 == val2); // Handle explicit null == null
      return _FoldingPattern(result, [offset2, offset3]);
    }

    return null;
  }

  static void _applyConstantFolding(Chunk chunk, int offset, _FoldingPattern pattern) {
    int newConstIdx = chunk.addConstant(pattern.result);
    // Replace original constant index
    chunk.code[offset + 1] = newConstIdx;

    // No-op the rest of the pattern
    for (final startOffset in pattern.noOpOffsets) {
      final size = _getInstructionSize(chunk, startOffset);
      for (int k = 0; k < size; k++) {
        chunk.code[startOffset + k] = OpCode.noOp.index;
      }
    }
  }
}

class _FoldingPattern {
  final Object? result;
  final List<int> noOpOffsets; // Start offsets of instructions to no-op

  _FoldingPattern(this.result, this.noOpOffsets);
}
