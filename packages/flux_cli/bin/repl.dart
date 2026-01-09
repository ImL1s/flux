#!/usr/bin/env dart

/// Flux REPL - Interactive command line interface
///
/// Usage: dart run flux_cli:repl

import 'dart:io';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

const String version = '2.0.0';
const String prompt = 'flux> ';
const String continuePrompt = '...   ';

void main(List<String> args) {
  final repl = FluxRepl();

  if (args.contains('--help') || args.contains('-h')) {
    _printHelp();
    return;
  }

  if (args.contains('--version') || args.contains('-v')) {
    print('Flux REPL v$version');
    return;
  }

  repl.run();
}

void _printHelp() {
  print('''
Flux REPL v$version
Interactive command line for the Flux language.

Usage: flux_repl [options]

Options:
  -h, --help     Show this help message
  -v, --version  Show version number

Commands (in REPL):
  :help          Show available commands
  :clear         Clear the screen
  :reset         Reset VM state
  :globals       Show global variables
  :exit, :quit   Exit the REPL
''');
}

class FluxRepl {
  late VM _vm;
  final List<String> _history = [];
  bool _multilineMode = false;
  final StringBuffer _buffer = StringBuffer();

  FluxRepl() {
    _resetVm();
  }

  void _resetVm() {
    _vm = VM();
    _vm.onPrint = (msg) => print(msg);
  }

  void run() {
    _printBanner();

    while (true) {
      final line = _readLine();
      if (line == null) {
        print('\nGoodbye!');
        break;
      }

      final trimmed = line.trim();

      // Handle empty input
      if (trimmed.isEmpty) continue;

      // Handle REPL commands
      if (trimmed.startsWith(':')) {
        if (_handleCommand(trimmed)) continue;
        break; // Exit command
      }

      // Handle multi-line input
      if (_multilineMode) {
        _buffer.write('\n');
        _buffer.write(line);
        if (_isComplete(_buffer.toString())) {
          _execute(_buffer.toString());
          _buffer.clear();
          _multilineMode = false;
        }
        continue;
      }

      // Check if input is complete
      if (!_isComplete(trimmed)) {
        _multilineMode = true;
        _buffer.write(trimmed);
        continue;
      }

      // Execute single line
      _execute(trimmed);
      _history.add(trimmed);
    }
  }

  void _printBanner() {
    print('''
╔════════════════════════════════════════╗
║       Flux REPL v$version               ║
║  A scripting language for Flutter      ║
╚════════════════════════════════════════╝

Type ":help" for available commands.
''');
  }

  String? _readLine() {
    stdout.write(_multilineMode ? continuePrompt : prompt);
    return stdin.readLineSync();
  }

  bool _handleCommand(String cmd) {
    switch (cmd.toLowerCase()) {
      case ':help':
        _printCommandHelp();
        return true;
      case ':clear':
        _clearScreen();
        return true;
      case ':reset':
        _resetVm();
        print('VM state reset.');
        return true;
      case ':globals':
        _printGlobals();
        return true;
      case ':history':
        _printHistory();
        return true;
      case ':exit':
      case ':quit':
      case ':q':
        print('Goodbye!');
        return false;
      default:
        print('Unknown command: $cmd. Type :help for available commands.');
        return true;
    }
  }

  void _printCommandHelp() {
    print('''
Available commands:
  :help     - Show this help
  :clear    - Clear the screen
  :reset    - Reset VM state (clear all variables)
  :globals  - Show all global variables
  :history  - Show command history
  :exit     - Exit the REPL (also :quit, :q)
''');
  }

  void _clearScreen() {
    // ANSI escape code to clear screen
    print('\x1B[2J\x1B[0;0H');
    _printBanner();
  }

  void _printGlobals() {
    final globals = _vm.globals;
    if (globals.isEmpty) {
      print('No global variables defined.');
      return;
    }
    print('Global variables:');
    globals.forEach((key, value) {
      // Skip standard library functions
      if (value is NativeFunction) return;
      if (value is ObjClosure) {
        print('  $key = <fn ${value.function.name}>');
      } else {
        print('  $key = $value');
      }
    });
  }

  void _printHistory() {
    if (_history.isEmpty) {
      print('No history.');
      return;
    }
    print('Command history:');
    for (int i = 0; i < _history.length; i++) {
      print('  ${i + 1}: ${_history[i]}');
    }
  }

  bool _isComplete(String source) {
    // Simple heuristic: count braces
    int braces = 0;
    int parens = 0;
    bool inString = false;

    for (int i = 0; i < source.length; i++) {
      final c = source[i];

      // Track strings to avoid counting braces inside them
      if (c == '"' && (i == 0 || source[i - 1] != '\\')) {
        inString = !inString;
        continue;
      }

      if (inString) continue;

      switch (c) {
        case '{':
          braces++;
          break;
        case '}':
          braces--;
          break;
        case '(':
          parens++;
          break;
        case ')':
          parens--;
          break;
      }
    }

    return braces == 0 && parens == 0 && !inString;
  }

  void _execute(String source) {
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
      final result = _vm.runChunk(function.chunk);

      if (result == InterpretResult.runtimeError) {
        // Error already printed by VM
      }
    } on ParseError catch (e) {
      print('Parse error: ${e.message}');
    } catch (e) {
      print('Error: $e');
    }
  }
}
