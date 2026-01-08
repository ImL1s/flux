# 更新日誌 (Changelog)

[English Documentation](CHANGELOG.md)

本檔案記錄了此專案的所有顯著變更。

## [3.0.0] - 2026-01-08

### 新增
- **網路增強 (Dio 遷移)**：
  - 將 `HttpModule` 遷移至 Dio 以實現強健的網路功能。
  - 支援 `connectTimeout` 與 `receiveTimeout`。
  - 整合 `LogInterceptor` 以優化偵錯體驗。
  - 新增透過 `cancel()` 與 `cancelAll()` 進行請求取消的功能。
  - 實現了 `application/json` 回應的自動 JSON 解碼。
  - 在回應映射中加入 `ok` 布林值，方便進行狀態檢查。
- **動畫系統 (V2)**：
  - 新增 `Animation.spring()` 以實現基於物理的動畫。
  - 新增 `Animation.stagger()` 以簡化交錯動畫序列的建立。
  - 新增 `Animation.colorTween()` 與 `Animation.sizeTween()`。
  - 將所有 Flutter `Curves` (例如：`fastOutSlowIn`, `easeInBack`) 同步至 Flux。

### 變更
- 重構 `HttpModule` 以支援 Dio 實體注入，提昇可測試性。
- 為了向後相容性，將 HTTP 回應標頭展平為 `Map<String, String>`。

## [2.0.1] - 2026-01-07

### 新增
- **狀態持久化 (State Persistence)**：使用 `persistent` 關鍵字透過 Hive CE 自動持久化狀態。
- **PersistenceDelegate**：自定義持久化後端的抽象介面。
- **HivePersistenceDelegate**：使用 Hive CE 的默認實現。

### 修復
- CI/CD 流水線依賴衝突 (`flux_updater` 路徑依賴)。
- 靜態分析警告 (`flux_vm` 不必要的類型檢查)。
- 遺漏的顯式依賴 (`flux_flutter` Hive CE 導入)。

## [2.0.0] - 2026-01-04

### 新增
- **FluxUI 組件庫**：完整的 UI 組件集 (Button, Card, Input, Badge, Row, Column, Grid, Stack)。
- **BLE 整合**：透過 `flutter_blue_plus` 提供完整的藍牙低功耗支援。
- **相機整合**：透過 `camera` 套件提供真實的相機功能。
- **設計系統**：支援主題 (Theme)、字體 (Typography) 與顏色 (Colors)。
- **CLI 增強**：`flux create`, `flux run`, `flux analyze` 命令。

### 變更
- 將所有套件升級至穩定的 v2.0.0 版本。
- 優化文檔與 API 參考。
- 增強 CI/CD 流水線。

### 修復
- 相機綁定恢復問題。
- 重複的 `_initFormWidgets()` 呼叫。
- 測試導入問題。

## [1.0.0] - 2025-12-01

### 新增
- 初始穩定版本。
- 包含詞法分析、語法分析與字節碼生成的 Flux 編譯器。
- 支援偵錯功能的 Flux 虛擬機 (VM)。
- 用於 IDE 整合的 LSP 伺服器。
- 用於 VS Code 的 DAP 偵錯器。
- 用於 UI 開發的 Flutter 綁定。
