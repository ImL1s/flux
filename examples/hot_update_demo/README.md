# 🔥 Flux 熱更新完整示範

這個範例展示如何使用 Flux 實現 **「無需重新發布 App 就能更新 UI」** 的完整流程。

---

## 📁 項目結構

```
hot_update_demo/
├── flutter_app/           # Flutter 客戶端應用
│   ├── lib/main.dart      # 主程式
│   └── pubspec.yaml       # 依賴配置
├── scripts/               # Flux 腳本 (模擬後端)
│   └── home_banner.flux   # 可熱更新的首頁 Banner
└── README.md              # 本文檔
```

---

## 🎯 這個範例做什麼？

**場景**：你的 App 首頁有一個活動 Banner。
- 第一週：顯示「春季特賣」(綠色主題)
- 第二週：顯示「母親節」(粉紅主題)
- 第三週：顯示「端午節」(橙色主題)

**傳統做法**：每次都要改 Dart 代碼 → 提交審核 → 用戶更新 App。

**Flux 做法**：只需要修改 `home_banner.flux` 文件，App 自動載入新版本！

---

## 🚀 快速開始

### 步驟 1：運行 Flutter App

這個 Demo 模擬「本機文件」作為「後端伺服器」。

#### 🖥️ Windows / macOS / Linux (推薦)
這是最簡單的方式，因為 App 可以直接讀取您的硬碟文件。

```bash
cd flutter_app
flutter run -d windows  # 或 linux, macos
```

#### 📱 Android (真機/模擬器)
Android App 運行在沙盒中，無法直接讀取電腦硬碟。您需要用 `adb` 把腳本「推」到手機裡，模擬「下載」過程。

1. **推送腳本到手機**：
   ```bash
   # 在 hot_update_demo/ 目錄下運行
   adb push scripts/home_banner.flux /data/local/tmp/home_banner.flux
   ```

2. **修改 Flutter 讀取路徑**：
   打開 `lib/main.dart`，將 `_loadBannerScript` 中的路徑改為：
   ```dart
   final file = File('/data/local/tmp/home_banner.flux');
   ```

3. **運行 App**：
   ```bash
   flutter run -d android
   ```

4. **如何更新？**
   修改電腦上的 `scripts/home_banner.flux`，然後再次運行 `adb push` 命令，最後點擊 App 上的刷新按鈕。

#### 🍎 iOS (模擬器)
iOS 模擬器可以直接讀取電腦文件系統，但路徑會不同。

1. 使用 `flutter run -d iphone` 運行。
2. 如果 App 提示找不到文件，請手動將絕對路徑寫死在 `main.dart` 中用作測試，例如：
   ```dart
   final file = File('/Users/yourname/projects/flux/examples/hot_update_demo/scripts/home_banner.flux');
   ```

> **💡 生產環境提示**：
> 在真實發布的 App 中，您不需要這麼麻煩！App 會使用 `http.get()` 從雲端下載腳本，所以**所有平台 (iOS/Android/Web/Desktop) 的代碼都是一樣的**，完全不需要處理文件路徑問題。本範例僅因為是「離線模擬」才需要處理文件權限。

### 步驟 2：觀察 App

App 啟動後，您會看到一個「春季特賣」的綠色 Banner。

### 步驟 3：模擬熱更新

打開 `scripts/home_banner.flux`，將：
```dart
state theme = "spring";  // 改成 "mother" 或 "dragon"
```

保存文件。

### 步驟 4：在 App 中點擊「刷新」按鈕

App 會從「後端」(本地 scripts 資料夾) 重新載入腳本，Banner 立刻變成新主題！

---

## 📄 核心代碼解析

