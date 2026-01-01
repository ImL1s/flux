#!/usr/bin/env dart
/// Flux CLI - Run Flux scripts from command line
/// 
/// Usage: dart run flux_cli:flux <script.flux>

import 'dart:io';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_cli/src/commands/serve_command.dart';

const String version = '2.0.0';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _printHelp();
    return;
  }
  
  if (args.contains('--version') || args.contains('-v')) {
    print('Flux CLI v$version');
    return;
  }
  
  if (args[0] == 'serve') {
    if (args.length < 2) {
      stderr.writeln('Usage: flux serve <script.flux>');
      exit(1);
    }
    final filePath = args[1];
    await ServeCommand().run(filePath);
    return;
  }

  if (args[0] == 'dev') {
    // Import dev server dynamically to avoid overhead when not used
    final devServerLib = await import('package:flux_cli/src/dev_server.dart');
    final watchDir = args.length > 1 ? args[1] : '.';
    final port = args.length > 2 ? int.tryParse(args[2]) ?? 8765 : 8765;
    await devServerLib.runDevServer([watchDir, port.toString()]);
    return;
  }

  if (args[0] == 'watch') {
    if (args.length < 2) {
      stderr.writeln('Usage: flux watch <script.flux>');
      exit(1);
    }
    final filePath = args[1];
    // Use ServeCommand for watch too, as they are essentially the same (file watcher + server)
    await ServeCommand().run(filePath);
    return;
  }

  final filePath = args[0];
  final file = File(filePath);
  
  if (!file.existsSync()) {
    stderr.writeln('Error: File not found: $filePath');
    exit(1);
  }
  
  try {
    final source = file.readAsStringSync();
    _run(source, filePath);
  } catch (e) {
    stderr.writeln('Error reading file: $e');
    exit(1);
  }
}

void _printHelp() {
  print('''
Flux CLI v$version
Run Flux scripts from the command line.

Usage: flux <script.flux> [options]

Options:
  -h, --help     Show this help message
  -v, --version  Show version number

Examples:
  flux hello.flux
  flux examples/functions.flux
''');
}

void _run(String source, String fileName) {
  try {
    // Tokenize
    final tokens = Lexer(source).tokenize();
    
    // Parse
    final parser = Parser(tokens);
    final unit = parser.parse();
    
    // Compile
    final compiler = Compiler(unit: unit);
    final function = compiler.endCompiler();
    
    // Execute
    final vm = VM();
    vm.onPrint = (msg) => print('[Flux]: $msg');
    
    final result = vm.runChunk(function.chunk);
    
    if (result == InterpretResult.runtimeError) {
      exit(1);
    }
    
  } on ParseError catch (e) {
    stderr.writeln('Parse error in $fileName: ${e.message}');
    exit(1);
  } catch (e) {
    stderr.writeln('Error in $fileName: $e');
    exit(1);
  }
}
