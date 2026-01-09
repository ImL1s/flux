import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_flutter/src/dev_tools/flux_service_extensions.dart';
import 'package:flux_flutter/src/flux_widget.dart';

void main() {
  group('DevTools Integration Test', () {
    test('Verifies service extension responses match UI expectations',
        () async {
      final source = """
fn main() {
  helper();
}
fn helper() {
  var a = 100;
  var b = 200;
  var c = a + b;
}
main();
""";

      // 1. Compile
      final lexer = Lexer(source);
      final parser = Parser(lexer.tokenize());
      final compilationUnit = parser.parse();
      final compiler = Compiler(moduleName: 'devtools_test');
      for (final decl in compilationUnit.declarations) {
        compiler.compile(decl);
      }
      final function = compiler.endCompiler();

      // 2. Setup VM
      final vm = VM();
      final debugger = FluxDebugger(vm);
      vm.debugger = debugger;
      debugger.attach();

      // 3. Set Breakpoints (Line 7 is 'var c = a + b')
      debugger.setBreakpoint('devtools_test', 7);

      bool paused = false;
      debugger.addListener((event, context) {
        if (event == DebugEvent.breakpoint) {
          paused = true;
        }
      });

      // 4. Run to Breakpoint
      vm.executeClosure(ObjClosure(function, []));

      expect(paused, isTrue, reason: "Debugger should pause at breakpoint");

      if (paused) {
        // 5. Test getStack (ext.flux.getStack)
        final stackResponse =
            await FluxServiceExtensionHandlers.getStack(vm, {});
        final stackJson = jsonDecode(stackResponse.result as String);

        expect(stackJson['type'], 'Stack');
        final frames = stackJson['frames'] as List;
        expect(frames.length, greaterThanOrEqualTo(2));
        expect(frames[0]['function'], 'helper');
        expect(frames[1]['function'], 'main');

        // 6. Test getLocals (ext.flux.getLocals)
        final localsResponse = await FluxServiceExtensionHandlers.getLocals(
            vm, {'frameIndex': '0'});
        final localsJson = jsonDecode(localsResponse.result as String);

        expect(localsJson['type'], 'Locals');
        final locals = localsJson['locals'] as Map;
        // New format: locals are structured objects
        expect(locals['a']['type'], 'primitive');
        expect(locals['a']['value'], '100');
        expect(locals['b']['value'], '200');

        // 7. Test Eval (ext.flux.eval)
        final evalResponse = await FluxServiceExtensionHandlers.eval(
            vm, {'expr': 'a + b', 'frameIndex': '0'});
        final evalJson = jsonDecode(evalResponse.result as String);

        expect(evalJson['type'], 'EvalResult');
        expect(evalJson['isError'], false,
            reason: "Eval returned error: ${evalJson['result']}");

        final res = evalJson['result'];
        expect(res.toString(), contains('300'), reason: "Eval result was $res");

        // 8. Test Eval Error
        final errorResponse = await FluxServiceExtensionHandlers.eval(
            vm, {'expr': 'unknown_var + 1'});
        final errorJson = jsonDecode(errorResponse.result as String);
        expect(errorJson['isError'], true);

        // 9. Test getStatus
        final statusResponse =
            await FluxServiceExtensionHandlers.getStatus(vm, {});
        final statusJson = jsonDecode(statusResponse.result as String);
        expect(statusJson['isPaused'], true, reason: "Status should be paused");
        expect(statusJson['vmState'], 'Paused');
        expect(statusJson['pausedLine'], 7);

        // 10. Test getMemoryStats (ext.flux.getMemoryStats)
        final memoryResponse =
            await FluxServiceExtensionHandlers.getMemoryStats(vm, {});
        final memoryJson = jsonDecode(memoryResponse.result as String);

        expect(memoryJson['type'], 'MemoryStats');
        final stats = memoryJson['stats'];
        expect(stats, contains('aliveInstances'));
        expect(stats, contains('totalAllocated'));
        expect(stats['totalAllocated'], isNotNull);

        // 11. Test getWidgetTree (ext.flux.getWidgetTree)
        // Simulate a widget tree
        final node = FluxWidgetNode('Center', args: {'key': 'val'}, children: ['Hello']);
        vm.lastWidgetTree = node;

        final treeResponse =
            await FluxServiceExtensionHandlers.getWidgetTree(vm, {});
        final treeJson = jsonDecode(treeResponse.result as String);

        expect(treeJson['type'], 'WidgetTree');
        expect(treeJson['tree']['name'], 'Center');
        expect(treeJson['tree']['args']['key'], 'val');
        expect(treeJson['tree']['children'][0], 'Hello');
      }
    });
  });
}
