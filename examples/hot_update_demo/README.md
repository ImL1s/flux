# 🔥 Flux 熱更新展示 (Hot Update Demo)

這個範例展示了 Flux 的核心能力：在不重新編譯 App 的情況下，透過修改外部腳本即時更新 UI 和業務邏輯。

## 📁 目錄結構

- `scripts/` - 存放 Flux 腳本 (`.flux`)。
- `server/` - 一個簡單的 Dart HTTP 伺服器，模擬遠端更新伺服器。
- `flutter_app/` - 載入並載入腳本的 Flutter 應用程序。

## 🚀 快速開始

### 1. 啟動熱更新伺服器 (選用)

如果您想測試真正的「遠端」更新，請先啟動伺服器：

```bash
cd examples/hot_update_demo/server
dart server.dart
```
伺服器將運行在 `http://localhost:8081`。

### 2. 啟動 Flutter App

```bash
cd examples/hot_update_demo/flutter_app
flutter pub get
flutter run -d windows  # 或其他桌面平台
```

### 3. 測試更新

1. 在 App 頂部切換 **「本地檔案」** 或 **「遠端伺服器」** 模式。
2. 開啟並修改 `examples/hot_update_demo/scripts/home_banner.flux`。
3. 儲存檔案。
4. 點擊 App 右上角的 **刷新按鈕 (🔄)**。

## 💡 技術要點

- **雙模式支援**：支援從本地檔案系統或遠端 HTTP URL 載入腳本。
- **Bytecode 執行**：腳本在載入後會立即編譯為 Bytecode 並由專屬 VM 執行。
- **路徑自動搜尋**：App 內建智慧路徑搜尋，自動定位 `scripts` 文件夾。
- **完整腳本語言**：除了 UI，還能處理 State、函數邏輯等。

---

更多資訊請參考 [GitHub Repo](https://github.com/ImL1s/flux)
