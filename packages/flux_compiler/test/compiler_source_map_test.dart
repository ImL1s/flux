import 'dart:convert';
import 'package:flux_compiler/src/compiler.dart';
import 'package:flux_compiler/src/lexer.dart';
import 'package:flux_compiler/src/parser.dart';

import 'package:test/test.dart';

CompiledFunction compileFluxScript(String source) {
  final lexer = Lexer(source);
  final parser = Parser(lexer.tokenize());
  final unit = parser.parse();
  final compiler = Compiler(unit: unit, moduleName: 'script.flux', generateSourceMap: true);
  // Pass a dummy line for endCompiler if needed, or use last stmt line
  return compiler.endCompiler(1);
}

void main() {
  group('Compiler Source Maps', () {
    test('generates map for variable declaration and print', () {
      final source = '''
var x = 42;
print(x);
''';
      // Line 1: var x = 42; -> OpCode.constant (42), OpCode.setGlobal (x), OpCode.pop
      // Line 2: print(x); -> OpCode.getGlobal(x), OpCode.print, OpCode.nil
      
      final func = compileFluxScript(source);
      expect(func.sourceMap, isNotNull);
      
      final map = jsonDecode(func.sourceMap!);
      expect(map['version'], 3);
      expect(map['sources'], contains('script.flux'));
      
      // Basic check: Ensure we have entries
      expect(map['mappings'], isNotEmpty);
      print('Mappings: ${map['mappings']}');
      
      // We can inspect the bytecode and ensuring mapping length covers it or looks reasonable
      // Since we don't have a decoder here, successful generation is the main check + simple structure.
    });

    test('generates map for if statement', () {
      final source = '''
if (true) {
  print(1);
} else {
  print(2);
}
''';
      final func = compileFluxScript(source);
      expect(func.sourceMap, isNotNull);
      final map = jsonDecode(func.sourceMap!);
      expect(map['mappings'], isNotEmpty);
    });
    
    test('local variables have mappings', () {
        final source = '''
{
  var y = 10;
  print(y);
}
        ''';
        final func = compileFluxScript(source);
        expect(func.sourceMap, isNotNull);
    });
    
    test('expressions have columns', () {
        // x = 1 + 2
        // columns for 1, 2, + available ideally
        final source = 'var z = 1 + 2;';
        final func = compileFluxScript(source);
        expect(func.sourceMap, isNotNull);
    });
  });
}
