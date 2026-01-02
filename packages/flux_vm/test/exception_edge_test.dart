import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';

void main() {
  group('Exception Handling Edge Cases', () {
    late VM vm;
    late List<String> logs;

    setUp(() {
      vm = VM();
      logs = [];
      vm.onPrint = (msg) => logs.add(msg);
    });

    void runScript(String source) {
      final tokens = Lexer(source).tokenize();
      final parser = Parser(tokens);
      final ast = parser.parse();
      final compiler = Compiler(unit: ast);
      final function = compiler.endCompiler();
      vm.runChunk(function.chunk);
    }

    test('Nested try-catch blocks', () {
      const source = '''
        try {
          print("Outer try");
          try {
             print("Inner try");
             throw "Basic Error";
          } catch (e) {
             print("Inner caught: " + e);
          }
          print("Outer continuing");
        } catch (e) {
          print("Outer caught: " + e);
        }
      ''';
      
      runScript(source);
      
      expect(logs, [
        'Outer try',
        'Inner try',
        'Inner caught: Basic Error',
        'Outer continuing'
      ]);
    });

    test('Rethrow from inner catch', () {
      const source = '''
        try {
          try {
             throw "Critical fail";
          } catch (e) {
             print("Inner logging: " + e);
             throw e; // Rethrow
          }
        } catch (e) {
          print("Outer caught: " + e);
        }
      ''';

      runScript(source);

      expect(logs, [
        'Inner logging: Critical fail',
        'Outer caught: Critical fail'
      ]);
    });

    test('Throwing non-string values', () {
      const source = '''
        try {
          throw 404;
        } catch (e) {
          print("Caught error code: " + toString(e));
        }
      ''';

      runScript(source);
      expect(logs, ['Caught error code: 404']);
    });
    
    test('Throwing nil', () {
      const source = '''
        try {
          throw nil;
        } catch (e) {
          if (e == nil) {
            print("Caught nil");
          } else {
             print("Caught something else");
          }
        }
      ''';

      runScript(source);
      expect(logs, ['Caught nil']);
    });

    test('Stack unwinding cleans up locals', () {
      // This tests ensures that when we jump out of a scope due to error,
      // the stack is restored to the correct height for the catch block.
      const source = '''
        var top = "top";
        try {
          var a = 1;
          var b = 2;
          var c = 3;
          throw "boom";
        } catch (e) {
           // At this point a,b,c should be popped. 
           // Only 'top' and 'e' should be accessible/on stack effectively.
           // We can verify stack clean up by declaring new vars which should reuse slots
           var d = 4;
           print("Recovered with d=" + toString(d));
        }
        print("Top is " + top);
      ''';
      
      runScript(source);
      expect(logs, [
        'Recovered with d=4',
        'Top is top'
      ]);
    });
  });
}
