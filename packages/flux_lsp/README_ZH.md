# Flux LSP

[English Documentation](README.md)

[![pub package](https://img.shields.io/pub/v/flux_lsp.svg)](https://pub.dev/packages/flux_lsp)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Flux 程式語言的語言伺服器協議 (Language Server Protocol) 實現。

此套件為支援 LSP 的編輯器（如 VS Code, Sublime Text, Vim 等）提供開發智慧化支援。

## 特性

- **自動補全 (Autocomplete)**：針對關鍵字、字串、專案組件等提供智慧提示。
- **診斷 (Diagnostics)**：即時回報語法和語意錯誤。
- **跳轉到定義 (Go to Definition)**：快速導航到變數、函式或類別的定義位置。
- **查詢所有引用 (Find All References)**：追蹤標識符在專案中的使用情況。
- **懸停資訊 (Hover)**：顯示符號的類型和說明文件。
- **程式碼格式化**：自動美化 Flux 代碼。

## 用法

通常情況下，您不需要直接執行此套件。它由編輯器擴充功能（如 [Flux VSCode](https://github.com/ImL1s/flux/tree/main/packages/flux_vscode)）自動啟動。

如果您需要手動啟動伺服器：

```bash
dart run flux_lsp:main
```

## IDE 整合

- **VS Code**: 安裝 [Flux 擴充功能](https://github.com/ImL1s/flux/tree/main/packages/flux_vscode)。
- **其他編輯器**: 配置您的 LSP 客戶端以執行 `dart run flux_lsp:main` 或編譯後的二進位制檔案。

## 貢獻

歡迎提交 Issue 或 Pull Request！請參閱 [Flux 主專案](https://github.com/ImL1s/flux) 了解更多資訊。
