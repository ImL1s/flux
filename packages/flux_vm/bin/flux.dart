import 'dart:io';
import 'package:flux_vm/flux_vm.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: flux <file>');
    return;
  }

  // Adjust path handling if running from package root vs bin
  final path = args[0];
  final file = File(path);
  
  if (!file.existsSync()) {
    print('Error: File not found at $path');
    print('Current CWD: ${Directory.current.path}');
    return;
  }

  final source = file.readAsStringSync();
  
  final vm = VM();
  vm.onPrint = (msg) => print('[Flux]: $msg');
  
  print('Running ${file.path}...\n');
  final result = vm.interpret(source);
  
  if (result == InterpretResult.ok) {
    print('\nExecution finished successfully.');
  } else {
    exitCode = 1;
  }
}
