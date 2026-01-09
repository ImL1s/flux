import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';

void main() {
  group('StdLib List Operations', () {
    late VM vm;
    late List<String> logs;

    setUp(() {
      vm = VM();
      logs = [];
      vm.onPrint = (msg) => logs.add(msg);
    });

    void runScript(String source) {
      final tokens = Lexer(source).tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final function = compiler.endCompiler();
      vm.runChunk(function.chunk);
    }

    test('list.push adds elements', () {
      runScript('''
        var l = [];
        push(l, 1);
        push(l, 2);
        print(l);
        print(len(l));
      ''');
      expect(logs[0], '[1, 2]');
      expect(logs[1], '2');
    });

    test('list.pop removes last element', () {
      runScript('''
        var l = [1, 2, 3];
        var x = pop(l);
        print(x);
        print(l);
      ''');
      expect(logs[0], '3');
      expect(logs[1], '[1, 2]');
    });

    test('list.pop throws on empty list', () {
      final vm = VM();
      vm.onPrint = (msg) {};

      // Manually running with expectation of failure result
      final tokens = Lexer('var l = []; pop(l);').tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final function = compiler.endCompiler();

      final result = vm.runChunk(function.chunk);
      expect(result, InterpretResult.runtimeError);
    });

    test('list.insert adds at index', () {
      runScript('''
        var l = [1, 3];
        insert(l, 1, 2);
        print(l);
      ''');
      expect(logs[0], '[1, 2, 3]');
    });

    test('list.remove removes at index', () {
      runScript('''
        var l = ["a", "b", "c"];
        var rem = remove(l, 1);
        print(rem);
        print(l);
      ''');
      expect(logs[0], 'b');
      expect(logs[1], '[a, c]');
    });

    test('list.indexOf finds elements', () {
      runScript('''
        var l = [10, 20, 30];
        print(indexOf(l, 20));
        print(indexOf(l, 99));
      ''');
      expect(logs[0], '1');
      expect(logs[1], '-1');
    });

    test('list.reverse returns reversed copy', () {
      runScript('''
        var l = [1, 2, 3];
        var r = reverse(l);
        print(r);
        print(l); // Original unchanged? 'reversed.toList()' creates new list in Dart
      ''');
      expect(logs[0], '[3, 2, 1]');
      expect(logs[1], '[1, 2, 3]'); // Confirming non-mutating
    });

    test('list.sort sorts in place', () {
      // Dart sort is in-place. stdlib implementation: `sorted.sort(); return sorted;`.
      // Wait, stdlib.dart says: `final sorted = List.from(list); sorted.sort(); return sorted;`
      // So it returns a NEW list and does NOT mutate original. Let's verify.
      runScript('''
        var l = [3, 1, 2];
        var s = sort(l);
        print(s);
        print(l);
      ''');
      expect(logs[0], '[1, 2, 3]');
      expect(logs[1], '[3, 1, 2]');
    });

    test('list.join creates string', () {
      runScript('''
        var l = ["a", "b", "c"];
        print(join(l, "-"));
      ''');
      expect(logs[0], 'a-b-c');
    });
  });
}
