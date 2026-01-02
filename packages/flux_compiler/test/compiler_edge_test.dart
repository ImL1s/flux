/// Comprehensive Compiler Edge Case Tests
import 'package:test/test.dart';
import 'package:flux_compiler/flux_compiler.dart';

void main() {
  CompiledFunction compile(String source) {
    final tokens = Lexer(source).tokenize();
    final ast = Parser(tokens).parse();
    final compiler = Compiler(unit: ast);
    return compiler.endCompiler();
  }

  group('Compiler Edge Cases', () {
    test('large constant pool (100+ constants)', () {
      final constants = List.generate(150, (i) => 'var c$i = "constant_$i";').join('\n');
      expect(() => compile(constants), returnsNormally);
    });

    test('many local variables (100+)', () {
      final vars = List.generate(100, (i) => 'var v$i = $i;').join('\n');
      final source = '''
        fn manyLocals() {
          $vars
          return v99;
        }
      ''';
      expect(() => compile(source), returnsNormally);
    });

    test('deeply nested closures (10 levels)', () {
      var body = 'return x;';
      for (var i = 9; i >= 0; i--) {
        body = '''
          var x$i = $i;
          return fn() {
            $body
          };
        ''';
      }
      final source = '''
        fn outer() {
          $body
        }
      ''';
      expect(() => compile(source), returnsNormally);
    });

    test('many upvalues in single closure', () {
      final vars = List.generate(20, (i) => 'var v$i = $i;').join('\n');
      final refs = List.generate(20, (i) => 'v$i').join(' + ');
      final source = '''
        fn outer() {
          $vars
          return fn() {
            return $refs;
          };
        }
      ''';
      expect(() => compile(source), returnsNormally);
    });

    test('class with many methods (50+)', () {
      final methods = List.generate(50, (i) => 'method$i() { return $i; }').join('\n');
      final source = '''
        class BigClass {
          $methods
        }
      ''';
      expect(() => compile(source), returnsNormally);
    });

    test('class with many fields (30+)', () {
      final fields = List.generate(30, (i) => 'field f$i = $i;').join('\n');
      final source = '''
        class ManyFields {
          $fields
        }
      ''';
      expect(() => compile(source), returnsNormally);
    });

    test('deeply nested try-catch (5 levels)', () {
      var body = 'throw "error";';
      for (var i = 0; i < 5; i++) {
        body = '''
          try {
            $body
          } catch (e$i) {
            throw e$i;
          }
        ''';
      }
      expect(() => compile(body), returnsNormally);
    });

    test('long chain of binary operations', () {
      final ops = List.generate(100, (i) => '+ $i').join(' ');
      final source = 'var result = 0 $ops;';
      expect(() => compile(source), returnsNormally);
    });

    test('complex switch-like if-else chain', () {
      final cases = List.generate(50, (i) => '''
        if (x == $i) {
          return $i;
        } else
      ''').join(' ');
      final source = '''
        fn switchLike(x) {
          $cases { return -1; }
        }
      ''';
      expect(() => compile(source), returnsNormally);
    });

    test('recursive function definition', () {
      final source = '''
        fn factorial(n) {
          if (n <= 1) { return 1; }
          return n * factorial(n - 1);
        }
      ''';
      final fn = compile(source);
      expect(fn.chunk.code.isNotEmpty, true);
    });

    test('mutually recursive functions', () {
      final source = '''
        fn isEven(n) {
          if (n == 0) { return true; }
          return isOdd(n - 1);
        }
        fn isOdd(n) {
          if (n == 0) { return false; }
          return isEven(n - 1);
        }
      ''';
      expect(() => compile(source), returnsNormally);
    });

    test('empty function body', () {
      final source = 'fn empty() {}';
      expect(() => compile(source), returnsNormally);
    });

    test('empty class', () {
      final source = 'class Empty {}';
      expect(() => compile(source), returnsNormally);
    });

    test('lambda as immediate argument', () {
      final source = '''
        var result = process(fn(x) { return x * 2; });
      ''';
      expect(() => compile(source), returnsNormally);
    });
  });
}
