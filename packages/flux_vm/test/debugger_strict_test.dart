import 'dart:io';
import 'package:test/test.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  final logFile = File('debugger_trace.log');
  if (logFile.existsSync()) logFile.deleteSync();

  group('Debugger Strict Tests', () {
    late VM fluxVM;
    late FluxDebugger fluxDebugger;

    setUp(() {
      fluxVM = VM();
      fluxVM.onPrint =
          (msg) => logFile.writeAsStringSync('$msg\n', mode: FileMode.append);
      fluxDebugger = FluxDebugger(fluxVM);
      fluxVM.debugger = fluxDebugger;
      fluxDebugger.attach();
    });

    ObjClosure _compile(String source, String moduleName) {
      final ast = Parser(Lexer(source).tokenize()).parse();
      final compiler = Compiler(unit: ast, moduleName: moduleName);
      // Compile each declaration
      for (final decl in ast.declarations) {
        compiler.compile(decl);
      }
      final function = compiler.endCompiler();
      return ObjClosure(function, []);
    }

    test('Step Over skips function body and stops at next line', () {
      final source = '''
fn add(a, b) {
  var res = a + b;
  return res;
}
var x = 1;         // Line 5
var y = add(x, 2); // Line 6
var z = y * 2;     // Line 7''';

      final closure = _compile(source, 'step_over.flux');

      // Breakdown:
      // Line 5: var x = 1;
      // Line 6: var y = add(x, 2);
      // Line 7: var z = y * 2;

      // Set BP at Line 6 (add call)
      fluxDebugger.setBreakpoint('step_over.flux', 6);

      var result = fluxVM.executeClosure(closure);
      expect(result, equals(InterpretResult.paused));

      // Step Over
      fluxDebugger.stepOver();
      result = fluxVM.resume();

      expect(result, equals(InterpretResult.paused),
          reason: 'Should pause at Line 7');
      expect(
          fluxVM.frames.last.chunk.getLine(fluxVM.frames.last.ip), equals(7));

      fluxVM.resume();
    });

    test('Step Out finishes function and stops in caller', () {
      final source = '''
fn work() {
  var a = 1; // Line 2
  var b = 2; // Line 3
  return a + b;
}
work(); // Line 6
var done = true; // Line 7''';

      final closure = _compile(source, 'step_out.flux');

      // Set BP inside work() at line 2
      fluxDebugger.setBreakpoint('step_out.flux', 2);

      var result = fluxVM.executeClosure(closure);
      expect(result, equals(InterpretResult.paused));

      // Step Out
      fluxDebugger.stepOut();
      result = fluxVM.resume();

      expect(result, equals(InterpretResult.paused));
      // Should stop at line 6 (immediately after returning to the call site)
      expect(
          fluxVM.frames.last.chunk.getLine(fluxVM.frames.last.ip), equals(6));

      fluxVM.resume();
    });

    test('Multiple breakpoints in a loop', () {
      print('TEST: Multiple breakpoints in a loop START');
      final source = '''
var sum = 0;
for (var i = 0; i < 3; i = i + 1) {
  sum = sum + i; // Line 3
}''';

      final closure = _compile(source, 'loop.flux');
      fluxDebugger.setBreakpoint('loop.flux', 3);

      // Iteration 0
      var result = fluxVM.executeClosure(closure);
      expect(result, equals(InterpretResult.paused));

      // Iteration 1
      result = fluxVM.resume();
      expect(result, equals(InterpretResult.paused));

      // Iteration 2
      result = fluxVM.resume();
      expect(result, equals(InterpretResult.paused));

      // End
      fluxDebugger.removeBreakpointAt('loop.flux', 3);
      result = fluxVM.resume();
      expect(result, equals(InterpretResult.ok));
    });

    test('Breaking in recursive calls', () {
      final source = '''
fn fib(n) {
  if (n <= 1) return n;
  return fib(n - 1) + fib(n - 2); // Line 3
}
var res = fib(3);''';

      final closure = _compile(source, 'recursive.flux');
      fluxDebugger.setBreakpoint('recursive.flux', 3);

      // Should hit multiple times
      var result = fluxVM.executeClosure(closure);
      expect(result, equals(InterpretResult.paused));

      result = fluxVM.resume();
      expect(result, equals(InterpretResult.paused));

      // Remove BP and finish
      fluxDebugger.removeBreakpointAt('recursive.flux', 3);
      fluxDebugger.continue_();
      result = fluxVM.resume();
      expect(result, equals(InterpretResult.ok));
    });

    test('Step Into follows into closure call', () {
      final source = '''
var makeAdder = fn(x) {
  return fn(y) {
    return x + y; // Line 3
  };
};
var adder = makeAdder(5);
var res = adder(10); // Line 7''';

      final closure = _compile(source, 'closure.flux');
      fluxDebugger.setBreakpoint('closure.flux', 7);

      var result = fluxVM.executeClosure(closure);
      expect(result, equals(InterpretResult.paused));

      fluxDebugger.stepInto();
      result = fluxVM.resume();

      expect(result, equals(InterpretResult.paused));
      expect(
          fluxVM.frames.last.chunk.getLine(fluxVM.frames.last.ip), equals(3));

      fluxVM.resume();
    });
  });
}
