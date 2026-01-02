# 🔥 Flux 熱更新展示

Flux 是一個為 Flutter 設計的動態 UI 框架，允許在不重新發布 App 的情況下即時更新介面。

## 核心概念

### 傳統 Flutter vs Flux

| 傳統 Flutter | Flux 熱更新 |
|-------------|------------|
| 修改代碼 → 編譯 → 審核 → 等待1-7天 | 修改腳本 → 推送 → **秒級生效** |

### 運作流程

```
開發者 → 修改 .flux 腳本
         ↓
伺服器 → 推送更新
         ↓
FluxVM → 編譯為 bytecode
         ↓
Flutter → UI 即時更新 ✨
```

## 快速開始

### 1. 運行展示 App

```bash
cd examples/hot_update_demo/flutter_app
flutter run -d windows
```

### 2. 修改腳本

編輯 `scripts/home_banner.flux`：

```flux
widget HomeBanner {
  state count = 0
  state theme = "blue"

  build {
    Container(
      color: theme,
      child: Column(
        children: [
          Text(text: "計數: " + count),
          Button(text: "加1", onPressed: fn() { count = count + 1; }),
          Button(text: "換色", onPressed: fn() { theme = "green"; })
        ]
      )
    )
  }
}
```

### 3. 重新載入

點擊 App 右上角 🔄 按鈕，UI 立即更新！

## Flux 語法

### 狀態定義

```flux
state count = 0           // 數字
state name = "Flux"       // 字串
state items = [1, 2, 3]   // 列表
```

### Widget 建構

```flux
widget MyWidget {
  build {
    Container(
      padding: 20.0,
      color: "blue",
      child: Text(text: "Hello!")
    )
  }
}
```

### 事件處理

```flux
Button(
  text: "點我",
  onPressed: fn() {
    count = count + 1;
  }
)
```

## 技術架構

```
┌─────────────────────────────────────────────┐
│  Flux 腳本 (.flux)                          │
└─────────────────┬───────────────────────────┘
                  ↓
┌─────────────────────────────────────────────┐
│  Lexer → Parser → Compiler                  │
│  詞法分析  語法分析   編譯器                   │
└─────────────────┬───────────────────────────┘
                  ↓
┌─────────────────────────────────────────────┐
│  Bytecode (字節碼)                          │
└─────────────────┬───────────────────────────┘
                  ↓
┌─────────────────────────────────────────────┐
│  Flux VM 虛擬機執行                          │
└─────────────────┬───────────────────────────┘
                  ↓
┌─────────────────────────────────────────────┐
│  FluxWidget → Flutter UI                    │
└─────────────────────────────────────────────┘
```

## 實際應用場景

- 🎄 **節日活動** - 即時更換 Banner 和主題
- 🐛 **緊急修復** - 10分鐘內修復 UI Bug
- 🧪 **A/B 測試** - 無需發版切換不同版本
- 🌍 **本地化** - 動態載入不同語言的 UI

## 注意事項

1. `build { }` 區塊內直接寫表達式，不需要 `return`
2. 狀態變數使用 `state` 關鍵字宣告
3. 事件回調使用 `fn() { }` 匿名函數語法
