# Flux Flutter

[English Documentation](README.md)

[![pub package](https://img.shields.io/pub/v/flux_flutter.svg)](https://pub.dev/packages/flux_flutter)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Flux 指令碼語言的 Flutter 綁定，支援服務端驅動 UI (Server-driven UI) 和熱重載功能。

## 特性

- **FluxUI 組件庫**：全套 UI 組件（Button, Card, Input, Badge, Row, Column, Grid, Stack）
- **BLE 整合**：透過 `flutter_blue_plus` 提供藍牙低功耗支援
- **相機整合**：透過 `camera` 套件實現真實相機功能
- **熱重載 (Hot Reload)**：無需重啟應用即可即時更新指令碼
- **Riverpod 整合**：與 Riverpod 3.x 無縫銜接的狀態管理
- **狀態持久化**：安全存儲、Hive 整合以及版本化狀態遷移 (v3.0)

## 入門指南

在您的 `pubspec.yaml` 中添加以下內容：

```yaml
dependencies:
  flux_flutter: ^2.0.1
  flutter_riverpod: ^3.0.0
```

## 用法

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
                  Button(text: "增加", onPressed: fn() { count = count + 1; })
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

## 更多資訊

- [GitHub 程式庫](https://github.com/ImL1s/flux)
- [文檔指南](https://github.com/ImL1s/flux/tree/main/docs)
