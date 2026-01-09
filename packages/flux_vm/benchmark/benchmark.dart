/// Flux VM Performance Benchmarks
///
/// Run with: dart run benchmark/benchmark.dart

import 'dart:io';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  print('=' * 60);
  print('Flux VM Performance Benchmarks');
  print('=' * 60);
  print('');

  final results = <String, Duration>{};

  // Fibonacci benchmark (recursive calls)
  results['Fibonacci(25)'] = benchmark(
      'Fibonacci(25)',
      '''
    fn fib(n) {
      if (n <= 1) { return n; }
      return fib(n - 1) + fib(n - 2);
    }
    var result = fib(25);
  ''',
      1);

  // Loop benchmark
  results['Loop 100K'] = benchmark(
      'Loop 100K iterations',
      '''
    var sum = 0;
    for (var i = 0; i < 100000; i = i + 1) {
      sum = sum + i;
    }
  ''',
      3);

  // Closure benchmark
  results['Closures'] = benchmark(
      'Closure creation and calls',
      '''
    fn makeCounter() {
      var count = 0;
      return fn() {
        count = count + 1;
        return count;
      };
    }
    
    var counter = makeCounter();
    for (var i = 0; i < 10000; i = i + 1) {
      counter();
    }
  ''',
      3);

  // Class instantiation benchmark
  results['Classes'] = benchmark(
      'Class instantiation and methods',
      '''
    class Point {
      field x = 0;
      field y = 0;
      
      init(px, py) {
        this.x = px;
        this.y = py;
      }
      
      add(other) {
        return Point(this.x + other.x, this.y + other.y);
      }
    }
    
    var p = Point(0, 0);
    for (var i = 0; i < 5000; i = i + 1) {
      p = Point(i, i);
    }
  ''',
      3);

  // List operations benchmark
  results['List Ops'] = benchmark(
      'List push/pop operations',
      '''
    var list = [];
    for (var i = 0; i < 10000; i = i + 1) {
      push(list, i);
    }
    for (var i = 0; i < 10000; i = i + 1) {
      pop(list);
    }
  ''',
      3);

  // String operations benchmark
  results['String Ops'] = benchmark(
      'String operations',
      '''
    var s = "";
    for (var i = 0; i < 1000; i = i + 1) {
      s = s + "a";
    }
    var u = upper(s);
    var parts = split(s, "a");
  ''',
      3);

  // Print summary
  print('');
  print('=' * 60);
  print('Summary');
  print('=' * 60);
  print('');
  print('| Benchmark | Time (avg) |');
  print('|-----------|------------|');
  for (final entry in results.entries) {
    final ms = entry.value.inMicroseconds / 1000.0;
    print(
        '| ${entry.key.padRight(20)} | ${ms.toStringAsFixed(2).padLeft(8)} ms |');
  }
  print('');

  // Save results to JSON
  final json = results.map((k, v) => MapEntry(k, v.inMicroseconds));
  final file = File('benchmark/results.json');
  file.writeAsStringSync('${json.toString()}\n');
  print('Results saved to benchmark/results.json');
}

Duration benchmark(String name, String source, int runs) {
  print('Running: $name');

  // Compile once
  final tokens = Lexer(source).tokenize();
  final ast = Parser(tokens).parse();
  final compiler = Compiler(unit: ast);
  final function = compiler.endCompiler();

  // Warmup
  for (var i = 0; i < 2; i++) {
    final vm = VM();
    vm.runChunk(function.chunk);
  }

  // Benchmark runs
  final times = <Duration>[];
  for (var i = 0; i < runs; i++) {
    final vm = VM();
    final sw = Stopwatch()..start();
    vm.runChunk(function.chunk);
    sw.stop();
    times.add(sw.elapsed);
  }

  // Calculate average
  final totalMicros = times.fold<int>(0, (sum, d) => sum + d.inMicroseconds);
  final avgMicros = totalMicros ~/ runs;
  final avgDuration = Duration(microseconds: avgMicros);

  print('  -> ${avgDuration.inMicroseconds / 1000.0} ms (avg of $runs runs)');
  return avgDuration;
}
