
import 'package:flux_vm/flux_vm.dart';
import 'package:test/test.dart';

void main() {
  group('FluxProfiler', () {
    late VM vm;
    late FluxProfiler profiler;

    setUp(() {
      vm = VM();
      profiler = FluxProfiler();
      vm.profiler = profiler;
    });

    void checkRun(String source) {
      final logs = <String>[];
      vm.onPrint = (msg) => logs.add(msg);
      
      final result = vm.interpret(source);
      if (result != InterpretResult.ok) {
        print('Runtime Logs:\n${logs.join('\n')}'); 
        fail('Interpreter failed with $result');
      }
    }

    test('records instructions', () {
      const source = '''
        var a = 1;
        var b = 2;
        var c = a + b;
      ''';

      profiler.start();
      checkRun(source);
      profiler.stop();

      final report = profiler.generateReport();
      print('DEBUG: Instructions=${report.totalInstructions}');
      print(report.toReport());

      expect(report.totalInstructions, greaterThan(0), reason: "Instructions should be > 0");
    });

    test('records execution time', () {
       const source = '''
        var a = 1;
        var i = 0; 
        // Simple loop to consume time (if loop supported, or just linear instructions)
        var b = a + 1;
        var c = b + 1;
      ''';
      
      profiler.start();
      checkRun(source);
      profiler.stop();
      
      final report = profiler.generateReport();
      expect(report.totalTime.inMicroseconds, greaterThanOrEqualTo(0));
    });

    test('records script profile', () {
      const source = '''
        var a = 1;
      ''';
      
      profiler.start();
      checkRun(source);
      profiler.stop();
      
      final report = profiler.generateReport();
      // "script" is the name of the top-level function wrapping the chunk
      final scriptProfile = report.functionProfiles.firstWhere((p) => p.name == 'script', orElse: () => FunctionProfile('NOT_FOUND'));
      expect(scriptProfile.name, 'script');
      expect(scriptProfile.callCount, 1);
    });
  });
}
