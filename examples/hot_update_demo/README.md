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

```bash
cd flutter_app
flutter pub get
flutter run
```

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
