# Flux VSCode 擴充功能 (Flux VSCode Extension)

[English Documentation](README.md)

> 為 [Flux](https://github.com/ImL1s/flux) 提供語法高亮、程式碼片段和語言支援 —— 用於 Flutter 服務端驅動 UI (Server-Driven UI) 的動態指令碼語言。

## 特性

### 智慧化支援 (LSP)
- **跳轉到定義 (Go to Definition)**：導航至變數、函式和組件的聲明位置。
- **查詢所有引用 (Find All References)**：追蹤標識符在檔案中的使用情況。
- **自動補全 (Autocompletion)**：針對關鍵字、組件和標準庫 (stdlib) 提供語境相關的補全。
- **懸停資訊 (Hover Information)**：在懸停時顯示詳細的說明文件和類型簽名。
- **診斷功能 (Diagnostics)**：即時語法和語意錯誤回報。

### 語法高亮 (Syntax Highlighting)
- **關鍵字**：`if`, `else`, `while`, `for`, `return`, `break`, `continue`
- **非同步 (Async/Await)**：`async`, `await`
- **例項處理 (Exception Handling)**：`try`, `catch`, `finally`, `throw`
- **聲明關鍵字**：`widget`, `fn`, `var`, `class`
- **修飾符 (Modifiers)**：`state`, `props`, `build`
- **組件 (Widgets)**：大駝峰拼寫的標識符（例如 `Column`, `Button`, `Scaffold`）
- **字串**：支援雙引號和單引號
- **數字**：整數、浮點數、十六進位顏色
- **註解**：單行註解 (`//`) 和塊註解 (`/* */`)

### 程式碼片段 (Snippets)

| 前綴 | 說明 |
|--------|-------------|
| `widget` | 建立一個有狀態組件 (Stateful Widget) |
| `swidget` | 建立一個帶有 props 的無狀態組件 |
| `fn` | 函式聲明 |
| `afn` | 非同步函式聲明 |
| `if` / `ife` | If / If-else 語句 |
| `while` / `for` | 迴圈語句 |
| `try` / `tryf` | Try-catch / Try-catch-finally |
| `btn` | 帶有 onPressed 的按鈕 |
| `tf` | 帶有 onChanged 的 TextField |
| `scaffold` | 帶有 AppBar 的 Scaffold |
| `httpget` | 帶有 await 的 HTTP GET 請求 |
| `state` / `props` | 狀態/屬性聲明 |
| `col` / `row` | Column/Row 組件 |
| `listtile` | 帶有 onTap 的 ListTile |

## 安裝

### 透過 VSIX 安裝（本地）
```bash
cd packages/flux_vscode
npm install -g vsce
vsce package
code --install-extension flux-vscode-0.1.0.vsix
```

### 透過 Marketplace 安裝（即將推出）
在 VSCode 擴充功能商店中搜尋 "Flux"。

## 系統要求

- VSCode 1.75.0 或更高版本

## 選項設定

此擴充功能目前尚無可配置選項。

## 已知問題

- 多檔案符號解析（開發中）
- 暫不支援偵錯 (Debugging)

## 版本記錄

### 0.2.0
- 整合了 Flux 語言伺服器 (LSP)
- 支援跳轉到定義 (Go to Definition) 和查詢所有引用 (Find All References)
- 上下文感知的程式碼補全
- 即時錯誤診斷和懸停資訊

### 0.1.0
- 首次發布
- 針對所有 Flux 關鍵字提供語法高亮
- 提供 22 個常用模式的程式碼片段
- 語言配置（括號、註解處理）

## 貢獻

歡迎任何形式的貢獻！請訪問 [GitHub](https://github.com/ImL1s/flux) 提出 Issue 或提交 Pull Request。

## 授權協議

MIT
