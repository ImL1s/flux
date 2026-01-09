import 'package:flux_compiler/src/compiler.dart';
import 'package:flux_compiler/src/lexer.dart';
import 'package:flux_compiler/src/parser.dart';
import 'package:flux_compiler/src/bytecode.dart';
import 'package:test/test.dart';

bool _checkForStateOpcodes(Chunk chunk) {
  bool hasSetState = chunk.code.contains(OpCode.setState.index);
  bool hasGetState = chunk.code.contains(OpCode.getState.index);

  if (hasSetState && hasGetState) {
    return true;
  }

  // Recursively check nested functions
  for (final constant in chunk.constants) {
    if (constant is CompiledFunction) {
      if (_checkForStateOpcodes(constant.chunk)) {
        return true;
      }
    }
  }
  return false;
}

void main() {
  test('Widget state access compiles to getState/setState', () {
    final source = """
      widget TestWidget {
        state count = 0;
        
        build {
          Button("Increment", onPressed: fn() {
            count = count + 1;
          })
        }
      }
    """;

    final lexer = Lexer(source);
    final parser = Parser(lexer.tokenize());
    final ast = parser.parse();
    final compiler = Compiler(unit: ast);

    final scriptFunc = compiler.endCompiler();

    bool found = false;
    for (final constant in scriptFunc.chunk.constants) {
      if (constant is CompiledWidget) {
        final widget = constant;
        final buildMethod = widget.buildMethod;

        // Check buildMethod and its nested lambdas
        if (_checkForStateOpcodes(buildMethod.chunk)) {
          found = true;
        } else {
          print("Missing opcodes in widget build or nested functions");
        }
      }
    }

    expect(found, isTrue,
        reason: "CompiledWidget not found or missing opcodes");
  });
}
