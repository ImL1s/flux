import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:watcher/watcher.dart';

/// Command to run Flux scripts with optional hot-reload
class RunCommand extends Command<void> {
  @override
  final String name = 'run';

  @override
  final String description = 'Run a Flux script with optional hot-reload';

  RunCommand() {
    argParser
      ..addFlag(
        'watch',
        abbr: 'w',
        help: 'Watch for file changes and re-run automatically',
        negatable: false,
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Show verbose output',
        negatable: false,
      );
  }

  @override
  Future<void> run() async {
    final args = argResults!;

    if (args.rest.isEmpty) {
      usageException('Please provide a Flux script to run');
    }

    final filePath = args.rest.first;
    final watch = args['watch'] as bool;
    final verbose = args['verbose'] as bool;

    final file = File(filePath);

    if (!file.existsSync()) {
      stderr.writeln('Error: File not found: $filePath');
      exit(1);
    }

    if (watch) {
      await _runWithWatch(file, verbose);
    } else {
      _runOnce(file, verbose);
    }
  }

  void _runOnce(File file, bool verbose) {
    try {
      final source = file.readAsStringSync();
      if (verbose) {
        print('[Flux] Running: ${file.path}');
      }
      _execute(source, file.path, verbose);
    } catch (e) {
      stderr.writeln('Error reading file: $e');
      exit(1);
    }
  }

  Future<void> _runWithWatch(File file, bool verbose) async {
    print('👀 Watching ${file.path} for changes...');
    print('   Press Ctrl+C to stop.\n');

    // Initial run
    _runOnce(file, verbose);

    // Watch for changes
    final watcher = FileWatcher(file.path);
    
    await for (final event in watcher.events) {
      if (event.type == ChangeType.MODIFY) {
        print('\n🔄 File changed, re-running...\n');
        _runOnce(file, verbose);
      }
    }
  }

  void _execute(String source, String fileName, bool verbose) {
    try {
      // Tokenize
      final tokens = Lexer(source).tokenize();
      if (verbose) {
        print('[Flux] Tokenized: ${tokens.length} tokens');
      }

      // Parse
      final parser = Parser(tokens);
      final unit = parser.parse();
      if (verbose) {
        print('[Flux] Parsed successfully');
      }

      // Compile
      final compiler = Compiler(unit: unit);
      final function = compiler.endCompiler();
      if (verbose) {
        print('[Flux] Compiled successfully');
      }

      // Execute
      final vm = VM();
      vm.onPrint = (msg) => print('[Output]: $msg');

      final result = vm.runChunk(function.chunk);

      if (result == InterpretResult.runtimeError) {
        stderr.writeln('[Flux] Runtime error occurred');
      } else if (verbose) {
        print('[Flux] Execution completed successfully');
      }
    } on ParseError catch (e) {
      stderr.writeln('Parse error in $fileName: ${e.message}');
    } catch (e) {
      stderr.writeln('Error in $fileName: $e');
    }
  }
}
