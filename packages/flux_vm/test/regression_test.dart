import 'package:flux_vm/flux_vm.dart';
import 'package:test/test.dart';

void main() {
  group('Regression Tests', () {
    test('try-finally exception propagation (Fix: Exception Swallowing)', () {
      final source = """
        var x = "start";
        try {
          throw "error";
        } finally {
          x = "finally";
        }
      """;

      final vm = VM();
      final result = vm.interpret(source);

      // Should Result in RuntimeError, NOT Ok
      expect(result, InterpretResult.runtimeError);
    });

    test('return inside try executes finally (Fix: Return Skipping Finally)',
        () {
      final source = """
        var x = "";
        fn test() {
          try {
             x = x + "try";
             return; 
          } finally {
             x = x + "-finally";
          }
        }
        test();
        print(x);
      """;

      final vm = VM();
      var output = "";
      vm.onPrint = (msg) => output = msg.toString();

      final result = vm.interpret(source);

      expect(result, InterpretResult.ok);
      expect(output, equals("try-finally"));
    });

    test('nested try-finally return execution', () {
      final source = """
        var log = "";
        fn test() {
          try {
            try {
              return;
            } finally {
              log = log + "inner";
            }
          } finally {
            log = log + "-outer";
          }
        }
        test();
        print(log);
      """;

      final vm = VM();
      var output = "";
      vm.onPrint = (msg) => output = msg.toString();

      vm.interpret(source);
      expect(output, equals("inner-outer"));
    });
  });
}
