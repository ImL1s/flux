import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';


void main() {
  group('StdLib Math Operations', () {
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

    test('math basic funcs', () {
      runScript('''
        print(abs(-5));
        print(min(10, 20));
        print(max(10, 20));
        print(floor(3.9));
        print(ceil(3.1));
        print(sqrt(16));
      ''');
      expect(logs[0], '5');
      expect(logs[1], '10');
      expect(logs[2], '20');
      expect(logs[3], '3');
      expect(logs[4], '4');
      expect(logs[5], '4.0');
    });

    test('math.pow', () {
      runScript('''
        print(pow(2, 3));
      ''');
      expect(logs[0], '8'); // 2^3 = 8. math.pow returns num, usually int if inputs int. 
      // Dart math.pow(2,3) returns 8 (int).
    });

    test('math.random', () {
      runScript('''
        var r = random();
        print(type(r));
        if (r >= 0) { print("ge0"); }
        if (r < 1) { print("lt1"); }
      ''');
      expect(logs[0], 'double');
      expect(logs[1], 'ge0');
      expect(logs[2], 'lt1');
    });

    test('math.randomInt', () {
      runScript('''
        var r = randomInt(10);
        print(type(r));
        if (r >= 0) { print("ge0"); }
        if (r < 10) { print("lt10"); }
      ''');
       expect(logs[0], 'int');
       expect(logs[1], 'ge0');
       expect(logs[2], 'lt10');
    });
  });
}
