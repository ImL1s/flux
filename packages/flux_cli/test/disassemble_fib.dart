import 'package:flux_compiler/flux_compiler.dart';

void main() {
  final source = '''
    fn fib(n) {
      if (n <= 1) { return n; }
      return fib(n - 1) + fib(n - 2);
    }
  ''';

  final scanner = Lexer(source);
  final parser = Parser(scanner.tokenize());
  final compiler = Compiler(unit: parser.parse());
  final function = compiler.endCompiler();

  print('Main Chunk:');
  printChunk(function.chunk);

  // Find fib function in constants
  for (final constant in function.chunk.constants) {
    if (constant is CompiledFunction) {
      print('\nFunction ${constant.name}:');
      printChunk(constant.chunk);
    }
  }
}

void printChunk(Chunk chunk) {
  int offset = 0;
  while (offset < chunk.code.length) {
    final op = OpCode.values[chunk.code[offset]];
    print('$offset: ${op.name}');

    // Simple operand handling for relevant opcodes
    if (op == OpCode.getLocal) {
      print('  slot: ${chunk.code[offset + 1]}');
      offset += 2;
    } else if (op == OpCode.constant) {
      print('  const: ${chunk.constants[chunk.code[offset + 1]]}');
      offset += 2;
    } else if (op == OpCode.jumpIfFalse || op == OpCode.jump) {
      offset += 3;
    } else if (op == OpCode.call) {
      offset += 2;
    } else if (op == OpCode.lessEqual) {
      offset += 1;
    } else {
      offset += 1; // Assume 1 byte for others
    }
  }
}
