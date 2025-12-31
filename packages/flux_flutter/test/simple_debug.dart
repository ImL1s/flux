
import 'dart:convert';
import 'dart:io';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_flutter/src/dev_tools/flux_service_extensions.dart';

void main() async {
  print("Starting simple debug script...");
  final source = """
fn main() {
  var list = [1, 2, 3];
  var map = {"a": 10, "b": 20};
  var x = 100;
}
main();
""";

  try {
      // 1. Compile
      final lexer = Lexer(source);
      final parser = Parser(lexer.tokenize());
      final compilationUnit = parser.parse();
      
      if (parser.errors.isNotEmpty) {
        print("Parser Errors: ${parser.errors}");
        return;
      }
      
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

      // Breakpoint at line 4: var x = 100;
      // Lines:
      // 1: fn main() {
      // 2:   var list = ...
      // 3:   var map = ...
      // 4:   var x = 100;
      // 5: }
      // 6: main();
      
      debugger.setBreakpoint('deep_test', 4); 
      
      bool paused = false;
      debugger.addListener((event, context) {
        if (event == DebugEvent.breakpoint) {
          paused = true;
          print("Debugger Paused!");
        }
      });

      // 4. Run
      print("Executing closure...");
      vm.executeClosure(ObjClosure(function, []));
      
      if (paused) {
         // 5. Get Locals
         print("Getting locals...");
         final localsResponse = await FluxServiceExtensionHandlers.getLocals(vm, {'frameIndex': '0'});
         print("Locals Response: ${localsResponse.result}");
         
         final localsJson = jsonDecode(localsResponse.result as String);
         final locals = localsJson['locals'] as Map;
         
         print("Parsed Locals Keys: ${locals.keys.toList()}");
         
         // Verify List
         if (locals.containsKey('list')) {
            print("List: ${locals['list']}");
            final handle = locals['list']['handle'];
            if (handle != null) {
               final objRes = await FluxServiceExtensionHandlers.getObject(vm, {'handle': handle.toString()});
               print("List Object: ${objRes.result}");
            }
         }
         
          // Verify Map
         if (locals.containsKey('map')) {
            print("Map: ${locals['map']}");
            final handle = locals['map']['handle'];
            if (handle != null) {
               final objRes = await FluxServiceExtensionHandlers.getObject(vm, {'handle': handle.toString()});
               print("Map Object: ${objRes.result}");
            }
         }
      } else {
        print("Did not pause! (Check line numbers)");
      }

  } catch (e, stack) {
    print("Error: $e");
    print(stack);
  }
}
