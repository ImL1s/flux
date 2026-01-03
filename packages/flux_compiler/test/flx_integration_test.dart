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

    test('flux build command produces valid .flx file', () async {
      // Create a temp .flux source file
      final sourcePath = '${tempDir.path}/build_test.flux';
      const source = '''
var x = 5;
var y = 10;
print(x + y);
''';
      File(sourcePath).writeAsStringSync(source);

      // Run flux build command
      final flxPath = '${tempDir.path}/build_test.flx';

      // Find flux_cli package directory dynamically
      String? cliDir;
      final candidates = [
        '../flux_cli',
        'packages/flux_cli',
      ];

      for (final candidate in candidates) {
        if (Directory(candidate).existsSync()) {
          cliDir = candidate;
          break;
        }
      }

      if (cliDir == null) {
        // Search upwards for repo root
        var current = Directory.current;
        while (current.path != current.parent.path) {
          final repoCli = Directory('${current.path}/packages/flux_cli');
          if (repoCli.existsSync()) {
            cliDir = repoCli.path;
            break;
          }
          current = current.parent;
        }
      }

      final result = Process.runSync(
        'dart',
        ['run', 'bin/flux.dart', 'build', sourcePath, '-o', flxPath],
        workingDirectory: cliDir,
      );

      // Check build succeeded
      expect(result.exitCode, equals(0), reason: 'Build failed: ${result.stderr}');
      expect(File(flxPath).existsSync(), isTrue);

      // Load and execute
      final loadedBytes = File(flxPath).readAsBytesSync();
      final deserializer = BytecodeDeserializer();
      final restored = deserializer.deserialize(loadedBytes);

      final output = <String>[];
      final vm = VM();
      vm.onPrint = (msg) => output.add(msg);
      vm.runChunk(restored.chunk);

      expect(output, anyOf(contains('15'), contains('15.0')));
    });
  });
}
