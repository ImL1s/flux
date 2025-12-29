import 'package:flux_compiler/flux_compiler.dart';

/// Helper to print Bytecode structure for golden tests
class BytecodePrinter {
  String print(Chunk chunk) {
    final sb = StringBuffer();
    sb.writeln("== Constants ==");
    for (var i = 0; i < chunk.constants.length; i++) {
        sb.writeln("$i: ${chunk.constants[i]}");
    }
    sb.writeln("== Code ==");
    
    int offset = 0;
    while (offset < chunk.code.length) {
      final op = OpCode.values[chunk.code[offset]];
      sb.write("${offset.toString().padLeft(4, '0')} ${op.name.padRight(12)}");
      offset++;
      
      switch (op) {
        case OpCode.constant:
        case OpCode.getGlobal:
        case OpCode.setGlobal:
        case OpCode.defineState:
        case OpCode.getState:
        case OpCode.setState:
        case OpCode.getProperty:
        case OpCode.setProperty:
        case OpCode.invoke:
        case OpCode.class_:
          final constantIndex = chunk.code[offset];
          sb.write(" $constantIndex ('${chunk.constants[constantIndex]}')");
          offset++;
          // handle extra args for some ops?
          if (op == OpCode.invoke) { // [name_index, arg_count]
             final argCount = chunk.code[offset];
             sb.write(" args: $argCount");
             offset++;
          }
          break;
        case OpCode.getLocal:
        case OpCode.setLocal:
        case OpCode.popScope:
        case OpCode.call:
        case OpCode.newList:
        case OpCode.newMap:
          final slot = chunk.code[offset];
          sb.write(" $slot");
          offset++;
          break;
        case OpCode.jump:
        case OpCode.jumpIfFalse:
        case OpCode.loop:
          // 2-byte operand
          final high = chunk.code[offset];
          final low = chunk.code[offset + 1];
          final jump = (high << 8) | low;
          sb.write(" $jump");
          offset += 2;
          break;
        case OpCode.closure:
           final funcIndex = chunk.code[offset];
           sb.write(" $funcIndex ('${chunk.constants[funcIndex]}')");
           offset++;
           
           // Read upvalue count
           final upvalueCount = chunk.code[offset];
           // sb.write(" upvalues: $upvalueCount"); // Optional: don't clutter golden output if not needed
           offset++;
           
           // Skip upvalues (2 bytes each: isLocal, index)
           offset += 2 * upvalueCount;
           break;
        default:
          break;
      }
      sb.writeln();
    }
    
    return sb.toString();
  }
}
