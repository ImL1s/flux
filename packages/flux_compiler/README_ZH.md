# Flux 編譯器 (Flux Compiler)

[English Documentation](README.md)

[![pub package](https://img.shields.io/pub/v/flux_compiler.svg)](https://pub.dev/packages/flux_compiler)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Flux 程式語言的官方編譯器。

將 Flux 源程式碼轉換為可由 Flux 虛擬機 (VM) 執行的字節碼塊 (Bytecode chunks)。

## 特性

- **單次掃描編譯 (Single-Pass Compilation)**：高效的編譯管道。
- **優化**：針對大小和速度進行基礎的窺孔優化 (Peephole optimizations)。
- **源碼映射 (Source Maps)**：生成偵錯資訊。
- **錯誤回報**：詳細的編譯時錯誤訊息。

## 用法

```dart
import 'package:flux_compiler/flux_compiler.dart';

void main() {
  String source = 'print("Hello Flux");';
  
  // 詞法分析 (Lexing)
  final lexer = Lexer(source);
  final tokens = lexer.tokenize();
  
  // 語法分析 (Parsing)
  final parser = Parser(tokens);
  final ast = parser.parse();
  
  // 編譯 (Compiling)
  final compiler = Compiler(unit: ast);
  final function = compiler.endCompiler();
  
  // function.chunk 包含編譯後的字節碼
}
```

## 貢獻

請參閱 [Flux 程式庫 (Repository)](https://github.com/ImL1s/flux)。
