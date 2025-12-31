import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'dart:async';
import 'dart:io';

void main() {
  group('Async Source Maps', () {
    test('Error after await reports correct line', () async {
      final vm = VM();
      final logs = <String>[];
      vm.onPrint = (msg) => logs.add(msg);

      // Register a native delay function
      vm.globals['delay'] = NativeFunction('delay', 0, (args) async {
        await Future.delayed(Duration(milliseconds: 10));
        return null;
      });

      final source = '''
        async fn test() {
          print("Before await")
          await delay() // Line 3
          print("After await")
          1 - "err"    // Line 5: Error here
        }
        
        test()
      ''';

      // We need to use FluxRuntime or manual resume management because VM.interpret 
      // returns InterpretResult.awaiting for top-level awaits.
      // But here test() is called without await at top level, so test() returns a Coroutine.
      
      vm.interpret(source);
      
      // Wait for async execution
      for (int i = 0; i < 10; i++) {
        await Future.delayed(Duration(milliseconds: 20));
        if (logs.any((l) => l.contains('Runtime Error'))) break;
      }
      
      
      // Check if error was logged
      expect(logs.any((l) => l.contains('Runtime Error')), isTrue);
      expect(logs.any((l) => l.contains('at test() [line 5]')), isTrue);
    });

    test('Nested async traces', () async {
      final vm = VM();
      final logs = <String>[];
      vm.onPrint = (msg) => logs.add(msg);

      vm.globals['delay'] = NativeFunction('delay', 0, (args) async {
        await Future.delayed(Duration(milliseconds: 10));
        return null;
      });

      final source = '''
        async fn level2() {
          await delay()  // Line 2
          1 - "err"     // Line 3: Error
        }
        
        async fn level1() {
          await level2() // Line 7
        }
        
        level1()         // Line 10
      ''';

      vm.interpret(source);
      
      for (int i = 0; i < 10; i++) {
        await Future.delayed(Duration(milliseconds: 20));
        if (logs.any((l) => l.contains('Runtime Error'))) break;
      }

      
      expect(logs.any((l) => l.contains('at level2() [line 3]')), isTrue);
      expect(logs.any((l) => l.contains('at level1() [line 7]')), isTrue);
      expect(logs.any((l) => l.contains('at script() [line 10]')), isTrue);
    });
  });
}
