import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:test/test.dart';

void main() {
  group('Lambda Expressions', () {
    late VM vm;
    late List<String> logs;

    setUp(() {
      vm = VM();
      logs = [];
      vm.onPrint = (msg) => logs.add(msg);
    });

    void runScript(String source) {
      final tokens = Lexer(source).tokenize();
      final ast = Parser(tokens).parse();
      final compiler = Compiler(unit: ast);
      final function = compiler.endCompiler();
      vm.runChunk(function.chunk);
    }

    test('basic anonymous function', () {
      // Flux uses 'fn' keyword, not arrow syntax
      runScript('''
        var double = fn (x) { return x * 2; };
        print(double(5));
      ''');
      expect(logs[0], '10');
    });

    test('anonymous function with multiple parameters', () {
      runScript('''
        var add = fn (a, b) { return a + b; };
        print(add(3, 7));
      ''');
      expect(logs[0], '10');
    });

    test('anonymous function captures variable (closure)', () {
      runScript('''
        var multiplier = 3;
        var triple = fn (x) { return x * multiplier; };
        print(triple(4));
      ''');
      expect(logs[0], '12');
    });

    test('anonymous function assigned and called later', () {
      runScript('''
        var f;
        var setup = fn () {
          var captured = "hello";
          f = fn () { 
            return captured; 
          };
          return null;
        };
        setup();
        print(f());
      ''');
      expect(logs[0], 'hello');
    });

    test('nested anonymous functions', () {
      runScript('''
        var outer = fn (x) {
          return fn (y) { return x + y; };
        };
        var inner = outer(10);
        print(inner(5));
      ''');
      expect(logs[0], '15');
    });

    test('anonymous function returning function (currying)', () {
      runScript('''
        var curry = fn (a) {
          return fn (b) {
            return fn (c) { return a + b + c; };
          };
        };
        print(curry(1)(2)(3));
      ''');
      expect(logs[0], '6');
    });
  });
}
