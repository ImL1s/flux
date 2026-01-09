import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';

void main() {
  group('StdLib Map and JSON', () {
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

    test('Map basics', () {
      runScript('''
        var m = {"a": 1, "b": 2};
        print(len(m));
        print(m["a"]);
        m["c"] = 3;
        print(len(m));
        print(m["c"]);
      ''');
      expect(logs[0], '2');
      expect(logs[1], '1');
      expect(logs[2], '3');
      expect(logs[3], '3');
    });

    test('json.stringify', () {
      runScript('''
        var m = {"name": "flux", "ver": 1};
        var s = json.stringify(m);
        // JSON key order is not strictly guaranteed, but typically stable for simple maps in Dart
        print(contains(s, '"name":"flux"'));
        print(contains(s, '"ver":1')); // Dart jsonEncode usually doesn't add spaces
      ''');
      expect(logs[0], 'true');
      expect(logs[1], 'true');
    });

    test('json.parse', () {
      runScript('''
        var s = '{"x": 10, "y": 20}';
        var m = json.parse(s);
        print(m["x"]);
        print(m["y"]);
      ''');
      expect(logs[0], '10');
      expect(logs[1], '20');
    });

    test('json error handling', () {
      // We verify that invalid json causes a runtime error (wrapped by VM)

      // Actually runChunk returns result, doesn't throw.
      // runScript helper doesn't assert.
      // Let's rely on VM behavior.

      final tokens = Lexer('json.parse("bad")').tokenize();
      final function = Compiler(unit: Parser(tokens).parse()).endCompiler();
      // Since we didn't patch VM to throw dart exceptions for native errors in previous steps,
      // we expect InterpretResult.runtimeError usually, unless stdlib native function throws strings that VM catches.
      final result = vm.runChunk(function.chunk);
      expect(result, InterpretResult.runtimeError);
    });
  });
}
