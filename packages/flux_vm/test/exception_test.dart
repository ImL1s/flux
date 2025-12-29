import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:test/test.dart';

class FluxCompiler {
  static CompiledFunction compile(String source) {
    final tokens = Lexer(source).tokenize();
    final parser = Parser(tokens);
    final unit = parser.parse();
    final compiler = Compiler(unit: unit);
    return compiler.endCompiler();
  }
}

void main() {
  late VM vm;
  late List<String> outputs;

  setUp(() {
    vm = VM();
    outputs = [];
    vm.onPrint = (msg) => outputs.add(msg);
  });

  group('Exception Handling', () {
    test('try-catch catches thrown exception', () {
      final source = '''
        try {
          throw "error message";
        } catch (e) {
          print(e);
        }
      ''';
      
      final unit = FluxCompiler.compile(source);
      final result = vm.runChunk(unit.chunk);
      
      expect(result, InterpretResult.ok);
      expect(outputs, equals(["error message"]));
    });
    
    test('try block without exception runs normally', () {
      final source = '''
        try {
          print("no error");
        } catch (e) {
          print("caught");
        }
      ''';
      
      final unit = FluxCompiler.compile(source);
      final result = vm.runChunk(unit.chunk);
      
      expect(result, InterpretResult.ok);
      expect(outputs, equals(["no error"]));
    });
    
    test('catch block does not run when no exception', () {
      final source = '''
        try {
          var x = 1 + 2;
          print(x);
        } catch (e) {
          print("should not print");
        }
      ''';
      
      final unit = FluxCompiler.compile(source);
      final result = vm.runChunk(unit.chunk);
      
      expect(result, InterpretResult.ok);
      expect(outputs, equals(["3"]));
    });
    
    test('exception variable is accessible in catch', () {
      final source = '''
        try {
          throw 42;
        } catch (myError) {
          print(myError);
        }
      ''';
      
      final unit = FluxCompiler.compile(source);
      final result = vm.runChunk(unit.chunk);
      
      expect(result, InterpretResult.ok);
      expect(outputs, equals(["42"]));
    });
    
    test('throw string exception', () {
      final source = '''
        try {
          throw "custom error";
        } catch (e) {
          print("caught: " + e);
        }
      ''';
      
      final unit = FluxCompiler.compile(source);
      final result = vm.runChunk(unit.chunk);
      
      expect(result, InterpretResult.ok);
      expect(outputs, equals(["caught: custom error"]));
    });
    
    test('nested try-catch (inner catches)', () {
      final source = '''
        try {
          try {
            throw "inner error";
          } catch (e1) {
            print("inner: " + e1);
          }
          print("outer continues");
        } catch (e2) {
          print("outer catch");
        }
      ''';
      
      final unit = FluxCompiler.compile(source);
      final result = vm.runChunk(unit.chunk);
      
      expect(result, InterpretResult.ok);
      expect(outputs, equals(["inner: inner error", "outer continues"]));
    });
    
    test('code after try-catch continues', () {
      final source = '''
        try {
          throw "error";
        } catch (e) {
          print("caught");
        }
        print("after");
      ''';
      
      final unit = FluxCompiler.compile(source);
      final result = vm.runChunk(unit.chunk);
      
      expect(result, InterpretResult.ok);
      expect(outputs, equals(["caught", "after"]));
    });
    
    test('throw propagates from function to outer catch', () {
      final source = '''
        fn inner() {
          throw "from inner";
        }
        
        try {
          inner();
        } catch (e) {
          print(e);
        }
      ''';
      
      final unit = FluxCompiler.compile(source);
      final result = vm.runChunk(unit.chunk);
      
      expect(result, InterpretResult.ok);
      expect(outputs, equals(["from inner"]));
    });
    
    test('throw propagates through multiple function calls', () {
      final source = '''
        fn level1() {
          throw "deep error";
        }
        
        fn level2() {
          level1();
        }
        
        fn level3() {
          level2();
        }
        
        try {
          level3();
        } catch (e) {
          print("caught: " + e);
        }
        print("done");
      ''';
      
      final unit = FluxCompiler.compile(source);
      final result = vm.runChunk(unit.chunk);
      
      expect(result, InterpretResult.ok);
      expect(outputs, equals(["caught: deep error", "done"]));
    });
    
    test('exception in function with local try-catch stays local', () {
      final source = '''
        fn mayFail() {
          try {
            throw "local error";
          } catch (e) {
            print("inner caught: " + e);
          }
          print("function continues");
        }
        
        try {
          mayFail();
        } catch (e) {
          print("outer caught");
        }
        print("done");
      ''';
      
      final unit = FluxCompiler.compile(source);
      final result = vm.runChunk(unit.chunk);
      
      expect(result, InterpretResult.ok);
      expect(outputs, equals(["inner caught: local error", "function continues", "done"]));
    });
  });
}
