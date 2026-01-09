import 'dart:async';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:test/test.dart';

void main() {
  group('VM Concurrency', () {
    late VM vm;

    setUp(() {
      vm = VM();
    });

    test('await on non-future value returns immediately', () {
      final source = '''
        var x = await 42;
        print(x);
      ''';

      String? output;
      vm.onPrint = (msg) => output = msg;

      final chunk = _compile(source);
      final result = vm.runChunk(chunk);

      expect(result, InterpretResult.ok);
      expect(output, '42');
      expect(vm.isAwaiting, false);
    });

    test('await on Dart Future suspends execution', () {
      final completer = Completer<int>();

      // Inject a native function that returns a Future
      vm.globals['fetchData'] =
          NativeFunction('fetchData', 0, (List<Object?> args) {
        return completer.future;
      });

      final source = '''
        print("Start");
        var x = await fetchData();
        print("End: " + x);
      ''';

      final logs = <String>[];
      vm.onPrint = (msg) => logs.add(msg);

      final chunk = _compile(source);
      final result = vm.runChunk(chunk);

      // Should be suspended
      expect(result, InterpretResult.awaiting);
      expect(vm.isAwaiting, true);
      expect(logs, ['Start']); // Executed up to await

      // Complete the future
      completer.complete(100);

      // Resume VM
      final resumeResult = vm.resumeFromAwait(100);

      expect(resumeResult, InterpretResult.ok);
      expect(logs, ['Start', 'End: 100']);
      expect(vm.isAwaiting, false);
    });

    test('async function call flow', () {
      // Test calling a Flux function that awaits
      final completer = Completer<String>();
      vm.globals['waitString'] =
          NativeFunction('waitString', 0, (List<Object?> args) {
        return completer.future;
      });

      final source = '''
        fn doAsync() {
           var s = await waitString();
           return "Got: " + s;
        }
        
        print(doAsync());
      ''';

      final logs = <String>[];
      vm.onPrint = (msg) => logs.add(msg);

      final chunk = _compile(source);
      final result = vm.runChunk(chunk);

      expect(result, InterpretResult.awaiting);

      // Resume
      final finalResult = vm.resumeFromAwait("Flux");

      expect(finalResult, InterpretResult.ok);
      expect(logs, ['Got: Flux']);
    });
  });
}

Chunk _compile(String source) {
  final lexer = Lexer(source);
  final tokens = lexer.tokenize();
  final parser = Parser(tokens);
  final ast = parser.parse();
  final compiler = Compiler(unit: ast);
  return compiler.endCompiler().chunk;
}
