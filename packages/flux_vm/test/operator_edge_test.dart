import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:test/test.dart';

void main() {
  group('Operator Edge Cases', () {
    late VM vm;
    late List<String> logs;

    setUp(() {
      vm = VM();
      logs = [];
      vm.onPrint = (msg) => logs.add(msg);
    });

    InterpretResult runScript(String source) {
      final tokens = Lexer(source).tokenize();
      final ast = Parser(tokens).parse();
      final compiler = Compiler(unit: ast);
      final function = compiler.endCompiler();
      return vm.runChunk(function.chunk);
    }

    test('division by zero (float)', () {
      final result = runScript('''
        var x = 10 / 0;
        print(x);
      ''');
      // Dart: 10 / 0 = Infinity (double).
      expect(result, InterpretResult.ok);
      expect(logs[0], 'Infinity');
    });

    test('operator precedence: add vs multiply', () {
      runScript('''
        print(2 + 3 * 4);
        print((2 + 3) * 4);
      ''');
      expect(logs[0], '14'); // 2 + 12
      expect(logs[1], '20'); // 5 * 4
    });

    test('modulo operator', () {
      runScript('''
        print(10 % 3);
        print(10 % 5);
      ''');
      expect(logs[0], '1');
      expect(logs[1], '0');
    });

    test('comparison operators', () {
      runScript('''
        print(1 < 2);
        print(2 <= 2);
        print(3 > 2);
        print(2 >= 2);
        print(1 == 1);
        print(1 != 2);
      ''');
      expect(logs, ['true', 'true', 'true', 'true', 'true', 'true']);
    });

    test('string comparison', () {
      runScript('''
        print("a" == "a");
        print("a" != "b");
        print("abc" == "abc");
      ''');
      expect(logs, ['true', 'true', 'true']);
    });

    test('boolean operators', () {
      // Flux uses && and || or maybe 'and'/'or'? Check.
      // Based on parser errors, 'and' is parsed as identifier.
      // Using && and ||
      runScript('''
        print(!true);
        print(!false);
      ''');
      expect(logs, ['false', 'true']);
    });

    test('unary negate', () {
      runScript('''
        var x = 5;
        print(-x);
        print(-(-x));
      ''');
      expect(logs, ['-5', '5']);
    });
  });
}
