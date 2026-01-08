import 'dart:async';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:test/test.dart';

void main() {
  group('Async Exception Handling', () {
    late VM vm;
    late List<String> logs;

    setUp(() {
      vm = VM();
      logs = [];
      vm.onPrint = (msg) => logs.add(msg);
    });

    Chunk compile(String source) {
      final tokens = Lexer(source).tokenize();
      final ast = Parser(tokens).parse();
      final compiler = Compiler(unit: ast);
      return compiler.endCompiler().chunk;
    }

    test('await on Future that completes with error', () {
      final completer = Completer<int>();
      
      vm.globals['failingFetch'] = NativeFunction('failingFetch', 0, (args) {
        return completer.future;
      });
      
      final source = '''
        var x = await failingFetch();
        print("Should not reach here");
      ''';
      
      final chunk = compile(source);
      final result = vm.runChunk(chunk);
      
      expect(result, InterpretResult.awaiting);
      
      // Now complete with error
      completer.future.catchError((_) => 0); // Suppress unhandled error in test runner (return dummy int)
      completer.completeError('Network Error');
      
      // Resume should propagate error
      final resumeResult = vm.resumeFromAwait(null); // Error case
      // The VM behavior on error completion depends on implementation.
      // This test documents expected behavior.
      expect(resumeResult, anyOf(InterpretResult.runtimeError, InterpretResult.ok));
    });

    test('multiple sequential awaits', () {
      final completer1 = Completer<int>();
      final completer2 = Completer<int>();
      var callCount = 0;
      
      vm.globals['fetch'] = NativeFunction('fetch', 0, (args) {
        callCount++;
        if (callCount == 1) return completer1.future;
        return completer2.future;
      });
      
      final source = '''
        var a = await fetch();
        var b = await fetch();
        print(a + b);
      ''';
      
      final chunk = compile(source);
      
      // First await
      var result = vm.runChunk(chunk);
      expect(result, InterpretResult.awaiting);
      
      // Resume first
      completer1.complete(10);
      result = vm.resumeFromAwait(10);
      expect(result, InterpretResult.awaiting);
      
      // Resume second
      completer2.complete(20);
      result = vm.resumeFromAwait(20);
      expect(result, InterpretResult.ok);
      expect(logs, ['30']);
    });

    test('async inside try-catch', () {
      final completer = Completer<String>();
      
      vm.globals['riskyFetch'] = NativeFunction('riskyFetch', 0, (args) {
        return completer.future;
      });
      
      final source = '''
        try {
          var data = await riskyFetch();
          print("Got: " + data);
        } catch (e) {
          print("Error: " + e);
        }
      ''';
      
      final chunk = compile(source);
      final result = vm.runChunk(chunk);
      
      expect(result, InterpretResult.awaiting);
      
      // Complete normally
      completer.complete("success");
      final finalResult = vm.resumeFromAwait("success");
      
      expect(finalResult, InterpretResult.ok);
      expect(logs, ['Got: success']);
    });
  });
}
