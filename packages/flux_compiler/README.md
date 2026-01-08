# Flux Compiler

[漢文文檔](README_ZH.md)

[![pub package](https://img.shields.io/pub/v/flux_compiler.svg)](https://pub.dev/packages/flux_compiler)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

The official compiler for the Flux programming language.

Converts Flux source code into bytecode chunks that can be executed by the Flux VM.

## Features

- **Single-Pass Compilation**: Efficient compilation pipeline.
- **Optimization**: Basic peephole optimizations for size and speed.
- **Source Maps**: Generates debugging information.
- **Error Reporting**: Detailed compile-time error messages.

## Usage

```dart
import 'package:flux_compiler/flux_compiler.dart';

void main() {
  String source = 'print("Hello Flux");';
  
  // Lexing
  final lexer = Lexer(source);
  final tokens = lexer.tokenize();
  
  // Parsing
  final parser = Parser(tokens);
  final ast = parser.parse();
  
  // Compiling
  final compiler = Compiler(unit: ast);
  final function = compiler.endCompiler();
  
  // function.chunk contains the bytecode
}
```

## Contributing

See [Flux Repository](https://github.com/ImL1s/flux).
