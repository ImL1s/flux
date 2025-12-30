import 'dart:io';
import 'package:test/test.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

/// Tests for Flux CLI functionality
void main() {
  group('Flux Script Execution', () {
    test('executes simple print statement', () {
      final source = 'print("Hello from Flux!");';
      final output = <String>[];
      
      final result = _runFlux(source, onPrint: output.add);
      
      expect(result, InterpretResult.ok);
      expect(output, ['Hello from Flux!']);
    });

    test('executes arithmetic expressions', () {
      final source = '''
        var a = 10;
        var b = 20;
        print(a + b);
        print(a * b);
      ''';
      final output = <String>[];
      
      final result = _runFlux(source, onPrint: output.add);
      
      expect(result, InterpretResult.ok);
      expect(output, ['30', '200']);
    });

    test('executes function definitions and calls', () {
      final source = '''
        fn greet(name) {
          return "Hello, " + name + "!";
        }
        print(greet("World"));
      ''';
      final output = <String>[];
      
      final result = _runFlux(source, onPrint: output.add);
      
      expect(result, InterpretResult.ok);
      expect(output, ['Hello, World!']);
    });

    test('executes while loops', () {
      final source = '''
        var i = 0;
        var sum = 0;
        while (i < 5) {
          sum = sum + i;
          i = i + 1;
        }
        print(sum);
      ''';
      final output = <String>[];
      
      final result = _runFlux(source, onPrint: output.add);
      
      expect(result, InterpretResult.ok);
      expect(output, ['10']); // 0+1+2+3+4 = 10
    });

    test('executes if/else statements', () {
      final source = '''
        var x = 10;
        if (x > 5) {
          print("big");
        } else {
          print("small");
        }
      ''';
      final output = <String>[];
      
      final result = _runFlux(source, onPrint: output.add);
      
      expect(result, InterpretResult.ok);
      expect(output, ['big']);
    });

    test('handles recursive functions (fibonacci)', () {
      final source = '''
        fn fib(n) {
          if (n <= 1) { return n; }
          return fib(n - 1) + fib(n - 2);
        }
        print(fib(10));
      ''';
      final output = <String>[];
      
      final result = _runFlux(source, onPrint: output.add);
      
      expect(result, InterpretResult.ok);
      expect(output, ['55']);
    });

    test('handles closures', () {
      final source = '''
        fn makeCounter() {
          var count = 0;
          fn increment() {
            count = count + 1;
            return count;
          }
          return increment;
        }
        var counter = makeCounter();
        print(counter());
        print(counter());
        print(counter());
      ''';
      final output = <String>[];
      
      final result = _runFlux(source, onPrint: output.add);
      
      expect(result, InterpretResult.ok);
      expect(output, ['1', '2', '3']);
    });

    test('handles try/catch exceptions', () {
      final source = '''
        try {
          throw "Test error";
        } catch (e) {
          print("Caught: " + e);
        }
      ''';
      final output = <String>[];
      
      final result = _runFlux(source, onPrint: output.add);
      
      expect(result, InterpretResult.ok);
      expect(output, ['Caught: Test error']);
    });

    test('handles list operations', () {
      final source = '''
        var list = [1, 2, 3];
        push(list, 4);
        print(list.length);
        print(list[3]);
      ''';
      final output = <String>[];
      
      final result = _runFlux(source, onPrint: output.add);
      
      expect(result, InterpretResult.ok);
      expect(output, ['4', '4']);
    });
  });

  group('Error Handling', () {
    test('throws ParseError for invalid syntax', () {
      final source = 'var x = ;'; // Invalid syntax
      
      bool caughtError = false;
      try {
        _runFlux(source);
      } on ParseError {
        caughtError = true;
      }
      
      expect(caughtError, isTrue);
    });

    test('reports undefined variable errors', () {
      final source = 'print(undefinedVar);';
      
      final result = _runFlux(source);
      expect(result, InterpretResult.runtimeError);
    });
  });
}

/// Helper function to run Flux code
InterpretResult _runFlux(String source, {void Function(String)? onPrint}) {
  final tokens = Lexer(source).tokenize();
  final parser = Parser(tokens);
  final unit = parser.parse();
  
  if (parser.errors.isNotEmpty) {
    throw parser.errors.first;
  }
  
  final compiler = Compiler(unit: unit);
  final function = compiler.endCompiler();
  
  final vm = VM();
  if (onPrint != null) {
    vm.onPrint = onPrint;
  }
  
  return vm.runChunk(function.chunk);
}
