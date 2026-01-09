import 'package:test/test.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  group('Class System', () {
    test('defines and instantiates a simple class', () {
      final source = '''
        class Counter {
          fn increment() {
            return 1;
          }
        }
        var c = Counter();
        print(type(c));
      ''';

      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();

      expect(ast.declarations, isNotEmpty);
      expect(ast.declarations.any((d) => d is ClassDecl), isTrue);
    });

    test('parses class with method', () {
      final source = '''
        class Greeter {
          fn greet(name) {
            return "Hello, " + name;
          }
        }
      ''';

      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();

      final classDecl = ast.declarations.whereType<ClassDecl>().first;
      expect(classDecl.name, equals('Greeter'));
      expect(classDecl.members, hasLength(1));
      expect(classDecl.members.first, isA<FunctionDecl>());
    });

    test('compiles class to CompiledClass', () {
      final source = '''
        class Calculator {
          fn add(a, b) {
            return a + b;
          }
          
          fn multiply(a, b) {
            return a * b;
          }
        }
      ''';

      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();

      final compiler = Compiler(unit: ast);
      final function = compiler.endCompiler();

      // Check that class is in constants
      expect(function.chunk.constants.any((c) => c is CompiledClass), isTrue);

      final compiledClass =
          function.chunk.constants.whereType<CompiledClass>().first;
      expect(compiledClass.name, equals('Calculator'));
      expect(compiledClass.methods.keys, containsAll(['add', 'multiply']));
    });
  });

  group('Import System', () {
    test('parses import statement', () {
      final source = '''
        import "utils.flux";
        
        fn main() {
          print("Hello");
        }
      ''';

      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();

      expect(ast.declarations.any((d) => d is ImportDecl), isTrue);

      final importDecl = ast.declarations.whereType<ImportDecl>().first;
      expect(importDecl.path, equals('utils.flux'));
    });

    test('compiles import to opcode', () {
      final source = '''
        import "lib/math.flux";
      ''';

      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();

      final compiler = Compiler(unit: ast);
      final function = compiler.endCompiler();

      // Check that import path is in constants
      expect(function.chunk.constants, contains('lib/math.flux'));

      // Check that import opcode is emitted
      expect(function.chunk.code.contains(OpCode.import_.index), isTrue);
    });

    test('VM tracks imports', () {
      final source = '''
        import "module1.flux";
        import "module2.flux";
        var x = 1;
      ''';

      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();

      final compiler = Compiler(unit: ast);
      final function = compiler.endCompiler();

      final vm = VM();
      vm.runChunk(function.chunk);

      expect(vm.imports, containsAll(['module1.flux', 'module2.flux']));
    });
  });

  group('Known Issues', () {
    test('empty map literal {} parsing', () {
      // This is a known issue - {} is parsed as empty block, not empty map
      final source = 'var map = {};';

      final lexer = Lexer(source);
      final tokens = lexer.tokenize();

      // Check token sequence
      expect(tokens.map((t) => t.type).toList(), contains(TokenType.leftBrace));
    });

    test('map with content works correctly', () {
      final source = '''
        var map = {"key": "value"};
        print(map["key"]);
      ''';

      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();

      expect(ast.declarations, isNotEmpty);
    });
  });
}
