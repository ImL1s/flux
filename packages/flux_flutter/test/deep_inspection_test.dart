import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_flutter/src/dev_tools/flux_service_extensions.dart';

void main() {
  group('Deep Object Inspection Test', () {
    test('Verifies deep inspection of List and Map', () async {
      final source = """
fn main() {
  var list = [1, 2, 3];
  var map = {"a": 10, "b": 20};
  var x = 100;
}
main();
""";

      // 1. Compile
      final lexer = Lexer(source);
      final parser = Parser(lexer.tokenize());
      final compilationUnit = parser.parse();
      final compiler = Compiler(moduleName: 'deep_test');
      for (final decl in compilationUnit.declarations) {
        compiler.compile(decl);
      }
      final function = compiler.endCompiler();

      // 2. Setup VM
      final vm = VM();
      final debugger = FluxDebugger(vm);
      vm.debugger = debugger;
      debugger.attach();

      debugger.setBreakpoint('deep_test', 4); // Line 4: var x = 100

      bool paused = false;
      debugger.addListener((event, context) {
        if (event == DebugEvent.breakpoint) {
          paused = true;
        }
      });

      // 4. Run
      vm.executeClosure(ObjClosure(function, []));

      expect(paused, isTrue, reason: "Debugger should pause");

      if (paused) {
        // 5. Get Locals
        final localsResponse = await FluxServiceExtensionHandlers.getLocals(
            vm, {'frameIndex': '0'});
        final localsJson = jsonDecode(localsResponse.result as String);
        final locals = localsJson['locals'] as Map;

        // Verify List
        expect(locals.containsKey('list'), true);
        final listRef = locals['list'];
        expect(listRef['type'], 'ref');
        expect(listRef['kind'], contains('List'));
        final listHandle = listRef['handle'];

        final listObjResponse = await FluxServiceExtensionHandlers.getObject(
            vm, {'handle': listHandle.toString()});
        final listObj = jsonDecode(listObjResponse.result as String)['object'];
        expect(listObj['kind'], 'List');
        expect(listObj['length'], 3);
        expect(listObj['elements'][0]['value']['value'], '1');

        // Verify Map
        expect(locals.containsKey('map'), true);
        final mapRef = locals['map'];
        expect(mapRef['type'], 'ref');
        expect(mapRef['kind'], contains('Map'));
        final mapHandle = mapRef['handle'];

        final mapObjResponse = await FluxServiceExtensionHandlers.getObject(
            vm, {'handle': mapHandle.toString()});
        final mapObj = jsonDecode(mapObjResponse.result as String)['object'];
        expect(mapObj['kind'], 'Map');

        final entries = mapObj['entries'] as List;
        final entryA = entries.firstWhere((e) => e['key']['value'] == 'a',
            orElse: () => null);
        expect(entryA, isNotNull, reason: "Map should contain key 'a'");
        expect(entryA['value']['value'], '10');
      }
    });
  });
}
