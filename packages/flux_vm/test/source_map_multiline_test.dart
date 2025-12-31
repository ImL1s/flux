import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'dart:io';

void main() {
  group('Multi-line Source Maps', () {
    test('Error in multi-line List', () {
      final vm = VM();
      final logs = <String>[];
      vm.onPrint = (msg) => logs.add(msg);

      final source = '''
        var list = [
          1,
          2,
          3 - "err" // Line 4
        ];
      ''';

      vm.interpret(source);
      expect(logs.any((l) => l.contains('at script() [line 4]')), isTrue);
    });

    test('Error in multi-line Map', () {
      final vm = VM();
      final logs = <String>[];
      vm.onPrint = (msg) => logs.add(msg);

      final source = '''
        var map = {
          "a": 1,
          "b": 2 - "err" // Line 3
        };
      ''';

      vm.interpret(source);
      expect(logs.any((l) => l.contains('at script() [line 3]')), isTrue);
    });

    test('Error in multi-line Function Call', () {
      final vm = VM();
      final logs = <String>[];
      vm.onPrint = (msg) => logs.add(msg);

      final source = '''
        fn add(a, b) { return a + b; } // Line 1
        add(                          // Line 2
          1,                          // Line 3
          2 - "err"                   // Line 4
        );
      ''';

      vm.interpret(source);
      expect(logs.any((l) => l.contains('at script() [line 4]')), isTrue);
    });

    test('Error in nested multi-line structures', () {
      final vm = VM();
      final logs = <String>[];
      vm.onPrint = (msg) => logs.add(msg);

      final source = '''
        var data = {
          "list": [
            1,
            {
              "key": 100 - "err" // Line 5
            }
          ]
        };
      ''';

      vm.interpret(source);
      expect(logs.any((l) => l.contains('at script() [line 5]')), isTrue);
    });

    test('Stack trace shows original error site after catch', () {
      final vm = VM();
      final logs = <String>[];
      vm.onPrint = (msg) => logs.add(msg);

      final source = '''
        fn fail() {
          1 - "err"; // Line 2
        }

        fn wrapper() {
          try {
            fail(); // Line 7
          } catch (e) {
            throw e; // Line 9: Re-throw
          }
        }

        wrapper(); // Line 13
      ''';

      vm.interpret(source);
      
      expect(logs.any((l) => l.contains('at fail() [line 2]')), isTrue);
      expect(logs.any((l) => l.contains('at wrapper() [line 7]')), isTrue);
      expect(logs.any((l) => l.contains('at script() [line 13]')), isTrue);
    });
  });
}
