import 'package:flux_compiler/flux_compiler.dart';
import 'package:test/test.dart';

void main() {
  group('Lexer', () {
    test('tokenizes simple expression', () {
      final lexer = Lexer('1 + 2');
      final tokens = lexer.tokenize();
      expect(tokens.length, 4); // 1, +, 2, EOF
      expect(tokens[0].type, TokenType.integer);
      expect(tokens[1].type, TokenType.plus);
      expect(tokens[2].type, TokenType.integer);
      expect(tokens[3].type, TokenType.eof);
    });

    test('tokenizes keywords', () {
      final lexer = Lexer('let fn if else while');
      final tokens = lexer.tokenize();
      expect(tokens[0].type, TokenType.let_);
      expect(tokens[1].type, TokenType.fn);
      expect(tokens[2].type, TokenType.if_);
      expect(tokens[3].type, TokenType.else_);
      expect(tokens[4].type, TokenType.while_);
    });

    test('tokenizes string literal', () {
      final lexer = Lexer('"Hello, World!"');
      final tokens = lexer.tokenize();
      expect(tokens[0].type, TokenType.string);
      expect(tokens[0].literal, 'Hello, World!');
    });

    test('handles comments', () {
      final lexer = Lexer('1 // comment\n+ 2');
      final tokens = lexer.tokenize();
      expect(tokens.length, 4); // 1, +, 2, EOF (comment ignored)
    });

    test('tokenizes operators', () {
      final lexer = Lexer('== != <= >= && ||');
      final tokens = lexer.tokenize();
      expect(tokens[0].type, TokenType.equalEqual);
      expect(tokens[1].type, TokenType.notEqual);
      expect(tokens[2].type, TokenType.lessEqual);
      expect(tokens[3].type, TokenType.greaterEqual);
      expect(tokens[4].type, TokenType.and);
      expect(tokens[5].type, TokenType.or);
    });
  });

  group('Parser', () {
    test('parses variable declaration', () {
      final lexer = Lexer('let x = 5');
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      expect(ast, isA<CompilationUnit>());
      expect(ast.declarations.length, 1);
      expect(ast.declarations[0], isA<VarDeclStmt>());
    });

    test('parses function declaration', () {
      final lexer = Lexer('fn add(a, b) { }');
      final tokens = lexer.tokenize();
      expect(tokens.isNotEmpty, true);
      // Check we have fn keyword
      expect(tokens[0].type, TokenType.fn);
      expect(tokens[1].type, TokenType.identifier);
      expect(tokens[1].lexeme, 'add');
    });

    test('parses widget declaration', () {
      final lexer = Lexer('widget MyWidget { build { Text("Hello") } }');
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      expect(ast, isA<CompilationUnit>());
      expect(ast.declarations.length, 1);
      expect(ast.declarations[0], isA<WidgetDecl>());
    });

    test('parses if statement', () {
      final lexer = Lexer('if (true) { print("yes") }');
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      expect(ast, isA<CompilationUnit>());
      expect(ast.declarations[0], isA<IfStmt>());
    });

    test('parses while statement', () {
      final lexer = Lexer('while (true) { break }');
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      expect(ast, isA<CompilationUnit>());
    });

    test('parses local function declaration', () {
      final source = '''
        fn outer() {
          fn inner() {
            print("inner");
          }
          inner();
        }
      ''';
      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      expect(ast.declarations.length, 1);
      expect(ast.declarations[0], isA<FunctionDecl>());
    });
  });

  group('Compiler', () {
    test('compiles simple expression', () {
      final lexer = Lexer('let x = 1 + 2');
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final result = compiler.endCompiler();
      expect(result, isNotNull);
      expect(result.chunk.code.isNotEmpty, true);
    });

    test('compiles function', () {
      final source = 'fn add(a, b) { return a + b; }';
      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final result = compiler.endCompiler();
      expect(result, isNotNull);
    });

    test('generates bytecode', () {
      final source = 'print(42)';
      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final result = compiler.endCompiler();
      expect(result.chunk.code, isNotEmpty);
      // Should contain: constant, call, pop, nil, return
    });

    test('compiles closure with upvalue', () {
      final source = '''
        fn outer() {
          var x = "outside";
          fn inner() {
            print(x);
          }
          return inner;
        }
      ''';
      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final result = compiler.endCompiler();
      expect(result, isNotNull);
      // Verify closure opcode is in the generated code
      expect(result.chunk.code.contains(OpCode.closure.index), true);
    });

    test('compiles nested closures', () {
      final source = '''
        fn outer() {
          var a = "a";
          fn middle() {
            var b = "b";
            fn inner() {
              print(a + b);
            }
            return inner;
          }
          return middle;
        }
      ''';
      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final result = compiler.endCompiler();
      expect(result, isNotNull);
    });
  });
}
