# Getting Started with Flux

[漢文文檔](getting_started_ZH.md)

Flux is a dynamic scripting language specifically designed for **Flutter Server-Driven UI**. It allows you to update UI layouts and business logic on the fly without republishing your app to stores.

## Prerequisites

- **Flutter SDK**: 3.x or higher
- **Dart SDK**: 3.x or higher
- **FVM** (Recommended): For managing Flutter versions.

## 1. Installation

Add Flux to your `pubspec.yaml`:

```yaml
dependencies:
  flux_flutter: ^2.0.0
```

## 2. Your First Flux Script

Create a file named `hello.flux`:

```javascript
widget HelloWorld {
  state name = "Developer";
  
  build {
    Column(
      children: [
        Text(text: "Hello, " + name + "!"),
        TextField(
          hint: "Enter your name",
          onChanged: fn(val) {
            name = val;
          }
        )
      ]
    )
  }
}
```

## 3. Running in Flutter

```dart
import 'package:flutter/material.dart';
import 'package:flux_flutter/flux_flutter.dart';

void main() => runApp(MaterialApp(home: FluxDemo()));

class FluxDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FluxWidget(
        source: fluxSourceCode, // Load your .flux file here
        widgetName: 'HelloWorld',
      ),
    );
  }
}
```

## 4. Key Features

- **Reactive State**: Use the `state` keyword for automatic UI updates.
- **Async Support**: Use `async`/`await` for network and storage operations.
- **Riverpod Core**: Deep integration with Riverpod for global state management.
- **Lightweight**: Optimized bytecode VM for mobile performance.

## Next Steps

- Explore the [Language Guide](./LANGUAGE_GUIDE.md).
- Check the [Widget Catalog](./WIDGET_CATALOG.md).
- Learn about [Architecture](./ARCHITECTURE.md).
