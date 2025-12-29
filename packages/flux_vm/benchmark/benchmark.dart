#!/usr/bin/env dart
/// Flux Language Performance Benchmarks
/// 
/// Industry-standard benchmarks for bytecode interpreter performance:
/// 1. Fibonacci (recursive) - tests function call overhead
/// 2. Ackermann function - tests deep recursion
/// 
/// Reference: https://github.com/drujensen/fib

import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

class FluxCompiler {
  static CompiledFunction compile(String source) {
    final tokens = Lexer(source).tokenize();
    final parser = Parser(tokens);
    final unit = parser.parse();
    final compiler = Compiler(unit: unit);
    return compiler.endCompiler();
  }
}

void main(List<String> args) {
  print('╔════════════════════════════════════════╗');
  print('║     Flux Performance Benchmarks        ║');
  print('╚════════════════════════════════════════╝');
  print('');
  
  // Parse args
  int fibN = 30;
  int ackM = 3;
  int ackN = 8;
  
  if (args.isNotEmpty) {
    fibN = int.tryParse(args[0]) ?? fibN;
  }
  
  runFibonacciBenchmark(fibN);
  print('');
  runAckermannBenchmark(ackM, ackN);
  print('');
  runLoopBenchmark(1000000);
}

void runFibonacciBenchmark(int n) {
  print('Benchmark: Fibonacci($n)');
  print('─' * 40);
  
  final source = '''
    fn fib(n) {
      if (n <= 1) return n;
      return fib(n - 1) + fib(n - 2);
    }
    
    var result = fib($n);
    print(result);
  ''';
  
  // Compilation time
  final compileStart = DateTime.now();
  final unit = FluxCompiler.compile(source);
  final compileTime = DateTime.now().difference(compileStart);
  print('  Compile time: ${compileTime.inMilliseconds}ms');
  
  // Execution time
  final vm = VM();
  var resultValue = 0;
  vm.onPrint = (msg) {
    resultValue = int.tryParse(msg) ?? 0;
  };
  
  final execStart = DateTime.now();
  final result = vm.runChunk(unit.chunk);
  final execTime = DateTime.now().difference(execStart);
  
  if (result == InterpretResult.ok) {
    print('  Execute time: ${execTime.inMilliseconds}ms');
    print('  Result: fib($n) = $resultValue');
  } else {
    print('  Error during execution');
  }
}

void runAckermannBenchmark(int m, int n) {
  print('Benchmark: Ackermann($m, $n)');
  print('─' * 40);
  
  final source = '''
    fn ack(m, n) {
      if (m == 0) return n + 1;
      if (n == 0) return ack(m - 1, 1);
      return ack(m - 1, ack(m, n - 1));
    }
    
    var result = ack($m, $n);
    print(result);
  ''';
  
  // Compilation time
  final compileStart = DateTime.now();
  final unit = FluxCompiler.compile(source);
  final compileTime = DateTime.now().difference(compileStart);
  print('  Compile time: ${compileTime.inMilliseconds}ms');
  
  // Execution time
  final vm = VM();
  var resultValue = 0;
  vm.onPrint = (msg) {
    resultValue = int.tryParse(msg) ?? 0;
  };
  
  final execStart = DateTime.now();
  final result = vm.runChunk(unit.chunk);
  final execTime = DateTime.now().difference(execStart);
  
  if (result == InterpretResult.ok) {
    print('  Execute time: ${execTime.inMilliseconds}ms');
    print('  Result: ack($m, $n) = $resultValue');
  } else {
    print('  Error during execution');
  }
}

void runLoopBenchmark(int iterations) {
  print('Benchmark: Loop ($iterations iterations)');
  print('─' * 40);
  
  final source = '''
    var sum = 0;
    for (var i = 0; i < $iterations; i = i + 1) {
      sum = sum + 1;
    }
    print(sum);
  ''';
  
  // Compilation
  final compileStart = DateTime.now();
  final unit = FluxCompiler.compile(source);
  final compileTime = DateTime.now().difference(compileStart);
  print('  Compile time: ${compileTime.inMilliseconds}ms');
  
  // Execution
  final vm = VM();
  var resultValue = 0;
  vm.onPrint = (msg) => resultValue = int.tryParse(msg) ?? 0;
  
  final execStart = DateTime.now();
  final result = vm.runChunk(unit.chunk);
  final execTime = DateTime.now().difference(execStart);
  
  if (result == InterpretResult.ok) {
    print('  Execute time: ${execTime.inMilliseconds}ms');
    print('  Result: sum = $resultValue');
    print('  Rate: ${(iterations / (execTime.inMicroseconds / 1000000)).round()} iterations/sec');
  } else {
    print('  Error during execution');
  }
}
