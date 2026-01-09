/// Comprehensive VM Edge Case Tests
import 'package:test/test.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  late VM vm;
  late List<String> logs;

  InterpretResult runScript(String source) {
    logs = [];
    vm = VM();
    vm.onPrint = (msg) => logs.add(msg);

    final tokens = Lexer(source).tokenize();
    final ast = Parser(tokens).parse();
    final compiler = Compiler(unit: ast);
    final function = compiler.endCompiler();
    return vm.runChunk(function.chunk);
  }

  group('VM Edge Cases - Stack Operations', () {
    test('deep recursion (50 calls)', () {
      final result = runScript('''
        fn countdown(n) {
          if (n <= 0) { return 0; }
          return countdown(n - 1);
        }
        var result = countdown(50);
        print(result);
      ''');
      expect(result, InterpretResult.ok);
      expect(logs[0], '0');
    });

    test('many local variables in scope', () {
      final vars = List.generate(50, (i) => 'var v$i = $i;').join('\n');
      final result = runScript('''
        $vars
        print(v49);
      ''');
      expect(result, InterpretResult.ok);
      expect(logs[0], '49');
    });

    test('stress: 10000 iterations', () {
      final result = runScript('''
        var sum = 0;
        for (var i = 0; i < 10000; i = i + 1) {
          sum = sum + 1;
        }
        print(sum);
      ''');
      expect(result, InterpretResult.ok);
      expect(logs[0], '10000');
    });
  });

  group('VM Edge Cases - Type Coercion', () {
    test('string + number concatenation', () {
      final result = runScript('''
        print("count: " + 42);
      ''');
      expect(result, InterpretResult.ok);
      expect(logs[0], 'count: 42');
    });

    test('number + string concatenation', () {
      final result = runScript('''
        print(42 + " items");
      ''');
      expect(result, InterpretResult.ok);
      expect(logs[0], '42 items');
    });

    test('boolean in string context', () {
      final result = runScript('''
        print("result: " + true);
      ''');
      expect(result, InterpretResult.ok);
      expect(logs[0], 'result: true');
    });

    test('nil in string context', () {
      final result = runScript('''
        print("value: " + nil);
      ''');
      expect(result, InterpretResult.ok);
      expect(logs[0], 'value: null');
    });
  });

  group('VM Edge Cases - Collections', () {
    test('nested lists (5 levels)', () {
      final result = runScript('''
        var nested = [[[[[1, 2], 3], 4], 5], 6];
        print(nested[0][0][0][0][0]);
      ''');
      expect(result, InterpretResult.ok);
      expect(logs[0], '1');
    });

    test('list modification during iteration', () {
      final result = runScript('''
        var list = [1, 2, 3];
        for (var i = 0; i < len(list); i = i + 1) {
          if (list[i] == 2) {
            push(list, 4);
          }
        }
        print(len(list));
      ''');
      expect(result, InterpretResult.ok);
      expect(logs[0], '4');
    });

    test('empty list operations', () {
      final result = runScript('''
        var list = [];
        print(len(list));
        push(list, 1);
        print(len(list));
        pop(list);
        print(len(list));
      ''');
      expect(result, InterpretResult.ok);
      expect(logs, ['0', '1', '0']);
    });

    test('map with various key types', () {
      final result = runScript('''
        var map = {"str": 1, "num": 2};
        print(map["str"]);
        print(map["num"]);
      ''');
      expect(result, InterpretResult.ok);
      expect(logs, ['1', '2']);
    });
  });

  group('VM Edge Cases - Closures', () {
    test('closure capturing loop variable', () {
      final result = runScript('''
        var funcs = [];
        for (var i = 0; i < 3; i = i + 1) {
          var captured = i;
          push(funcs, fn() { return captured; });
        }
        print(funcs[0]());
        print(funcs[1]());
        print(funcs[2]());
      ''');
      expect(result, InterpretResult.ok);
      expect(logs, ['0', '1', '2']);
    });

    test('closure modifying captured variable', () {
      final result = runScript('''
        fn makeCounter() {
          var count = 0;
          return fn() {
            count = count + 1;
            return count;
          };
        }
        var c = makeCounter();
        print(c());
        print(c());
        print(c());
      ''');
      expect(result, InterpretResult.ok);
      expect(logs, ['1', '2', '3']);
    });

    test('multiple closures sharing same upvalue', () {
      final result = runScript('''
        fn makePair() {
          var shared = 0;
          var inc = fn() { shared = shared + 1; return shared; };
          var get = fn() { return shared; };
          return [inc, get];
        }
        var pair = makePair();
        var inc = pair[0];
        var get = pair[1];
        inc();
        inc();
        print(get());
      ''');
      expect(result, InterpretResult.ok);
      expect(logs[0], '2');
    });
  });

  group('VM Edge Cases - Classes', () {
    test('simple class instantiation', () {
      final result = runScript('''
        class Empty {}
        var e = Empty();
        print(e != nil);
      ''');
      expect(result, InterpretResult.ok);
      expect(logs[0], 'true');
    });
  });

  group('VM Edge Cases - Exception Handling', () {
    test('exception with nil value', () {
      final result = runScript('''
        try {
          throw nil;
        } catch (e) {
          print(e == nil);
        }
      ''');
      expect(result, InterpretResult.ok);
      expect(logs[0], 'true');
    });

    test('exception with complex object', () {
      final result = runScript('''
        try {
          throw {"code": 404, "message": "Not found"};
        } catch (e) {
          print(e["code"]);
        }
      ''');
      expect(result, InterpretResult.ok);
      expect(logs[0], '404');
    });

    test('finally always runs on return', () {
      final result = runScript('''
        fn test() {
          try {
            return "early";
          } finally {
            print("cleanup");
          }
        }
        var r = test();
        print(r);
      ''');
      expect(result, InterpretResult.ok);
      expect(logs, ['cleanup', 'early']);
    });
  });
}
