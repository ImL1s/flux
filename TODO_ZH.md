# Flux 待辦清單 (TODO)

[English Documentation](TODO.md)

本檔案用於追蹤計劃中的特性與改進。每個項目都應在獨立的特性分支上實作，並提交相應的 PR。

## ✅ 已完成特性 (v2.0.0)

### FluxUI 組件庫
- [x] 核心組件 (Button, Card, Input, Badge)
- [x] 佈局組件 (Column, Row, Stack, Grid)
- [x] 設計系統支援 (主題、字體、顏色)

### CLI 增強
- [x] `flux create` - 專案腳手架建立
- [x] `flux run` - 具備熱重載的增強執行功能
- [x] `flux analyze` - 整合靜態分析

### BLE 整合
- [x] 整合真實的 `flutter_blue_plus`
- [x] 連接狀態管理
- [x] 權限處理 (Android/iOS)
- [x] 使用 BLE mock 進行單元測試

### 相機整合
- [x] 整合真實的 `camera` 套件
- [x] 生命周期管理
- [x] 平台特定配置

### 基礎設施
- [x] DAP 偵錯器
- [x] LSP 智能提示
- [x] 編譯器優化
- [x] VM 內聯緩存 (Inline Caching)
- [x] CI/CD 流水線
- [x] Pub.dev 發布

---

## 🔵 計劃中特性 (v3.0)

### 特性：狀態持久化 ✅
- **描述**：自動化的狀態持久化與恢復
- **狀態**：已於 v2.0.1 完成
- **實作內容**：
  - [x] Flux 語言中的 `persistent` 關鍵字
  - [x] 用於複雜狀態的 Hive CE 整合
  - [x] PersistenceDelegate 抽象層
  - [x] HivePersistenceDelegate 實作

### 特性：網路層
- **描述**：在 Flux 腳本中內置 HTTP/WebSocket 支援
- **目標**：
  - [ ] HTTP 用戶端綁定 (GET, POST, PUT, DELETE)
  - [ ] WebSocket 即時通訊
  - [x] **網路模組增強**
    - [x] 遷移至 Dio 用戶端
    - [x] BaseUrl 與逾時配置
    - [x] 回應攔截器 (日誌、錯誤)
    - [x] 請求取消支援

### 特性：動畫系統
- **描述**：在 Flux 腳本中實作聲明式動畫
- **目標**：
  - [x] **動畫模組增強**
    - [x] 彈簧物理模擬 (`Animation.spring`)
    - [x] 交錯動畫 (`Animation.stagger`)
    - [x] 顏色與尺寸補間動畫 (Tweens)
    - [x] 完整的 Curves 同步
  - [ ] 透過腳本實現 Hero 過渡動畫

### 特性：多平台擴展
- **描述**：平台特定功能支援
- **目標**：
  - [ ] Web 電腦版支援
  - [ ] 桌面端 (Windows/macOS/Linux) 支援
  - [ ] 平台特定綁定 API

### 特性：插件系統
- **描述**：第三方插件架構
- **目標**：
  - [ ] 插件註冊中心
  - [ ] 插件生命週期管理
  - [ ] 插件沙箱化
  - [ ] 社群插件市場

### 特性：開發者體驗 (DX)
- **描述**：增強型 DX 工具
- **目標**：
  - [ ] FluxDevTools 瀏覽器擴充功能
  - [ ] 性能分析器 (Profiler)
  - [ ] 記憶體洩漏檢測
  - [ ] 可視化組件檢查器 (Widget Inspector)

---

## 📝 備註

- 每個特性分支應遵循命名規範：`feature/<name>`
- 所有特性在合併前均需進行測試
- 使用網絡搜索獲取最新的套件版本與最佳實踐
- PR 應針對 `dev` 分支
