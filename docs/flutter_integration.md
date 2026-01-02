# Flutter Integration Guide

## Setup

Add dependencies to `pubspec.yaml`:

```yaml
dependencies:
  flux_vm: ^1.0.0
  flux_flutter: ^1.0.0
```

## FluxWidget

The primary way to embed Flux in Flutter:

```dart
import 'package:flux_flutter/flux_flutter.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FluxWidget(
      source: '''
        widget Greeting {
          state name = "World";
          
          build {
            return Text(text: "Hello, " + name + "!");
          }
        }
      ''',
    );
  }
}
```

## Widget State

State variables automatically trigger rebuilds:

```flux
widget Counter {
  state count = 0;
  
  build {
    return Column(
      children: [
        Text(text: "Count: " + count),
        Button(
          text: "+",
          onTap: fn() { count = count + 1; }
        ),
        Button(
          text: "-", 
          onTap: fn() { count = count - 1; }
        )
      ]
    );
  }
}
```

## Supported Widgets

| Widget | Properties |
|--------|------------|
| `Text` | `text`, `style` |
| `Button` | `text`, `onTap` |
| `Column` | `children` |
| `Row` | `children` |
| `Container` | `child`, `padding`, `color` |
| `Image` | `src` |
| `TextField` | `value`, `onChanged` |

## Hot Reload

### Development Server

Start the dev server:

```bash
flux dev --watch ./scripts
```

### Flutter App Connection

```dart
import 'package:flux_flutter/flux_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Connect to dev server
  final hotReload = await HotReloadService.connect('ws://localhost:8080');
  
  runApp(MyApp(hotReloadService: hotReload));
}
```

### Widget with Hot Reload

```dart
class MyApp extends StatelessWidget {
  final HotReloadService hotReloadService;
  
  MyApp({required this.hotReloadService});
  
  @override
  Widget build(BuildContext context) {
    return FluxWidget(
      source: myScript,
      hotReloadService: hotReloadService,
    );
  }
}
```

## DevTools Integration

Flux integrates with Flutter DevTools for debugging:

1. Run your app in debug mode
2. Open DevTools
3. Navigate to "Flux" tab
4. Set breakpoints, inspect variables, evaluate expressions

### Service Extensions

| Extension | Description |
|-----------|-------------|
| `ext.flux.getStack` | Get call stack |
| `ext.flux.getLocals` | Get local variables |
| `ext.flux.evaluate` | Evaluate expression |
| `ext.flux.getObject` | Inspect object |

## Script Signing (Production)

### Generate Keys

```bash
flux keygen --output keys/
```

### Sign Script

```bash
flux sign script.flux --key keys/private.pem --output script.flux.signed
```

### Verify in App

```dart
final verifier = FluxScriptVerifier(publicKey: myPublicKey);

if (verifier.verify(signedScript)) {
  vm.interpret(signedScript.content);
} else {
  throw SecurityException('Invalid signature');
}
```

## Best Practices

1. **Pre-compile scripts** for production to avoid parsing overhead
2. **Use .flx format** for distribution (smaller, faster to load)
3. **Sign scripts** for production to prevent tampering
4. **Limit VM capabilities** by not registering sensitive modules
5. **Validate all inputs** from Flux scripts before use in Dart
