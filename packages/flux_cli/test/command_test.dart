import 'dart:io';
import 'package:test/test.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  group('Flux CLI Commands', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('flux_cli_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('flux build command produces valid .flx file', () {
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

      // We assume we are running tests from the package root or a standard dart test environment
      // where 'bin/flux.dart' is accessible relative to the package root.
      // If running via `dart test`, current directory is usually the package root.

      final result = Process.runSync(
        'dart',
        ['run', 'bin/flux.dart', 'build', sourcePath, '-o', flxPath],
      );

      // Check build succeeded
      expect(result.exitCode, equals(0),
          reason: 'Build failed: ${result.stderr}\nStdout: ${result.stdout}');
      expect(File(flxPath).existsSync(), isTrue);

      // Load and execute to verify content correctness
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
