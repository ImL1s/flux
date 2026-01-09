import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:test/test.dart';

void main() {
  group('Expression Evaluation', () {
    test('evaluates expressions with local variables', () {
      final source = """
fn main() {
  var a = 10;
  var b = 20;
  var c = a + b;
}
main();
""";

      final lexer = Lexer(source);
      final parser = Parser(lexer.tokenize());
      final compilationUnit = parser.parse();
      final compiler = Compiler(moduleName: 'eval_test');
      compiler.compile(compilationUnit.declarations[0]); // main
      compiler.compile(compilationUnit.declarations[1]); // main() call

      final function = compiler.endCompiler();

      final vm = VM();
      final debugger = FluxDebugger(vm);
      vm.debugger = debugger;
      debugger.attach();

      // Set breakpoints on all lines to catch where it is
      debugger.setBreakpoint('eval_test', 2);
      debugger.setBreakpoint('eval_test', 3);
      debugger.setBreakpoint('eval_test', 4);
      debugger.setBreakpoint('eval_test', 5);

      bool paused = false;
      debugger.addListener((event, context) {
        if (event == DebugEvent.breakpoint) {
          paused = true;

          if (context.line == 4) {
            // 1. Evaluate simple local
            expect(debugger.evaluate('a'), equals(10));

            // 2. Evaluate another local
            expect(debugger.evaluate('b'), equals(20));

            // 3. Evaluate expression
            expect(debugger.evaluate('a + b'), equals(30));

            // 4. Evaluate expression with literals
            expect(debugger.evaluate('a * 2'), equals(20));
          }
        }
      });

      vm.executeClosure(ObjClosure(function, []));

      // Pump loop
      while (debugger.isPaused) {
        debugger.continue_();
      }

      expect(paused, isTrue);
    });

    test('evaluates expressions with function parameters', () {
      final source = """
fn add(x, y) {
  var z = x + y;
}
add(5, 7);
""";

      final lexer = Lexer(source);
      final parser = Parser(lexer.tokenize());
      final compilationUnit = parser.parse();
      final compiler = Compiler(moduleName: 'eval_test_2');
      compiler.compile(compilationUnit.declarations[0]); // add
      compiler.compile(compilationUnit.declarations[1]); // add call
      final function = compiler.endCompiler();

      final vm = VM();
      final debugger = FluxDebugger(vm);
      vm.debugger = debugger;
      debugger.attach();

      debugger.setBreakpoint('eval_test_2', 2);

      bool paused = false;
      debugger.addListener((event, context) {
        if (event == DebugEvent.breakpoint) {
          paused = true;

          expect(debugger.evaluate('x'), equals(5));
          expect(debugger.evaluate('y'), equals(7));
          expect(debugger.evaluate('x + y'), equals(12));

          debugger.continue_();
        }
      });

      vm.executeClosure(ObjClosure(function, []));

      while (debugger.isPaused) {
        debugger.continue_();
      }

      expect(paused, isTrue);
    });
  });
}
