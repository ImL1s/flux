import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';

void main() {
  group('List Operations', () {
    test('List concatenation', () {
      const source = '''
        var a = [1, 2];
        var b = [3, 4];
        var c = a + b;
        print(c);
      ''';
      
      final logs = <String>[];
      
      final tokens = Lexer(source).tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final function = compiler.endCompiler();
      
      final vm = VM();
      vm.onPrint = (msg) => logs.add(msg);
      vm.runChunk(function.chunk);
      
      expect(logs.length, 1);
      expect(logs[0], '[1, 2, 3, 4]');
    });

    test('Empty list concatenation', () {
      const source = '''
        var a = [];
        var b = [1];
        var c = a + b;
        print(c);
      ''';
      
      final logs = <String>[];
      
      final tokens = Lexer(source).tokenize();
      final ast = Parser(tokens).parse();
      final function = Compiler(unit: ast).endCompiler();
      
      final vm = VM();
      vm.onPrint = (msg) => logs.add(msg);
      vm.runChunk(function.chunk);
      
      expect(logs[0], '[1]');
    });
  });
}
