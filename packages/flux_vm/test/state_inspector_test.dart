import 'package:test/test.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  group('State Inspector', () {
    late VM vm;
    late FluxDebugger debugger;

    setUp(() {
      vm = VM();
      debugger = FluxDebugger(vm);
      vm.debugger = debugger;
      debugger.attach();
    });

    tearDown(() {
      debugger.detach();
    });

    test('getCallStack returns frame info during breakpoint', () {
      // Simple test: just verify getCallStack works when paused
      final source = '''
fn test() {
  var x = 42;
  print(x);
}
test();
''';
      
      final ast = Parser(Lexer(source).tokenize()).parse();
      final compiler = Compiler(unit: ast, moduleName: 'test.flux');
      for (final decl in ast.declarations) {
        compiler.compile(decl);
      }
      final function = compiler.endCompiler();
      
      debugger.setBreakpoint('test.flux', 3); // Break at print(x)
      
      var result = vm.executeClosure(ObjClosure(function, []));
      
      expect(result, InterpretResult.paused);
      
      final callStack = debugger.getCallStack();
      expect(callStack.length, greaterThanOrEqualTo(1));
      
      // Top frame should be test
      expect(callStack[0].functionName, 'test');
    });

    test('getLocals returns local variables', () {
      final source = '''
fn test() {
  var a = 42;
  var b = "hello";
  print(a);
}
test();
''';
      
      final ast = Parser(Lexer(source).tokenize()).parse();
      final compiler = Compiler(unit: ast, moduleName: 'test.flux');
      for (final decl in ast.declarations) {
        compiler.compile(decl);
      }
      final function = compiler.endCompiler();
      
      debugger.setBreakpoint('test.flux', 4); // Break at print(a)
      
      var result = vm.executeClosure(ObjClosure(function, []));
      
      expect(result, InterpretResult.paused);
      
      final locals = debugger.getLocals();
      expect(locals['a'], {'type': 'primitive', 'kind': 'int', 'value': '42'});
      expect(locals['b'], {'type': 'primitive', 'kind': 'String', 'value': 'hello'});
    });

    test('getLocals works with function parameters', () {
      final source = '''
fn greet(name, count) {
  var msg = "Hello";
  print(msg);
}
greet("World", 3);
''';
      
      final ast = Parser(Lexer(source).tokenize()).parse();
      final compiler = Compiler(unit: ast, moduleName: 'test.flux');
      for (final decl in ast.declarations) {
        compiler.compile(decl);
      }
      final function = compiler.endCompiler();
      
      debugger.setBreakpoint('test.flux', 3); // Break at print(msg)
      
      var result = vm.executeClosure(ObjClosure(function, []));
      
      expect(result, InterpretResult.paused);
      
      final locals = debugger.getLocals();
      expect(locals['name'], {'type': 'primitive', 'kind': 'String', 'value': 'World'});
      expect(locals['count'], {'type': 'primitive', 'kind': 'int', 'value': '3'});
      expect(locals['msg'], {'type': 'primitive', 'kind': 'String', 'value': 'Hello'});
    });
  });
}
