import 'dart:io';
import 'package:test/test.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  group('End-to-End .flx File Test', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('flux_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('compile, write .flx, load .flx, and execute', () {
      // 1. Compile a Flux script
      const source = '''
var greeting = "Hello from .flx!";
print(greeting);
var sum = 10 + 20;
print(sum);
''';
      final lexer = Lexer(source);
      final parser = Parser(lexer.tokenize());
      final unit = parser.parse();
      final compiler = Compiler(unit: unit);
      final original = compiler.endCompiler();

      // 2. Serialize to bytes
      final serializer = BytecodeSerializer();
      final bytes = serializer.serialize(original);

      // 3. Write to .flx file
      final flxPath = '${tempDir.path}/test_script.flx';
      File(flxPath).writeAsBytesSync(bytes);

      // 4. Read .flx file from disk
      final loadedBytes = File(flxPath).readAsBytesSync();
      expect(loadedBytes.length, equals(bytes.length));

      // 5. Deserialize
      final deserializer = BytecodeDeserializer();
      final restored = deserializer.deserialize(loadedBytes);

      // 6. Execute in VM
      final output = <String>[];
      final vm = VM();
      vm.onPrint = (msg) => output.add(msg);

      final result = vm.runChunk(restored.chunk);

      // 7. Verify execution
      expect(result, equals(InterpretResult.ok));
      expect(output, contains('Hello from .flx!'));
      expect(output, anyOf(contains('30'), contains('30.0')));
    });


  });
}
