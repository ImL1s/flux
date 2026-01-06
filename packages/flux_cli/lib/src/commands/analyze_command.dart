import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:flux_compiler/flux_compiler.dart';

/// Command to analyze Flux scripts for errors and warnings
class AnalyzeCommand extends Command<void> {
  @override
  final String name = 'analyze';

  @override
  final String description = 'Analyze Flux scripts for errors and warnings';

  AnalyzeCommand() {
    argParser
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Show verbose output including info messages',
        negatable: false,
      )
      ..addFlag(
        'fatal-warnings',
        help: 'Treat warnings as errors',
        negatable: false,
      );
  }

  @override
  Future<void> run() async {
    final args = argResults!;

    if (args.rest.isEmpty) {
      usageException('Please provide a Flux script or directory to analyze');
    }

    final path = args.rest.first;
    final verbose = args['verbose'] as bool;
    final fatalWarnings = args['fatal-warnings'] as bool;

    final target = FileSystemEntity.typeSync(path);

    List<File> files = [];

    if (target == FileSystemEntityType.file) {
      files.add(File(path));
    } else if (target == FileSystemEntityType.directory) {
      final dir = Directory(path);
      files = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.flux'))
          .toList();
    } else {
      stderr.writeln('Error: Path not found: $path');
      exit(1);
    }

    if (files.isEmpty) {
      print('No .flux files found to analyze.');
      return;
    }

    print('Analyzing ${files.length} file(s)...\n');

    int errorCount = 0;
    int warningCount = 0;
    int infoCount = 0;

    for (final file in files) {
      final result = _analyzeFile(file, verbose);
      errorCount += result.errors;
      warningCount += result.warnings;
      infoCount += result.infos;
    }

    print('');
    print('═══════════════════════════════════════════');
    print('Analysis complete:');
    print('  Errors:   $errorCount');
    print('  Warnings: $warningCount');
    if (verbose) {
      print('  Info:     $infoCount');
    }
    print('═══════════════════════════════════════════');

    if (errorCount > 0 || (fatalWarnings && warningCount > 0)) {
      exit(1);
    }
  }

  _AnalysisResult _analyzeFile(File file, bool verbose) {
    int errors = 0;
    int warnings = 0;
    int infos = 0;

    try {
      final source = file.readAsStringSync();

      // Tokenize
      try {
        final tokens = Lexer(source).tokenize();

        // Parse
        try {
          final parser = Parser(tokens);
          parser.parse();

          if (parser.errors.isNotEmpty) {
            for (final e in parser.errors) {
              print('✗ ${file.path}:${e.token.line}:${e.token.column}');
              print('  Error: ${e.message}');
              errors++;
            }
          } else if (verbose) {
            print('✓ ${file.path}: OK');
            infos++;
          }
        } catch (e) {
          print('✗ ${file.path}');
          print('  Parser error: $e');
          errors++;
        }
      } catch (e) {
        print('✗ ${file.path}');
        print('  Lexer error: $e');
        errors++;
      }
    } catch (e) {
      print('✗ ${file.path}');
      print('  Could not read file: $e');
      errors++;
    }

    return _AnalysisResult(errors: errors, warnings: warnings, infos: infos);
  }
}

class _AnalysisResult {
  final int errors;
  final int warnings;
  final int infos;

  _AnalysisResult({
    required this.errors,
    required this.warnings,
    required this.infos,
  });
}
