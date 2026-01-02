/// Comprehensive Parser Edge Case Tests
import 'package:test/test.dart';
import 'package:flux_compiler/flux_compiler.dart';

void main() {
  group('Parser Edge Cases', () {
    test('empty source', () {
      final tokens = Lexer('').tokenize();
      final ast = Parser(tokens).parse();
      expect(ast.declarations, isEmpty);
    });

    test('only comments', () {
      final tokens = Lexer('''
        // This is a comment
        // Another comment
      ''').tokenize();
      final ast = Parser(tokens).parse();
      expect(ast.declarations, isEmpty);
    });

    test('deeply nested parentheses (50 levels)', () {
      var expr = 'x';
      for (var i = 0; i < 50; i++) {
        expr = '($expr)';
      }
      final source = 'var result = $expr;';
      final tokens = Lexer(source).tokenize();
      expect(() => Parser(tokens).parse(), returnsNormally);
    });

    test('deeply nested blocks (30 levels)', () {
      var code = 'var x = 1;';
      for (var i = 0; i < 30; i++) {
        code = '{ $code }';
      }
      final tokens = Lexer(code).tokenize();
      expect(() => Parser(tokens).parse(), returnsNormally);
    });

    test('very long identifier', () {
      final longName = 'a' * 1000;
      final source = 'var $longName = 42;';
      final tokens = Lexer(source).tokenize();
      final ast = Parser(tokens).parse();
      expect(ast.declarations.length, 1);
    });

    test('unicode strings', () {
      final source = '''
        var emoji = "🎉🚀✨";
        var chinese = "你好世界";
        var arabic = "مرحبا";
      ''';
      final tokens = Lexer(source).tokenize();
      final ast = Parser(tokens).parse();
      expect(ast.declarations.length, 3);
    });

    test('multiline string with escapes', () {
      final source = r'''
        var s = "line1\nline2\tline3\\end";
      ''';
      final tokens = Lexer(source).tokenize();
      expect(() => Parser(tokens).parse(), returnsNormally);
    });

    test('chained method calls (20+)', () {
      final source = '''
        var obj = builder()
          .step1()
          .step2()
          .step3()
          .step4()
          .step5()
          .step6()
          .step7()
          .step8()
          .step9()
          .step10()
          .step11()
          .step12()
          .step13()
          .step14()
          .step15()
          .step16()
          .step17()
          .step18()
          .step19()
          .step20()
          .build();
      ''';
      final tokens = Lexer(source).tokenize();
      expect(() => Parser(tokens).parse(), returnsNormally);
    });

    test('complex nested ternary-like expressions', () {
      // Using && and || for conditional logic
      final source = '''
        var result = (a > 0 && (b > 0 && (c > 0 || d > 0))) || e > 0;
      ''';
      final tokens = Lexer(source).tokenize();
      expect(() => Parser(tokens).parse(), returnsNormally);
    });

    test('function with many parameters (20+)', () {
      final params = List.generate(25, (i) => 'arg$i').join(', ');
      final source = 'fn manyArgs($params) { return nil; }';
      final tokens = Lexer(source).tokenize();
      expect(() => Parser(tokens).parse(), returnsNormally);
    });

    test('list with 100 elements', () {
      final elements = List.generate(100, (i) => i).join(', ');
      final source = 'var list = [$elements];';
      final tokens = Lexer(source).tokenize();
      expect(() => Parser(tokens).parse(), returnsNormally);
    });

    test('map with 50 key-value pairs', () {
      final pairs = List.generate(50, (i) => '"key$i": $i').join(', ');
      final source = 'var map = {$pairs};';
      final tokens = Lexer(source).tokenize();
      expect(() => Parser(tokens).parse(), returnsNormally);
    });

    test('error recovery - missing semicolon', () {
      final source = '''
        var x = 1
        var y = 2;
      ''';
      final tokens = Lexer(source).tokenize();
      // Should not crash, may have partial parse
      expect(() => Parser(tokens).parse(), returnsNormally);
    });

    test('consecutive operators', () {
      final source = 'var x = 1 + + 2;';
      final tokens = Lexer(source).tokenize();
      // May fail to parse but should not crash
      expect(() => Parser(tokens).parse(), returnsNormally);
    });
  });
}
