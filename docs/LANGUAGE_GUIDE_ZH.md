# Flux 語言指南

[English Documentation](LANGUAGE_GUIDE.md)

Flux 是一種專為 Flutter 服務端驅動 UI (Server-Driven UI) 設計的動態指令碼語言。它將類 Dart 語法與類似 React 或 Flutter 的響應式執行模型相結合。

## 基礎語法

### 變數 (Variables)

```dart
var x = 10;
var name = "Flux";
var isReady = true;
```

### 控制流 (Control Flow)

```dart
if (x > 5) {
  print("大於 (Greater)");
} else {
  print("小於 (Smaller)");
}

while (x > 0) {
  x = x - 1;
}

for (var i = 0; i < 10; i = i + 1) {
  print(i);
}
```

### 函式 (Functions)

```dart
fn add(a, b) {
  return a + b;
}

print(add(5, 3)); // 8
```

## 組件與狀態 (Widgets & State)

Flux 的核心特性是其組件系統。

### 有狀態組件 (Stateful Widgets)

`widget` 區塊定義一個 UI 組件。使用 `state` 定義可變數據。

```dart
widget Counter {
  state count = 0;

  build {
    Column(
      children: [
        Text(text: "計數: " + toString(count)),
        SizedBox(height: 16.0),
        Button(
          text: "增加", 
          onPressed: fn() {
            count = count + 1; // UI 會自動重新構建
          }
        )
      ]
    )
  }
}
```

### 無狀態組件 (Props)

使用 `props` 接收來自父組件的參數。

```dart
widget Greeting {
  props name;
  props color;

  build {
    Container(
      color: color,
      child: Text(text: "你好, " + name + "!")
    )
  }
}

// 使用方式
Greeting(name: "小明", color: "blue");
```

## 非同步程式設計 (Asynchronous Programming)

Flux 支援 `async` / `await` 進行非阻塞操作。

```dart
async fn fetchData() {
  var data = await http.get("https://api.example.com/data");
  return data;
}

widget DataLoader {
  state data = "載入中...";

  build {
    Column(
      children: [
        Text(text: data),
        Button(
          text: "載入", 
          onPressed: async fn() {
            data = await fetchData();
          }
        )
      ]
    )
  }
}
```

## 例外處理 (Exception Handling)

```dart
try {
  throw "出了點問題";
} catch (e) {
  print("捕獲到錯誤: " + e);
} finally {
  print("清理 (Cleanup)");
}
```

## 標準庫 (Standard Library)

- `print(obj)`：列印到控制台
- `toString(obj)`：轉換為字串
- `len(list)`：獲取長度
- `push(list, item)`：添加到列表
- `pop(list)`：移除最後一項
- `now()`：當前時間戳
- `toDouble(x)`, `toInt(x)`：類型轉換

## 原生互操作 (Native Interop)

Flux 允許指令碼與宿主環境（Dart/Flutter）之間進行無縫通訊。

### 註冊原生函式 (Dart 端)

您可以註冊原生的 Dart 函式，以便從 Flux 指令碼中呼叫：

```dart
// 在您的 Flutter 程式碼中
runtime.vm.registerFunction('showNativeDialog', (args) {
  final message = args[0] as String;
  // 實現原生邏輯...
  return null;
});
```

### 呼叫原生函式 (Flux 端)

一旦註冊完成，您就可以像呼叫普通函式一樣呼叫它們：

```dart
// 在您的 Flux 指令碼中
build {
  Button(
    text: "顯示原生對話框",
    onPressed: fn() {
      showNativeDialog("來自 Flux 的問候！");
    }
  )
}
```
