#!/usr/bin/env dart
/// Flux CLI - Run Flux scripts from command line
/// 
/// Usage: dart run flux_cli:flux <script.flux>

import 'dart:io';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_cli/src/commands/serve_command.dart';
import 'package:flux_cli/src/commands/key_command.dart';
import 'package:flux_cli/src/commands/sign_command.dart';
import 'package:flux_cli/src/commands/verify_command.dart';
import 'package:args/command_runner.dart';
import 'package:flux_cli/src/dev_server.dart' as dev_server;

const String version = '2.0.0';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _printHelp();
    return;
  }
  
  if (args.contains('--version') || args.contains('-v')) {
    print('Flux CLI v$version');
    return;
  }
  
  // Create command runner
  final runner = CommandRunner('flux', 'Flux CLI Tool')
    ..addCommand(ServeCommand())
    ..addCommand(KeyCommand())
    ..addCommand(SignCommand())
    ..addCommand(VerifyCommand());
    
  // Handle built-in dev commands manually for now or migrate them to proper Commands
  if (['serve', 'watch', 'keygen', 'sign', 'verify'].contains(args[0])) {
    try {
      await runner.run(args);
    } catch (e) {
      if (e is UsageException) {
        stderr.writeln(e);
        exit(64);
      }
      rethrow;
    }
    return;
  }

  // --- Original logic for 'dev' and running scripts directly ---

  if (args[0] == 'dev') {
    final watchDir = args.length > 1 ? args[1] : '.';
    final port = args.length > 2 ? int.tryParse(args[2]) ?? 8765 : 8765;
    await dev_server.runDevServer([watchDir, port.toString()]);
    return;
  }

  // Default: Run script
  final filePath = args[0];
  final file = File(filePath);
  
  if (!file.existsSync()) {
    // If it looks like a flag, print help
    if (filePath.startsWith('-')) {
       _printHelp();
       return;
    }
    
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

Usage: flux <command> [arguments]

Commands:
  serve <file>    Serve a Flux script for Flutter client
  watch <file>    Watch and serve a Flux script
  keygen          Generate a new Ed25519 key pair
  sign <file>     Sign a script with a private key
  verify <file>   Verify a signed script

Options:
  -h, --help     Show this help message
  -v, --version  Show version number

Examples:
  flux hello.flux
  flux sign script.flux
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
