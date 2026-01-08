# Flux VM

[English Documentation](README.md)

[![pub package](https://img.shields.io/pub/v/flux_vm.svg)](https://pub.dev/packages/flux_vm)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

一個由 Dart 編寫的高性能 Flux 程式語言虛擬機。

Flux 是一種專為 UI 開發設計的現代感響應式指令碼語言。此套件 `flux_vm` 作為核心執行引擎，負責執行 Flux 字節碼塊 (Bytecode chunks)。

## 特性

- **基於棧的架構 (Stack-based Architecture)**：高效的執行模型。
- **原生互操作 (Native Interop)**：靈活的 Dart 函式和物件綁定系統。
- **作用域管理**：強大的詞法作用域和變數解析。
- **非同步支援**：內置對非同步操作的支援。

## 用法

```dart
import 'package:flux_vm/flux_vm.dart';

void main() {
  final vm = VM();
  
  // 註冊原生模組
  // vm.registerModule(MyModule());
  
  // 執行字節碼塊
  // vm.run(chunk);
}
```

## 貢獻

歡迎貢獻！請參閱主 [Flux 程式庫](https://github.com/ImL1s/flux) 了解詳情。
