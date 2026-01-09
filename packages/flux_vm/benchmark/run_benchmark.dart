import 'dart:io';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  final source = File('benchmark/metrics.flux').readAsStringSync();

  // Compile once
  final lexer = Lexer(source);
  final parser = Parser(lexer.tokenize());
  final unit = parser.parse();
  final compiler = Compiler(unit: unit);
  final compiledScript = compiler.endCompiler();

  print('Running benchmark for Fib(20) with heavy method calls...');

  // 1. Run WITHOUT Optimization
  print('\n--- Without Inline Caching ---');
  final durationsNoOpt = <int>[];
  for (int i = 0; i < 5; i++) {
    final vm = VM(enableInlineCaching: false);
    vm.registerScript('benchmark', compiledScript);

    final stopwatch = Stopwatch()..start();
    vm.interpret(
        source); // Note: interpret re-parses, but internal execution uses VM loop
    // Better to use a way to run compiled script directly if possible, or just accept parse overhead as constant
    // VM.interpret parses and runs. To isolate runtime, we'd want to run chunk.
    // But interpret is the standard entry point.
    // Let's assume parse time is constant.
    stopwatch.stop();
    durationsNoOpt.add(stopwatch.elapsedMilliseconds);
    print('Run ${i + 1}: ${stopwatch.elapsedMilliseconds}ms');
  }
  final avgNoOpt =
      durationsNoOpt.reduce((a, b) => a + b) / durationsNoOpt.length;
  print('Average (No Opt): ${avgNoOpt.toStringAsFixed(2)}ms');

  // 2. Run WITH Optimization
  print('\n--- With Inline Caching ---');
  final durationsOpt = <int>[];
  for (int i = 0; i < 5; i++) {
    final vm = VM(enableInlineCaching: true);
    // Reuse same compiled artifact logic if possible, but interpret parses.
    // Optimization is in getting property during execution.

    final stopwatch = Stopwatch()..start();
    vm.interpret(source);
    stopwatch.stop();
    durationsOpt.add(stopwatch.elapsedMilliseconds);
    print('Run ${i + 1}: ${stopwatch.elapsedMilliseconds}ms');

    // Print stats for last run
    if (i == 4) {
      print('Cache Stats: ${vm.cacheStats}');
    }
  }
  final avgOpt = durationsOpt.reduce((a, b) => a + b) / durationsOpt.length;
  print('Average (With Opt): ${avgOpt.toStringAsFixed(2)}ms');

  // 3. Result
  final speedup = ((avgNoOpt - avgOpt) / avgNoOpt) * 100;
  print('\n----------------------------------------');
  print('Performance Improvement: ${speedup.toStringAsFixed(2)}%');
  print('----------------------------------------');
}
