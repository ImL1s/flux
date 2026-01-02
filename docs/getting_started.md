# Flux 快速入門

## 前置條件
- 已安裝 Dart SDK 3.0+
- 已克隆 Flux 項目

---

## 方法一：在現有項目中使用

### 1. 添加本地依賴

在你的 `pubspec.yaml` 中：

```yaml
dependencies:
  flux_vm:
    path: /path/to/flux/packages/flux_vm
  flux_compiler:
    path: /path/to/flux/packages/flux_compiler
```

### 2. 獲取依賴

```bash
dart pub get
```

### 3. 最簡代碼

```dart
import 'package:flux_vm/flux_vm.dart';

void main() {
  final vm = VM();
  vm.onPrint = print;  // 將 print 輸出到控制台
  
  vm.interpret('print("Hello from Flux!");');
}
```

---

## 方法二：運行完整示例

### 1. 進入 VM 測試目錄

```bash
cd flux/packages/flux_vm
```

### 2. 運行集成測試

```bash
dart test test/integration_test.dart
```

### 3. 運行性能基準

```bash
dart run benchmark/benchmark.dart
```

---

## 核心 API

### VM 類

```dart
final vm = VM();

// 設置輸出回調
vm.onPrint = (String message) {
  print('Script output: $message');
};

// 運行腳本字串
InterpretResult result = vm.interpret('''
  var x = 10;
  print(x * 2);
''');

// 檢查結果
if (result == InterpretResult.ok) {
  print('成功');
} else if (result == InterpretResult.compileError) {
  print('編譯錯誤');
} else {
  print('運行時錯誤');
}
```

### 預編譯（提高性能）

```dart
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

// 編譯一次
String source = '''
  fn fibonacci(n) {
    if (n <= 1) { return n; }
    return fibonacci(n-1) + fibonacci(n-2);
  }
  print(fibonacci(20));
''';

final tokens = Lexer(source).tokenize();
final ast = Parser(tokens).parse();
final compiler = Compiler(unit: ast);
final compiled = compiler.endCompiler();

// 可以多次運行編譯後的代碼
final vm = VM();
vm.onPrint = print;
vm.runChunk(compiled.chunk);  // 更快！
```

---

## 常見問題

### Q: 如何傳入外部變量？

```dart
// 設置全局變量
vm.defineGlobal('myVar', 42);
vm.defineGlobal('myList', [1, 2, 3]);

vm.interpret('''
  print(myVar);  // 42
''');
```

### Q: 如何獲取腳本返回值？

```dart
// 目前需從全局變量讀取
vm.interpret('''
  var result = 10 + 20;
''');
var value = vm.getGlobal('result');  // 30
```

### Q: 發生錯誤怎麼辦？

```dart
vm.onError = (String error) {
  print('腳本錯誤: $error');
};
```

---

## 下一步

- [語言參考](language_reference.md) - 完整語法
- [標準庫](stdlib_reference.md) - 可用函數
- [Flutter 整合](flutter_integration.md) - 在 Flutter 中使用
