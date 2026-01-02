# Getting Started with Flux

## Installation

Add Flux to your `pubspec.yaml`:

```yaml
dependencies:
  flux_vm: ^1.0.0
  flux_flutter: ^1.0.0  # For Flutter apps
```

## Basic Usage

### Running a Script

```dart
import 'package:flux_vm/flux_vm.dart';

void main() {
  final vm = VM();
  
  vm.onPrint = (message) => print('Flux: $message');
  
  final result = vm.interpret('''
    var name = "World";
    print("Hello, " + name + "!");
  ''');
  
  if (result == InterpretResult.ok) {
    print('Script executed successfully');
  }
}
```

### Pre-compiling Scripts

```dart
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

// Compile once
final tokens = Lexer(source).tokenize();
final ast = Parser(tokens).parse();
final compiler = Compiler(unit: ast);
final function = compiler.endCompiler();

// Run many times
final vm = VM();
vm.runChunk(function.chunk);
```

## Flutter Integration

```dart
import 'package:flux_flutter/flux_flutter.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FluxWidget(
      source: '''
        widget Counter {
          state count = 0;
          
          build {
            return Button(
              text: "Count: " + count,
              onTap: fn() { count = count + 1; }
            );
          }
        }
      ''',
    );
  }
}
```

## Hot Reload

Enable hot-reload during development:

```dart
HotReloadService.connect('ws://localhost:8080')
  .then((service) {
    service.onReload = (script) => print('Reloaded: $script');
  });
```

## Next Steps

- [Language Reference](language_reference.md) - Learn the syntax
- [Standard Library](stdlib_reference.md) - Available functions
- [Debugging](security.md) - Debug your scripts
