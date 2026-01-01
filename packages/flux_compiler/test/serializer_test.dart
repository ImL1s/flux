import 'package:test/test.dart';
import 'package:flux_compiler/flux_compiler.dart';

void main() {
  group('BytecodeSerializer/Deserializer Round-trip', () {
    test('simple script round-trip', () {
      const source = '''
var x = 10;
print(x);
''';
      final lexer = Lexer(source);
      final parser = Parser(lexer.tokenize());
      final unit = parser.parse();
      final compiler = Compiler(unit: unit);
      final original = compiler.endCompiler();

      // Serialize
      final serializer = BytecodeSerializer();
      final bytes = serializer.serialize(original);

      // Deserialize
      final deserializer = BytecodeDeserializer();
      final restored = deserializer.deserialize(bytes);

      // Verify
      expect(restored.name, equals(original.name));
      expect(restored.arity, equals(original.arity));
      expect(restored.isAsync, equals(original.isAsync));
      expect(restored.chunk.code, equals(original.chunk.code));
      expect(restored.chunk.constants.length, equals(original.chunk.constants.length));
    });

    test('function with parameters round-trip', () {
      const source = '''
fn add(a, b) {
  return a + b;
}
var result = add(1, 2);
''';
      final lexer = Lexer(source);
      final parser = Parser(lexer.tokenize());
      final unit = parser.parse();
      final compiler = Compiler(unit: unit);
      final original = compiler.endCompiler();

      final serializer = BytecodeSerializer();
      final bytes = serializer.serialize(original);

      final deserializer = BytecodeDeserializer();
      final restored = deserializer.deserialize(bytes);

      expect(restored.name, equals(original.name));
      expect(restored.chunk.code, equals(original.chunk.code));
      
      // Check that nested function constant was restored
      final originalFn = original.chunk.constants.whereType<CompiledFunction>().firstOrNull;
      final restoredFn = restored.chunk.constants.whereType<CompiledFunction>().firstOrNull;
      expect(restoredFn, isNotNull);
      expect(restoredFn!.name, equals(originalFn!.name));
      expect(restoredFn.arity, equals(originalFn.arity));
      expect(restoredFn.paramNames, equals(originalFn.paramNames));
    });

    test('class round-trip', () {
      const source = '''
class Counter {
  fn increment() {
    print("increment called");
  }
}
''';
      final lexer = Lexer(source);
      final parser = Parser(lexer.tokenize());
      final unit = parser.parse();
      final compiler = Compiler(unit: unit);
      final original = compiler.endCompiler();

      final serializer = BytecodeSerializer();
      final bytes = serializer.serialize(original);

      final deserializer = BytecodeDeserializer();
      final restored = deserializer.deserialize(bytes);

      expect(restored.chunk.code, equals(original.chunk.code));

      final originalClass = original.chunk.constants.whereType<CompiledClass>().firstOrNull;
      final restoredClass = restored.chunk.constants.whereType<CompiledClass>().firstOrNull;
      expect(restoredClass, isNotNull);
      expect(restoredClass!.name, equals(originalClass!.name));
      expect(restoredClass.fields, equals(originalClass.fields));
      expect(restoredClass.methods.keys, equals(originalClass.methods.keys));
    });
  });
}
