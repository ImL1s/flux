import 'package:flux_compiler/flux_compiler.dart';

void main() {
  const source = '''
    widget Counter {
      state count = 0;
      build {
        Column(children: [
          Text("Count: " + count),
          Button(text: "Increment", onPressed: fn() {
            count = count + 1;
          })
        ])
      }
    }
  ''';

  try {
    // 1. Parse the source using the Lexer and Parser
    final parser = Parser(Lexer(source).tokenize());
    final unit = parser.parse();

    print('Successfully parsed with declarations.');

    // 2. Compile AST to Bytecode
    final compiler = Compiler(unit: unit);
    final bytecode = compiler.chunk.code;

    print('Successfully compiled to bytecode (${bytecode.length} bytes).');
    print('First 10 bytes: ${bytecode.take(10).toList()}');

  } catch (e) {
    print('Error: $e');
  }
}
