# 🔥 Flux 熱更新展示

Flux 是一個為 Flutter 設計的動態 UI 框架，允許在不重新發布 App 的情況下即時更新介面。

## 🚀 快速啟動

```bash
# 1. 進入展示目錄
cd examples/hot_update_demo/flutter_app

# 2. 安裝依賴
flutter pub get

# 3. 運行 (Windows/macOS/Linux)
flutter run -d windows
# 或
flutter run -d macos
# 或
flutter run -d linux
```

## 📱 展示功能

| 功能 | 說明 |
|------|------|
| 📊 狀態管理 | 計數器即時更新 |
| 🎨 動態主題 | 點擊切換顏色 |
| 📝 列表操作 | 動態新增/清空 |
| 🔄 熱更新 | 修改腳本即時生效 |

## 🎯 測試熱更新

1. **開啟** `scripts/home_banner.flux`
2. **修改**任何內容 (顏色、文字、邏輯)
3. **儲存**檔案
4. **點擊** App 右上角 🔄

**無需重新編譯，UI 立即更新！**

## 💡 應用場景

- 🎄 節日活動 - 即時更換 Banner
- 🐛 緊急修復 - 分鐘級上線
- 🧪 A/B 測試 - 無需發版
- 🌍 本地化 - 動態載入 UI
