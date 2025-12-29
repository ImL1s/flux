import 'dart:io';
import '../packages/flux_vm/lib/flux_vm.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run_flux.dart <file>');
    return;
  }

  final file = File(args[0]);
  if (!file.existsSync()) {
    print('Error: File not found.');
    return;
  }

  final source = file.readAsStringSync();
  
  final vm = VM();
  // Simple print override to prefix output
  vm.onPrint = (msg) => print('[Flux]: $msg');
  
  print('Running ${file.path}...\n');
  final result = vm.interpret(source);
  
  if (result == InterpretResult.ok) {
    print('\nExecution finished successfully.');
  } else {
    exitCode = 1;
  }
}
