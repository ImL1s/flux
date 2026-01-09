import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:test/test.dart';

void main() {
  group('VM Basic Operations', () {
    late VM vm;

    setUp(() {
      vm = VM();
    });

    test('has stdlib loaded on init', () {
      // VM now loads stdlib on init, so globals should have stdlib functions
      expect(vm.globals.containsKey('len'), true);
      expect(vm.globals.containsKey('sqrt'), true);
    });

    test('sets globals', () {
      vm.globals['test'] = 42;
      expect(vm.globals['test'], 42);
    });
  });

  group('VM State Management', () {
    late VM vm;

    setUp(() {
      vm = VM();
    });

    test('manages widget state', () {
      expect(vm.widgetState, isEmpty);

      // Simulate state initialization
      vm.widgetState['count'] = 0;
      expect(vm.widgetState['count'], 0);

      // Simulate state update
      vm.widgetState['count'] = 5;
      expect(vm.widgetState['count'], 5);
    });

    test('triggers onStateChange callback', () {
      String? changedName;
      Object? changedValue;

      vm.onStateChange = (name, value) {
        changedName = name;
        changedValue = value;
      };

      vm.widgetState['count'] = 10;
      vm.onStateChange?.call('count', 10);

      expect(changedName, 'count');
      expect(changedValue, 10);
    });

    test('clears state', () {
      vm.widgetState['a'] = 1;
      vm.widgetState['b'] = 2;
      vm.clearState();
      expect(vm.widgetState, isEmpty);
    });
  });

  group('VM Async Support', () {
    test('has awaiting state', () {
      final vm = VM();
      expect(vm.isAwaiting, false);
    });

    test('resumeFromAwait returns error when not awaiting', () {
      final vm = VM();
      final result = vm.resumeFromAwait(42);
      expect(result, InterpretResult.runtimeError);
    });

    test('pending future is null initially', () {
      final vm = VM();
      expect(vm.pendingFuture, isNull);
    });
  });

  group('VM Execution', () {
    test('executes simple bytecode', () {
      final vm = VM();

      // Simple compile and run
      final lexer = Lexer('let x = 42');
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final result = compiler.endCompiler();

      final interpretResult = vm.runChunk(result.chunk);
      expect(interpretResult, InterpretResult.ok);
    });

    test('executes print statement', () {
      final vm = VM();

      final lexer = Lexer('print("Hello")');
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final result = compiler.endCompiler();

      final interpretResult = vm.runChunk(result.chunk);
      expect(interpretResult, InterpretResult.ok);
    });

    test('executes arithmetic', () {
      final vm = VM();

      final lexer = Lexer('print(2 + 3 * 4)');
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final result = compiler.endCompiler();

      final interpretResult = vm.runChunk(result.chunk);
      expect(interpretResult, InterpretResult.ok);
    });

    test('executes function call', () {
      final vm = VM();

      final source = '''
        fn add(a, b) {
          return a + b;
        }
        print(add(2, 3));
      ''';
      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final result = compiler.endCompiler();

      String? printedValue;
      vm.onPrint = (msg) => printedValue = msg;

      final interpretResult = vm.runChunk(result.chunk);
      expect(interpretResult, InterpretResult.ok);
      expect(printedValue, '5');
    });

    test('executes if statement', () {
      final vm = VM();

      final source = '''
        var x = 10;
        if (x > 5) {
          print("greater");
        } else {
          print("less");
        }
      ''';
      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final result = compiler.endCompiler();

      String? printedValue;
      vm.onPrint = (msg) => printedValue = msg;

      final interpretResult = vm.runChunk(result.chunk);
      expect(interpretResult, InterpretResult.ok);
      expect(printedValue, 'greater');
    });

    test('executes while loop', () {
      final vm = VM();

      final source = '''
        var i = 0;
        while (i < 3) {
          i = i + 1;
        }
        print(i);
      ''';
      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final result = compiler.endCompiler();

      String? printedValue;
      vm.onPrint = (msg) => printedValue = msg;

      final interpretResult = vm.runChunk(result.chunk);
      expect(interpretResult, InterpretResult.ok);
      expect(printedValue, '3');
    });
  });
}
