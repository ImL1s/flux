import 'dart:io';
import 'package:test/test.dart';
import 'package:args/command_runner.dart';
import 'package:flux_cli/src/commands/create_command.dart';
import 'package:flux_cli/src/commands/run_command.dart';
import 'package:flux_cli/src/commands/analyze_command.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('flux_cli_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('CLI Commands Integration', () {
    test('create command generates correct files for basic template', () async {
      final runner = CommandRunner('flux', 'Flux CLI');
      runner.addCommand(CreateCommand());

      final projectName = 'test_project';
      final projectPath = '${tempDir.path}/$projectName';

      await runner.run(['create', projectPath, '--template', 'basic']);

      expect(Directory(projectPath).existsSync(), isTrue);
      expect(File('$projectPath/main.flux').existsSync(), isTrue);
      expect(File('$projectPath/flux.yaml').existsSync(), isTrue);
      
      final mainContent = File('$projectPath/main.flux').readAsStringSync();
      expect(mainContent, contains('fn main()'));
      expect(mainContent, contains('main();'));
    });

    test('analyze command reports no errors for basic template', () async {
      final runner = CommandRunner('flux', 'Flux CLI');
      runner.addCommand(CreateCommand());
      runner.addCommand(AnalyzeCommand());

      final projectName = 'test_analyze';
      final projectPath = '${tempDir.path}/$projectName';

      await runner.run(['create', projectPath]);
      
      // Analyze the created project
      // Need to capture stdout to verify but for now just check it doesn't throw
      await runner.run(['analyze', projectPath]);
    });

    test('run command executes basic template successfully', () async {
      final runner = CommandRunner('flux', 'Flux CLI');
      runner.addCommand(CreateCommand());
      runner.addCommand(RunCommand());

      final projectName = 'test_run';
      final projectPath = '${tempDir.path}/$projectName';

      await runner.run(['create', projectPath]);
      
      // Run the created project
      // Note: RunCommand uses FluxVM which prints to stdout. 
      // In a real test we'd capture this, but here we just verify it runs.
      await runner.run(['run', '$projectPath/main.flux']);
    });
  });
}
