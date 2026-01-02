# 🔥 Flux 熱更新展示 (Hot Update Demo)

這個範例展示了 Flux 的核心能力：在不重新編譯 App 的情況下，透過修改外部腳本即時更新 UI 和業務邏輯。

## 📁 目錄結構

- `scripts/` - 存放 Flux 腳本 (`.flux`)。
- `flutter_app/` - 載入並載入腳本的 Flutter 應用程序。

## 🚀 快速開始

### 1. 安裝與執行

```bash
cd examples/hot_update_demo/flutter_app
flutter pub get
flutter run -d windows  # 或其他桌面平台
```

### 2. 測試熱更新

1. 保持 App 運行。
2. 使用編輯器開啟 `examples/hot_update_demo/scripts/home_banner.flux`。
3. 修改任何內容（例如改變 `state theme` 的初值或修改 `Text` 文字）。
4. 儲存檔案。
5. 在 App 中點擊右上角的 **刷新按鈕 (🔄)**。

### 3. 觀察結果

UI 會立即根據新腳本重新渲染，且狀態（State）會重新初始化。

## 💡 技術要點

- **動態載入**：App 會從檔案系統動態讀取腳本內容。
- **即時編譯**：Flux VM 在運行時將原始碼編譯為 Bytecode 並執行。
- **跨平台**：同一份 `.flux` 腳本可以在所有支援的 Flutter 平台上運行。
- **路徑搜尋**：`main.dart` 內建了路徑搜尋邏輯，會自動在當前目錄及其父目錄中尋找 `scripts` 文件夾。

---

更多資訊請參考 [GitHub Repo](https://github.com/ImL1s/flux)
