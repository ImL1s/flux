# Flux vs Lua 熱更新：技術對比

Flux 的設計理念借鏡了遊戲產業中成熟的 Lua 熱更新模式，並針對 Flutter 生態系統進行了專門優化。

## 核心概念對比

| 特性 | Lua 熱更新 | Flux 熱更新 |
|------|----------|------------|
| **腳本化邏輯** | 遊戲邏輯寫在 `.lua` 腳本中 | UI 和邏輯寫在 `.flux` 腳本中 |
| **嵌入式 VM** | App 內嵌 Lua VM 執行腳本 | App 內嵌 Flux VM 執行 Bytecode |
| **動態載入** | 從伺服器下載新腳本並重新載入 | 從伺服器下載新腳本並重新載入 |
| **繞過審核** | 可繞過 App Store 審核推送更新 | 同樣可繞過審核（腳本不改變核心功能） |
| **沙箱執行** | 在隔離環境中執行，不影響宿主 App | 同樣設計為沙箱化執行 |

## 技術差異

| 特性 | Lua 方案 | Flux 方案 |
|------|---------|----------|
| **主要用途** | 遊戲邏輯（Unity/Cocos2d-x） | Flutter UI + 業務邏輯 |
| **Flutter 整合** | 需第三方套件如 `LuaDardo` | 原生設計專為 Flutter |
| **語法風格** | Lua 語法（學習曲線較高） | 類 Dart/JS 語法（學習成本低） |
| **Widget 支援** | 需自行橋接 Flutter Widget | 內建完整 Flutter Widget 綁定 |
| **狀態管理** | 需自行實現 | 內建 `state` 關鍵字 + Riverpod 整合 |

## 業界方案對比

### 🎮 遊戲領域
- **xLua（騰訊）**：用於 Unity 遊戲熱更新，廣泛應用於中國手遊市場。
- **Cocos2d-x + Lua**：許多 2D 遊戲使用 Lua 腳本化遊戲邏輯。
- **ToLua / SLua**：Unity 的其他 Lua 整合方案。

### 📱 Flutter 領域
- **LuaDardo**：純 Dart 實現的 Lua 5.3 VM，需自行處理 Widget 橋接。
- **flutter_embed_lua**：嵌入式 Lua 解譯器，但缺乏 UI 整合。
- **Shorebird**：Flutter 專屬的 Dart Code Push 方案，只能推送 Dart 代碼。

## Flux 的獨特優勢

1. **專為 Flutter 設計**
   - 不需要額外的橋接層，直接支援 Flutter Widget。
   - 與 Flutter 的響應式 UI 模型完美契合。

2. **類 Dart 語法**
   - 對 Flutter 開發者幾乎零學習成本。
   - 使用 `widget`、`state`、`build` 等熟悉的關鍵字。

3. **完整工具鏈**
   - LSP 支援（智能補全、跳轉定義）
   - VS Code Extension（語法高亮、程式碼片段）
   - CLI 工具（腳本執行與調試）

4. **輕量級整合**
   - 不需要像 xLua 那樣複雜的設置。
   - 單一 `FluxWidget` 即可嵌入任何 Flutter 頁面。

## 語言對接機制

### Lua 如何與宿主語言對接

Lua 之所以能在遊戲產業廣泛使用，關鍵在於它優秀的**嵌入式設計**和**雙向綁定機制**：

```
┌─────────────────────────────────────────────────────┐
│                    宿主應用程式                      │
│  ┌───────────┐        ┌───────────────────────────┐ │
│  │  C/C++    │◄──────►│     Lua VM               │ │
│  │  代碼     │ Stack  │  ┌─────────────────────┐  │ │
│  │           │ API    │  │   Lua 腳本          │  │ │
│  └───────────┘        │  └─────────────────────┘  │ │
│                       └───────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

**Lua 的 C API 特點：**
1. **Stack-based 通訊**：透過一個虛擬「堆棧」在 C 和 Lua 之間傳遞數據。
2. **註冊 C 函數**：可以將 C 函數暴露給 Lua 腳本調用。
3. **調用 Lua 函數**：C 代碼可以執行 Lua 腳本中的函數。
4. **完整類型轉換**：自動處理 Lua table ↔ C struct 等轉換。

### Flux 如何與 Dart/Flutter 對接

Flux 採用類似的設計理念，但針對 Dart 和 Flutter 進行了優化：

```
┌─────────────────────────────────────────────────────┐
│                   Flutter 應用程式                   │
│  ┌───────────┐        ┌───────────────────────────┐ │
│  │   Dart    │◄──────►│     Flux VM              │ │
│  │   代碼    │Bindings│  ┌─────────────────────┐  │ │
│  │  (Widget) │        │  │   .flux 腳本        │  │ │
│  └───────────┘        │  └─────────────────────┘  │ │
│                       └───────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

**Flux 的綁定系統：**

| 能力 | Lua (C API) | Flux (Dart Bindings) |
|------|-------------|---------------------|
| 從腳本調用宿主函數 | `lua_register()` | `registerFunction()` |
| 從宿主調用腳本函數 | `lua_pcall()` | `vm.callFunction()` |
| 傳遞複雜數據 | Stack push/pop | 直接 Dart 物件映射 |
| UI 組件整合 | 需自行橋接 | 內建 Widget Bindings |

### Flux 綁定範例

**1. 從 Flux 調用 Dart 函數：**

```dart
// Dart 側：註冊一個原生函數
final vm = VM();
vm.registerFunction('showToast', (args) {
  final message = args[0] as String;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
  return null;
});
```

```javascript
// Flux 腳本中調用
showToast("Hello from Flux!")
```

**2. 從 Dart 讀取 Flux 狀態：**

```dart
// 透過 Riverpod Provider 雙向同步
final counterProvider = NotifierProvider<FluxValueNotifier<int>, int>(
  () => FluxValueNotifier(0),
);

// Flux 腳本可以讀寫這個 Provider
// Dart 側也可以監聽變化
```

**3. 內建 Widget 綁定：**

Flux 已內建 50+ Flutter Widget 的綁定，無需手動橋接：

```javascript
// 直接在 Flux 中使用 Flutter Widget
Container(
  color: "blue",
  child: Column(
    children: [
      Text(text: "Hello"),
      Button(text: "Click", onPressed: fn() { ... })
    ]
  )
)
```

### 擴展性對比

| 擴展場景 | Lua | Flux |
|---------|-----|------|
| 新增原生函數 | ✅ 透過 C API 註冊 | ✅ 透過 `registerFunction` |
| 新增 Widget 類型 | ❌ 需手動實現 | ✅ 可擴展 Widget Bindings |
| 雙向狀態同步 | ⚠️ 需自行實現 | ✅ 內建 Riverpod 整合 |
| 異步操作 | ⚠️ 需 coroutine 配合 | ✅ 原生 `async/await` |

## 結論


Flux 不是從零發明的新概念，而是將**遊戲產業驗證過的 Lua 熱更新模式**，專門為 **Flutter 生態系統**重新設計的方案。它結合了 Lua 方案的成熟性與 Flutter 開發的便利性，為跨平台應用提供了一個優雅的動態更新解決方案。

---

📚 [返回主文檔](../README.md) | [Lua 遷移指南](./lua_migration.md)
