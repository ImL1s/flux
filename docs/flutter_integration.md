# Flutter 整合指南

本指南將教你如何在 Flutter 應用中嵌入和使用 Flux 腳本。

## 1. 安裝與設定

在你的 Flutter 項目的 `pubspec.yaml` 中添加依賴：

```yaml
dependencies:
  flutter:
    sdk: flutter
  # 添加 Flux 依賴
  flux_vm: ^1.0.0
  flux_flutter: ^1.0.0
```

然後運行：
```bash
flutter pub get
```

---

## 2. 最基礎的用法 (FluxWidget)

`FluxWidget` 是核心組件，用於在 Flutter 界面中渲染 Flux 代碼。

### 顯示簡單文字

```dart
import 'package:flutter/material.dart';
import 'package:flux_flutter/flux_flutter.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flux 示例")),
      body: Center(
        child: FluxWidget(
          // 定義 Flux Widget 名稱
          widgetName: 'Greeting',
          // Flux 源代碼
          source: '''
            widget Greeting {
              build {
                return Text("你好，Flutter！");
              }
            }
          ''',
        ),
      ),
    );
  }
}
```

---

## 3. 狀態管理 (State)

Flux 擁有自己的狀態管理系統。當 `state` 變量改變時，UI 會自動更新。

### 計數器示例

```dart
FluxWidget(
  widgetName: 'Counter',
  source: '''
    widget Counter {
      // 定義狀態變量
      state count = 0;
      
      build {
        return Column(
          children: [
            Text("目前計數: " + count),
            
            // 按鈕觸發狀態改變
            Row(
              children: [
                Button(
                  text: "增加",
                  onTap: fn() { 
                    count = count + 1; 
                  }
                ),
                Button(
                  text: "減少",
                  onTap: fn() { 
                    count = count - 1; 
                  }
                )
              ]
            )
          ]
        );
      }
    }
  ''',
)
```

---

## 4. 支援的組件 (Widgets)

目前 Flux 支援以下基礎 Flutter 組件：

| Flux 組件 | 對應 Flutter | 屬性範例 |
|-----------|--------------|----------|
| `Text` | `Text` | `text: "Hello"`, `style: {...}` |
| `Button` | `ElevatedButton` | `text: "按我"`, `onTap: fn() {...}` |
| `Column` | `Column` | `children: [...]` |
| `Row` | `Row` | `children: [...]` |
| `Container` | `Container` | `padding: 10`, `color: "red"`, `child: ...` |
| `Image` | `Image.network` | `src: "https://..."` |
| `TextField` | `TextField` | `onChanged: fn(val) { ... }` |
| `Center` | `Center` | `child: ...` |

### 樣式示例

```dart
widget StyledBox {
  build {
    return Container(
      color: "blue",
      padding: 20,
      child: Text(
        text: "白色文字",
        style: {
          "color": "white",
          "fontSize": 24,
          "fontWeight": "bold"
        }
      )
    );
  }
}
```

---

## 5. 進階：Flutter 與 Flux 交互

### 從 Flutter 傳入初始數據

你可以通過 `initialState` 將數據傳入 Flux：

```dart
FluxWidget(
  widgetName: 'UserProfile',
  initialState: {
    'username': '小明',
    'level': 5
  },
  source: '''
    widget UserProfile {
      // 這些變量會被 initialState 初始化
      state username = "";
      state level = 0;
      
      build {
        return Text("用戶: " + username + " (Lv." + level + ")");
      }
    }
  ''',
)
```

---

## 6. 熱重載 (Hot Reload) 開發

Flux 支援即時熱重載，讓你在調整 UI 時無需重啟 App。

### 步驟 1: 設置熱重載服務

在你的 Flutter `main.dart` 中：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 連接到開發服務器 (模擬器用 10.0.2.2，真機用電腦 IP)
  final hotReload = await HotReloadService.connect('ws://127.0.0.1:8080');
  
  runApp(MyApp(hotReload: hotReload));
}
```

### 步驟 2: 使用 Flux CLI 啟動服務器 (在終端機)

```bash
# 監控 scripts 資料夾
flux dev --watch ./scripts
```

現在，當你修改 `./scripts` 中的 `.flux` 文件時，App 會自動更新！

---

## 常見問題

### Q: 為什麼我的 UI 沒有更新？
A: 確保你修改的是 `state` 變量。只有 `state` 關鍵字聲明的變量才會觸發重繪。普通 `var` 變量不會。

### Q: 支援自定義 Flutter 組件嗎？
A: 支援！你可以在 `FluxBindings` 中註冊自己的 Flutter 組件供 Flux 使用。

```dart
// 在 Flutter 中註冊
FluxBindings.register('MyCustomWidget', (args, children) {
  return MyCustomFlutterWidget(
    title: args['title'],
  );
});

// 在 Flux 中使用
widget Demo {
  build {
    return MyCustomWidget(title: "測試");
  }
}
```
