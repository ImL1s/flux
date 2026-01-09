import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';

void main() {
  group('Recursion and Limits', () {
    late VM vm;

    setUp(() {
      vm = VM();
    });

    void runScript(String source,
        {InterpretResult expectedResult = InterpretResult.ok}) {
      final tokens = Lexer(source).tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final function = compiler.endCompiler();
      final result = vm.runChunk(function.chunk);
      expect(result, expectedResult);
    }

    test('Recursion within limits succeeds', () {
      const source = '''
        fn factorial(n) {
           if (n <= 1) return 1;
           return n * factorial(n - 1);
        }
        var res = factorial(5);
        if (res != 120) throw "Incorrect factorial: " + toString(res);
      ''';
      runScript(source);
    });

    test('Deep recursion triggers Stack Overflow', () {
      // framesMax is 64 in vm.dart. A recursion depth of 100 should strictly fail.
      const source = '''
        fn diverge(n) {
           return diverge(n + 1);
        }
        diverge(0);
      ''';

      // We expect a runtime error due to stack overflow
      runScript(source, expectedResult: InterpretResult.runtimeError);
    });

    test('Return from deep stack works', () {
      // Test that we can return from a moderately deep stack (e.g. 50, < 64)
      // successfully back to top level.
      const source = '''
         fn deep(n) {
            if (n == 0) return "done";
            return deep(n - 1);
         }
         var r = deep(50);
         if (r != "done") throw "Failed to return from deep stack";
      ''';
      runScript(source);
    });
  });
}
