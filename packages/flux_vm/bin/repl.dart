#!/usr/bin/env dart
/// Flux REPL - Interactive Command Line Interface

import 'dart:io';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

void main(List<String> args) {
  final vm = VM();
  
  print('');
  print('╔═══════════════════════════════════════╗');
  print('║       Flux REPL v2.0                  ║');
  print('║  Type "exit" or Ctrl+C to quit        ║');
  print('║  Type "help" for commands             ║');
  print('╚═══════════════════════════════════════╝');
  print('');
  
  final buffer = StringBuffer();
  bool multiLine = false;
  
  while (true) {
    stdout.write(multiLine ? '... ' : 'flux> ');
    final line = stdin.readLineSync();
    
    if (line == null) break;
    
    final trimmed = line.trim();
    
    // Commands
    if (!multiLine) {
      if (trimmed == 'exit' || trimmed == 'quit') {
        print('Goodbye!');
        break;
      }
      
      if (trimmed == 'help') {
        _printHelp();
        continue;
      }
      
      if (trimmed == 'clear') {
        // Clear screen
        print('\x1B[2J\x1B[0;0H');
        continue;
      }
      
      if (trimmed == 'globals') {
        print('Global variables:');
        for (final entry in vm.globals.entries) {
          if (entry.value is! NativeFunction) {
            print('  ${entry.key} = ${entry.value}');
          }
        }
        continue;
      }
      
      if (trimmed == 'stdlib') {
        print('Standard library functions:');
        final funcs = StdLib.functions.keys.toList()..sort();
        for (int i = 0; i < funcs.length; i += 5) {
          final row = funcs.skip(i).take(5).join(', ');
          print('  $row');
        }
        continue;
      }
    }
    
    // Multi-line detection
    if (trimmed.endsWith('{') || trimmed.endsWith('\\')) {
      buffer.writeln(line.replaceAll('\\', ''));
      multiLine = true;
      continue;
    }
    
    if (multiLine) {
      if (trimmed == '}' || trimmed.isEmpty) {
        buffer.writeln(line);
        if (trimmed == '}') {
          multiLine = false;
        } else {
          continue;
        }
      } else {
        buffer.writeln(line);
        continue;
      }
    } else {
      buffer.writeln(line);
    }
    
    // Execute
    final source = buffer.toString().trim();
    buffer.clear();
    
    if (source.isEmpty) continue;
    
    try {
      // Tokenize
      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      
      if (lexer.errors.isNotEmpty) {
        for (final error in lexer.errors) {
          print('Lexer Error: $error');
        }
        continue;
      }
      
      // Parse
      final parser = Parser(tokens);
      final ast = parser.parse();
      
      if (parser.errors.isNotEmpty) {
        for (final error in parser.errors) {
          print('Parse Error: $error');
        }
        continue;
      }
      
      // Compile
      final compiler = Compiler();
      compiler.compile(ast);
      final function = compiler.endCompiler();
      
      // Execute
      final result = vm.runChunk(function.chunk);
      
      if (result == InterpretResult.runtimeError) {
        print('Runtime Error');
      }
      
    } catch (e, stack) {
      print('Error: $e');
      if (args.contains('--debug')) {
        print(stack);
      }
    }
  }
}

void _printHelp() {
  print('''
Commands:
  help     - Show this help message
  exit     - Exit the REPL
  clear    - Clear the screen
  globals  - Show all global variables
  stdlib   - List standard library functions
  
Examples:
  let x = 42
  print(x + 8)
  print(sqrt(16))
  let list = [1, 2, 3]
  print(len(list))
''');
}
