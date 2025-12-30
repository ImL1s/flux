import 'package:test/test.dart';

import 'package:flux_compiler/flux_compiler.dart';
import 'helpers/ast_printer.dart';
import 'helpers/bytecode_printer.dart';

void main() {
  group('AST Golden Tests', () {
    test('basic structure', () {
      final source = '''
        fn main() {
          var a = 1 + 2;
          print(a);
        }
      ''';
      final ast = _parse(source);
      final output = AstPrinter().print(ast);
      
      final expected = '''
CompilationUnit
  FunctionDecl(main)
    Params: 
    Body:
      VarDeclStmt(a)
        BinaryExpr(+)
          LiteralExpr(1)
          LiteralExpr(2)
      ExpressionStmt
        CallExpr
          Callee:
            VariableExpr(print)
          Args:
            VariableExpr(a)
''';
      // trim to ignore whitespace diffs
      expect(output.trim(), equals(expected.trim()));
    });
    
    test('class definitions', () {
      final source = '''
        class Foo {
          fn bar() {}
        }
      ''';
      final ast = _parse(source);
      final output = AstPrinter().print(ast);
       final expected = '''
CompilationUnit
  ClassDecl(Foo)
    FunctionDecl(bar)
      Params: 
      Body:
''';
       expect(output.trim(), equals(expected.trim()));
    });
    
    test('import statement', () {
      final source = 'import "foo.flux";';
      final ast = _parse(source);
      final output = AstPrinter().print(ast);
      
      expect(output.trim(), contains('ImportDecl(foo.flux)'));
    });
    
    test('error recovery', () {
      try {
        // This source has a syntax error (invalid expression) but should recover
        // and parse the next statement.
        final source = '''
          var a = 1 + ;
          var b = 2;
        ''';
        
        final lexer = Lexer(source);
        final tokens = lexer.tokenize();
        final parser = Parser(tokens);
        final ast = parser.parse();
        
        // Should have reported an error
        expect(parser.errors, isNotEmpty, reason: "Parser should have errors");
        
        // Should have synchronized and parsed the second declaration
        final output = AstPrinter().print(ast);
        expect(output, contains('VarDeclStmt(b)'));
      } catch (e, st) {
        print("Test Exception: $e");
        print(st);
        rethrow;
      }
    });
  });

  group('Bytecode Golden Tests', () {
    test('basic arithmetic', () {
      final source = 'print(1 + 2);';
      final chunk = _compile(source);
      final output = BytecodePrinter().print(chunk);
      
      // Expected bytecode check
      // Constants: 0: 1, 1: 2
      expect(output, contains("0: 1"));
      expect(output, contains("1: 2"));
      // Opcodes: constant, constant, add, print
      expect(output, contains("constant"));
      expect(output, contains("add"));
      expect(output, contains("print"));
    });
    
    test('if statement with jump', () {
      final source = 'if (true) { print(1); }';
      final chunk = _compile(source);
      final output = BytecodePrinter().print(chunk);
      
      expect(output, contains("jumpIfFalse"));
    });

    
    test('function call', () {
      final source = '''
        fn foo() {}
        foo();
      ''';
      final chunk = _compile(source);
      final output = BytecodePrinter().print(chunk);
      
      expect(output, contains("call"));
    });
  });

  group('BytecodePrinter Unit Test', () {
    test('prints call opcode', () {
      final chunk = Chunk();
      // add constant (optional, not needed for call)
      // emit CALL with 0 args
      chunk.write(OpCode.call.index, 1);
      chunk.write(0, 1); // arg count
      
      final output = BytecodePrinter().print(chunk);
      print("Manual Chunk Output:\n$output");
      expect(output, contains("call"));
      expect(output, contains(" 0")); // arg count
    });
  });
}

Chunk _compile(String source) {
  final lexer = Lexer(source);
  final tokens = lexer.tokenize();
  final parser = Parser(tokens);
  final ast = parser.parse();
  final compiler = Compiler(unit: ast);
  return compiler.endCompiler().chunk;
}

CompilationUnit _parse(String source) {
  final lexer = Lexer(source);
  final tokens = lexer.tokenize();
  final parser = Parser(tokens);
  return parser.parse();
}
