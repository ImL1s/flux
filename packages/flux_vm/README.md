# Flux VM

[漢文文檔](README_ZH.md)

[![pub package](https://img.shields.io/pub/v/flux_vm.svg)](https://pub.dev/packages/flux_vm)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A high-performance virtual machine for the Flux programming language, written in Dart.

Flux is a modern, reactive scripting language designed for UI development. This package `flux_vm` serves as the runtime engine that executes Flux bytecode chunks.

## Features

- **Stack-based Architecture**: Efficient execution model.
- **Native Interop**: Flexible binding system for Dart functions and objects.
- **Scope Management**: Robust lexical scoping and variable resolution.
- **Async Support**: Built-in support for asynchronous operations.

## Usage

```dart
import 'package:flux_vm/flux_vm.dart';

void main() {
  final vm = VM();
  
  // Register native modules
  // vm.registerModule(MyModule());
  
  // Run bytecode chunk
  // vm.run(chunk);
}
```

## Contributing

Contributions are welcome! Please see the main [Flux repository](https://github.com/ImL1s/flux) for details.
