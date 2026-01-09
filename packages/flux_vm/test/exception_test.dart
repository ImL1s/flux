import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';

void main() {
  group('Exception Handling', () {
    test('Basic try-catch', () {
      const source = '''
        try {
          throw "error";
        } catch (e) {
          print("Caught: " + e);
        }
      ''';

      final logs = <String>[];

      final tokens = Lexer(source).tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      // verification of compilation is part of test
      final compiler = Compiler(unit: ast);
      final function = compiler.endCompiler();

      final vm = VM();
      vm.onPrint = (msg) => logs.add(msg);
      vm.runChunk(function.chunk);

      expect(logs[0], 'Caught: error');
    });
  });
}
