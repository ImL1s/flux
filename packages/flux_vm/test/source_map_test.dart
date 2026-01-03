import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';


void main() {
  group('Source Maps', () {
    test('Runtime error reports correct line number', () {
      final vm = VM();
      final logs = <String>[];
      vm.onPrint = (msg) => logs.add(msg);

      final source = '''
        print("Start")
        var a = 1
        var b = "s"
        a - b // Error on line 4 (subtraction must be numbers)
      ''';

      final result = vm.interpret(source);
      
      expect(result, InterpretResult.runtimeError);
      // Subtraction of string from num throws TypeError in Dart
      expect(logs.any((l) => l.contains('subtype of type') || l.contains('Operands must be two numbers')), isTrue);
      // Stack trace check
      expect(logs.any((l) => l.contains('at script() [line 4]')), isTrue);
    });

    test('Stack trace shows function names and lines', () {
      final vm = VM();
      final logs = <String>[];
      vm.onPrint = (msg) => logs.add(msg);

      final source = '''
        fn a() {
          b()
        }
        
        fn b() {
          c()
        }
        
        fn c() {
          1 - "error" // Line 10
        }
        
        a()
      ''';

      final result = vm.interpret(source);
      
      expect(result, InterpretResult.runtimeError);
      
      // Check full trace
      // c() at line 10
      expect(logs.any((l) => l.contains('at c() [line 10]')), isTrue);
      // b() called c() at line 2 (wait, let me recount)
      // Actually, looking at the code:
      // 1: fn a() {
      // 2:   b()
      // 3: }
      // 4: 
      // 5: fn b() {
      // 6:   c()
      // 7: }
      // 8: 
      // 9: fn c() {
      // 10:  1 - "error"
      // 11: }
      // 12:
      // 13: a()
      
      expect(logs.any((l) => l.contains('at b() [line 6]')), isTrue);
      expect(logs.any((l) => l.contains('at a() [line 2]')), isTrue);
      expect(logs.any((l) => l.contains('at script() [line 13]')), isTrue);
    });
  });
}
