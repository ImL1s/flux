# Flux Language

A lightweight, embeddable scripting language for Flutter applications.

## Features

- **Stack-based VM** - Efficient bytecode execution
- **Flutter Integration** - Hot-reload, widget state management
- **Full Debugger** - Breakpoints, stepping, expression evaluation
- **Security** - Ed25519 script signing
- **Developer Tools** - LSP, DevTools integration, Source Maps

## Quick Start

```dart
import 'package:flux_vm/flux_vm.dart';

final vm = VM();
vm.interpret('''
  var greeting = "Hello, Flux!";
  print(greeting);
''');
```

## Documentation

- [Getting Started](getting_started.md)
- [Language Reference](language_reference.md)
- [Standard Library](stdlib_reference.md)
- [Flutter Integration](flutter_integration.md)
- [Security Guide](security.md)

## Packages

| Package | Description |
|---------|-------------|
| `flux_compiler` | Lexer, Parser, Compiler |
| `flux_vm` | Virtual Machine, Debugger, StdLib |
| `flux_flutter` | Flutter bindings, Hot-reload |
| `flux_cli` | Command-line tools |
| `flux_vscode` | VSCode extension |

## License

MIT License
