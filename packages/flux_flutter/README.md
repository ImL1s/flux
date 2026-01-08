# Flux Flutter

[漢文文檔](README_ZH.md)

[![pub package](https://img.shields.io/pub/v/flux_flutter.svg)](https://pub.dev/packages/flux_flutter)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Flutter bindings for the Flux scripting language, enabling server-driven UI and hot-reload capabilities.

## Features

- **FluxUI Component Library**: Complete set of UI components (Button, Card, Input, Badge, Row, Column, Grid, Stack)
- **BLE Integration**: Bluetooth Low Energy support via `flutter_blue_plus`
- **Camera Integration**: Real camera functionality via `camera` package
- **Hot Reload**: Live update scripts without app restart
- **Riverpod Integration**: Seamless state management with Riverpod 3.x
- **State Persistence**: Secure storage, Hive integration, and versioned state migration (v3.0)

## Getting Started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flux_flutter: ^2.0.1
  flutter_riverpod: ^3.0.0
```

## Usage

```dart
import 'package:flux_flutter/flux_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        home: FluxWidget(
          source: '''
            widget Counter {
              state count = 0;
              build {
                Column(children: [
                  Text(count),
                  Button(text: "Increment", onPressed: fn() { count = count + 1; })
                ])
              }
            }
          ''',
          widgetName: 'Counter',
        ),
      ),
    );
  }
}
```

## Additional Information

- [GitHub Repository](https://github.com/ImL1s/flux)
- [Documentation](https://github.com/ImL1s/flux/tree/main/docs)
