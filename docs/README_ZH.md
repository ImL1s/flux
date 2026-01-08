# Flux 腳本語言

[English Documentation](README.md)

一個輕量級、可嵌入的 Flutter 腳本語言。

## 這是什麼？

Flux 讓您可以在 Flutter 應用中運行動態腳本，實現：
- 🔄 **熱更新** - 不重新發布 App Store 就能更新 UI 和邏輯
- 🎮 **遊戲邏輯** - 動態載入關卡配置
- 📝 **用戶自定義** - 讓用戶編寫自己的規則

> **🔥 想快速體驗熱更新？** 查看 **[完整示範項目](../examples/hot_update_demo/README.md)**，包含可運行的 Flutter App 和說明。

## 30 秒快速入門

### 第 1 步：創建測試項目

```bash
# 創建新的 Dart 項目
dart create flux_demo
cd flux_demo
```

### 第 2 步：添加依賴

編輯 `pubspec.yaml`：

```yaml
dependencies:
  flux_vm:
    path: ../flux/packages/flux_vm
  flux_compiler:
    path: ../flux/packages/flux_compiler
```

### 第 3 步：編寫代碼

編輯 `bin/flux_demo.dart`：

```dart
import 'package:flux_vm/flux_vm.dart';

void main() {
  // 創建虛擬機
  final vm = VM();
  
  // 設置 print 輸出處理
  vm.onPrint = (message) => print('>>> $message');
  
  // 運行 Flux 腳本
  vm.interpret('''
    // 這是 Flux 腳本！
    var name = "小明";
    var age = 25;
    
    print("你好，" + name + "！");
    print("你今年 " + age + " 歲");
    
    // 簡單計算
    var result = (10 + 5) * 2;
    print("計算結果: " + result);
  ''');
}
```

### 第 4 步：運行

```bash
dart run
```

輸出：
```
>>> 你好，小明！
>>> 你今年 25 歲
>>> 計算結果: 30
```

---

## Flux 語法速查

```
// 變量
var x = 10;
var message = "Hello";

// 函數
fn add(a, b) {
  return a + b;
}
var result = add(3, 4);  // 7

// 條件
if (x > 5) {
  print("大於 5");
} else {
  print("小於等於 5");
}

// 迴圈
for (var i = 0; i < 5; i = i + 1) {
  print(i);
}

// 類別
class Person {
  field name = "";
  fn greet() {
    print("我是 " + this.name);
  }
}
var p = Person();
p.name = "小華";
p.greet();
```

---

## 常用標準庫函數

| 函數 | 說明 | 例子 |
|------|------|------|
| `print(x)` | 輸出 | `print("Hello")` |
| `len(x)` | 長度 | `len([1,2,3])` → 3 |
| `push(list, item)` | 添加元素 | `push(arr, 5)` |
| `pop(list)` | 移除最後元素 | `pop(arr)` |
| `upper(str)` | 轉大寫 | `upper("hi")` → "HI" |
| `Math.sqrt(x)` | 平方根 | `Math.sqrt(16)` → 4 |

---

## Flutter 整合示例

在 Flutter 中使用 `FluxWidget` 嵌入腳本：

```dart
// 在 build 方法中
FluxWidget(
  widgetName: 'Counter', // 對應 Flux 中的 widget 名稱
  source: '''
    widget Counter {
      state count = 0;
      
      build {
        Column(
          children: [
            Text(text: "點擊次數: " + count),
            Button(
              text: "加一",
              onPressed: fn() { count = count + 1; }
            )
          ]
        )
      }
    }
  ''',
)
```

---

## 更多文檔

- [語言完整參考](language_reference.md)
- [標準庫參考](stdlib_reference.md)
- [Flutter 整合](flutter_integration.md)
