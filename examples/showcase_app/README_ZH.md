# Flux 綜合展示應用 (Showcase App)

這是一個功能完整的範例應用，展示了 Flux 腳本在真實場景中的強大能力。

## 📱 包含頁面

| 頁面 | 描述 | 展示技術 | 腳本路徑 |
|------|------|----------|----------|
| **🛒 電商產品** | 產品詳情與互動 | 圖片輪播、狀態管理、Toast 調用 | `scripts/product_page.flux` |
| **✅ 待辦事項** | 簡易 CRUD | 列表操作、條件渲染 | `scripts/todo_page.flux` |
| **⚙️ 應用設定** | 系統偏好設定 | 開關、滑桿、原生儲存存取 | `scripts/settings_page.flux` |
| **📊 數據儀表板** | 異步數據展示 | **Async/Await**、**Dio API 請求** | `scripts/dashboard_page.flux` |

## 🚀 如何運行

### 1. 啟動後端伺服器 (提供 API 與腳本)

```bash
cd examples/showcase_app/server
dart pub get
dart server.dart
```
> 伺服器運行於 `http://localhost:8082`

### 2. 啟動 App

```bash
cd examples/showcase_app/flutter_app
flutter pub get
flutter run -d windows
```

## 🔥 嘗試熱更新

1. 保持 App 運行在「數據儀表板」頁面。
2. 開啟 `scripts/dashboard_page.flux`。
3. 修改標題文字，例如將「營運總覽」改為「即時戰情室」。
4. 儲存檔案，點擊 App 右上角的重新整理按鈕。
5. **見證 UI 瞬間更新！**

## 🏗️ 系統架構

- **Flutter (Dart)**: 負責 App 骨架、導航 (`BottomNavigationBar`) 與原生功能 (Dio, Storage)。
- **Flux**: 負責所有頁面的 UI 佈局與業務邏輯。
- **Riverpod**: 作為狀態中介，雖然此範例主要由 Flux 內部 State 管理，但架構上支援雙向綁定。