### Flutter 端 (`flutter_app/lib/main.dart`)

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flux_flutter/flux_flutter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flux 熱更新 Demo',
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _bannerScript;
  
  @override
  void initState() {
    super.initState();
    _loadBannerScript();
  }
  
  /// 從「後端」載入腳本 (這裡用本地文件模擬)
  Future<void> _loadBannerScript() async {
    // 實際生產環境：這裡改成 http.get('https://api.yourapp.com/scripts/home_banner.flux')
    final file = File('../scripts/home_banner.flux');
    final script = await file.readAsString();
    setState(() => _bannerScript = script);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flux 熱更新 Demo'),
        actions: [
          // 手動觸發「熱更新」
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBannerScript,
            tooltip: '模擬從後端刷新腳本',
          ),
        ],
      ),
      body: Column(
        children: [
          // === 這個 Banner 是 Flux 動態渲染的 ===
          if (_bannerScript != null)
            FluxWidget(
              widgetName: 'HomeBanner',
              source: _bannerScript!,
            )
          else
            const CircularProgressIndicator(),
            
          const SizedBox(height: 20),
          const Text('👆 點擊右上角刷新按鈕來觸發熱更新'),
          const Text('修改 scripts/home_banner.flux 後再刷新'),
        ],
      ),
    );
  }
}
```

---

### Flux 腳本 (`scripts/home_banner.flux`)

```dart
// === 可熱更新的首頁 Banner ===
// 修改 theme 變量來切換主題，無需重新編譯 App！

widget HomeBanner {
  // 🔄 修改這裡的值來觸發熱更新！
  // 可選值: "spring", "mother", "dragon"
  state theme = "spring";
  
  build {
    // 根據 theme 動態決定顏色和文字
    var color = "green";
    var title = "🌸 春季特賣";
    var subtitle = "全場 30% OFF";
    
    if (theme == "mother") {
      color = "pink";
      title = "💐 母親節快樂";
      subtitle = "為媽媽準備一份驚喜";
    }
    
    if (theme == "dragon") {
      color = "orange";
      title = "🐲 端午節";
      subtitle = "粽子禮盒 5 折起";
    }
    
    return Container(
      color: color,
      padding: 24,
      child: Column(
        children: [
          Text(text: title, style: {"fontSize": 28, "fontWeight": "bold", "color": "white"}),
          Text(text: subtitle, style: {"fontSize": 18, "color": "white"}),
          Button(
            text: "立即查看",
            onTap: fn() { print("用戶點擊了 Banner"); }
          )
        ]
      )
    );
  }
}
```

---

## 🔄 完整流程圖

```
┌─────────────────────────────────────────────────────────────────┐
│                         熱更新流程                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌───────────┐     ┌───────────┐     ┌───────────────────┐    │
│   │  運營人員  │────▶│  修改腳本  │────▶│ 上傳到後端伺服器   │    │
│   └───────────┘     └───────────┘     └───────────────────┘    │
│                                               │                 │
│                                               ▼                 │
│   ┌───────────┐     ┌───────────┐     ┌───────────────────┐    │
│   │  用戶手機  │◀────│  下載腳本  │◀────│    HTTP API        │    │
│   └───────────┘     └───────────┘     └───────────────────┘    │
│         │                                                       │
│         ▼                                                       │
│   ┌───────────────────────────────────────────────────────┐    │
│   │  Flux VM 執行腳本 → 渲染新 UI → 用戶立刻看到變化！      │    │
│   └───────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 💡 生產環境建議

| 項目 | 開發模式 (本範例) | 生產模式 |
|------|-----------------|---------|
| 腳本來源 | 本地 `File` 讀取 | `http.get()` 從 CDN/API 獲取 |
| 更新觸發 | 手動點擊刷新 | App 啟動時自動檢查 / 推送通知 |
| 腳本存儲 | 本地文件夾 | AWS S3 / Firebase Storage / 自建 API |
| 安全性 | 無 | 使用 Ed25519 簽名驗證腳本 |

---

## 🎉 恭喜！

您已經理解了 Flux 熱更新的核心概念：
1. **Flux 腳本是數據**，可以從任何地方載入。
2. **FluxWidget** 負責執行腳本並渲染 UI。
3. **修改腳本 = 更新 UI**，完全不需要重新發布 App。

這就是 Flux 的威力：讓您的 App 具有**動態運營能力**！
