import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:test/test.dart';

class FluxCompiler {
  static CompiledFunction compile(String source) {
    final tokens = Lexer(source).tokenize();
    final parser = Parser(tokens);
    final unit = parser.parse();
    final compiler = Compiler(unit: unit);
    return compiler.endCompiler();
  }
}

void main() {
  late VM vm;

  setUp(() {
    vm = VM();
  });

  // testScript helper removed as it was unused and caused analysis warnings

  test('Basic closure', () {
    final source = """
      var x = "global";
      fn outer() {
        var x = "outer";
        fn inner() {
          print(x);
        }
        inner();
      }
      outer();
    """;

    var output = "";
    vm.onPrint = (msg) => output = msg;

    final unit = FluxCompiler.compile(source);
    vm.runChunk(unit.chunk);

    expect(output, equals("outer"));
  });

  test('Closure closes over variable', () {
    final source = """
      var f;
      fn outer() {
        var x = "outside";
        fn inner() {
          print(x);
        }
        f = inner;
      }
      outer();
      f();
    """;

    var output = "";
    vm.onPrint = (msg) => output = msg;

    final unit = FluxCompiler.compile(source);
    vm.runChunk(unit.chunk);

    expect(output, equals("outside"));
  });

  test('Closure modifies captured variable', () {
    final source = """
      var f;
      fn outer() {
        var x = "before";
        fn inner() {
          x = "after";
        }
        inner();
        print(x);
      }
      outer();
    """;

    var output = "";
    vm.onPrint = (msg) => output = msg;

    final unit = FluxCompiler.compile(source);
    vm.runChunk(unit.chunk);

    expect(output, equals("after"));
  });

  test('Closure modifies closed upvalue', () {
    final source = """
      var set;
      var get;
      
      fn outer() {
        var x = "initial";
        fn setter() {
          x = "updated";
        }
        fn getter() {
           print(x);
        }
        set = setter;
        get = getter;
      }
      
      outer();
      set();
      get();
    """;

    var output = "";
    vm.onPrint = (msg) => output = msg;

    final unit = FluxCompiler.compile(source);
    vm.runChunk(unit.chunk);

    expect(output, equals("updated"));
  });

  test('Multiple closures capture same existing upvalue', () {
    final source = """
      var x = "value";
      fn outer() {
         var y = "calc"; // local
         fn inner1() {
           print(x);
         }
         fn inner2() {
           print(x);
         }
         inner1();
         inner2();
      }
      outer();
    """;

    List<String> outputs = [];
    vm.onPrint = (msg) => outputs.add(msg);

    final unit = FluxCompiler.compile(source);
    vm.runChunk(unit.chunk);

    expect(outputs, equals(["value", "value"]));
  });

  test('Nested closures', () {
    final source = """
      var f;
      fn outer() {
        var a = "a";
        fn middle() {
          var b = "b";
          fn inner() {
            print(a + b);
          }
          f = inner;
        }
        middle();
      }
      outer();
      f();
    """;

    var output = "";
    vm.onPrint = (msg) => output = msg;

    final unit = FluxCompiler.compile(source);
    vm.runChunk(unit.chunk);

    expect(output, equals("ab"));
  });

  // Additional edge-case tests based on best practices

  test('Counter pattern (classic closure use case)', () {
    final source = """
      var makeCounter;
      var counter;
      
      fn createCounter() {
        var count = 0;
        fn increment() {
          count = count + 1;
          print(count);
        }
        return increment;
      }
      
      counter = createCounter();
      counter();
      counter();
      counter();
    """;

    List<String> outputs = [];
    vm.onPrint = (msg) => outputs.add(msg);

    final unit = FluxCompiler.compile(source);
    vm.runChunk(unit.chunk);

    expect(outputs, equals(["1", "2", "3"]));
  });

  test('Closure captures parameter', () {
    final source = """
      var f;
      fn outer(x) {
        fn inner() {
          print(x);
        }
        f = inner;
      }
      outer("captured param");
      f();
    """;

    var output = "";
    vm.onPrint = (msg) => output = msg;

    final unit = FluxCompiler.compile(source);
    vm.runChunk(unit.chunk);

    expect(output, equals("captured param"));
  });

  test('Two independent closures with same variable name', () {
    final source = """
      var f1;
      var f2;
      
      fn make1() {
        var x = "closure1";
        fn inner() {
          print(x);
        }
        f1 = inner;
      }
      
      fn make2() {
        var x = "closure2";
        fn inner() {
          print(x);
        }
        f2 = inner;
      }
      
      make1();
      make2();
      f1();
      f2();
    """;

    List<String> outputs = [];
    vm.onPrint = (msg) => outputs.add(msg);

    final unit = FluxCompiler.compile(source);
    vm.runChunk(unit.chunk);

    expect(outputs, equals(["closure1", "closure2"]));
  });

  test('Closed upvalue survives stack pop', () {
    final source = """
      var f;
      fn outer() {
        var local = "survived";
        fn inner() {
          print(local);
        }
        f = inner;
        // After outer() returns, local is popped from stack
        // But upvalue should be closed and preserved
      }
      outer();
      // Now call f() after outer's stack frame is gone
      f();
    """;

    var output = "";
    vm.onPrint = (msg) => output = msg;

    final unit = FluxCompiler.compile(source);
    vm.runChunk(unit.chunk);

    expect(output, equals("survived"));
  });

  test('Three-level nested closure', () {
    final source = """
      var f;
      fn level1() {
        var a = "L1";
        fn level2() {
          var b = "L2";
          fn level3() {
            var c = "L3";
            fn level4() {
              print(a + b + c);
            }
            f = level4;
          }
          level3();
        }
        level2();
      }
      level1();
      f();
    """;

    var output = "";
    vm.onPrint = (msg) => output = msg;

    final unit = FluxCompiler.compile(source);
    vm.runChunk(unit.chunk);

    expect(output, equals("L1L2L3"));
  });
}
