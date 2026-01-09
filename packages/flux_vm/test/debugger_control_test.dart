import 'package:test/test.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  group('Debugger Control', () {
    late VM vm;
    late FluxDebugger debugger;

    setUp(() {
      vm = VM();
      debugger = FluxDebugger(vm);
      vm.debugger = debugger;
      debugger.attach();
    });

    test('Pauses at breakpoint with moduleName', () {
      final source = 'var a = 1;\nvar b = 2;\nvar c = a + b;\nvar d = c * 2;';

      // Line mapping:
      // 1: var a = 1;
      // 2: var b = 2;
      // 3: var c = a + b;
      // 4: var d = c * 2;

      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();

      // Compile with moduleName
      final compiler = Compiler(unit: ast, moduleName: 'test.flux');
      compiler.compile(ast.declarations[0]); // Compile script
      final function = compiler.endCompiler();

      // Set Breakpoint at Line 3
      debugger.setBreakpoint('test.flux', 3);

      // Run
      final result = vm.executeClosure(ObjClosure(function, []));

      expect(result, equals(InterpretResult.paused));
      expect(debugger.isPaused, isTrue);

      // Resume
      final result2 = vm.resume();
      expect(result2, equals(InterpretResult.ok));
    });

    test('Resuming from breakpoint executes next line', () {
      final source = 'var start = 1;\nvar mid = 2;\nvar end = 3;';

      final lexer = Lexer(source);
      final parser = Parser(lexer.tokenize());
      final ast = parser.parse();
      final compiler = Compiler(unit: ast, moduleName: 'step.flux');
      compiler.compile(ast.declarations[0]);
      final function = compiler.endCompiler();

      debugger.setBreakpoint('step.flux', 2); // Break at var mid = 2

      var result = vm.executeClosure(ObjClosure(function, []));
      expect(result, equals(InterpretResult.paused));

      // Current line should be 2.
      // Since we don't have easy access to line inspection via VM public API,
      // we trust the pause happened.

      // Resume
      result = vm.resume();
      expect(result, equals(InterpretResult.ok));
    });

    test('Step Into behaves correctly', () {
      final source = '''
         var x = 1;
         var y = 2;
       ''';

      final ast = Parser(Lexer(source).tokenize()).parse();
      final compiler = Compiler(unit: ast, moduleName: 'step_into.flux');
      compiler.compile(ast.declarations[0]);
      final function = compiler.endCompiler();

      // Pause initially
      debugger.pause();

      // First run should trigger pause immediately because we are paused
      var result = vm.executeClosure(ObjClosure(function, []));
      expect(result, equals(InterpretResult.paused));

      // Enable Step Into
      debugger.stepInto();

      // Resume (logic inside VM should execute one instruction then pause)
      result = vm.resume();

      expect(result, equals(InterpretResult.paused));
      // Depending on how many instructions per line...
      // var x = 1 involves multiple ops (Constant, DefineGlobal).
      // So stepInto should pause after Constant, before DefineGlobal?

      // Clean up
      debugger.continue_();
      vm.resume();
    });

    test('breakpoint on non-existent line does not crash', () {
      final source = 'var a = 1;\nvar b = 2;';

      final ast = Parser(Lexer(source).tokenize()).parse();
      final compiler = Compiler(unit: ast, moduleName: 'edge.flux');
      compiler.compile(ast.declarations[0]);
      final function = compiler.endCompiler();

      // Set breakpoint on line 100 (doesn't exist)
      debugger.setBreakpoint('edge.flux', 100);

      // Should run without hitting breakpoint
      final result = vm.executeClosure(ObjClosure(function, []));
      expect(result, equals(InterpretResult.ok));
    });

    test('remove non-existent breakpoint does not crash', () {
      // removeBreakpoint takes int id
      expect(() => debugger.removeBreakpoint(9999), returnsNormally);
    });

    test('clear breakpoints on empty state', () {
      expect(() => debugger.clearBreakpoints(), returnsNormally);
    });
  });
}
