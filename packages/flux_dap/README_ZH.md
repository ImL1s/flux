# Flux DAP (Debug Adapter Protocol)

[English Documentation](README.md)

Flux 程式語言的偵錯適配器協議 (Debug Adapter Protocol) 實現。

此套件允許支援 DAP 的 IDE（如 VS Code）與 Flux 虛擬機進行通訊，以提供斷點、單步執行和變數檢查等偵錯功能。

## 特性

- **斷點管理**：設定、移除和切換斷點。
- **單步執行**：步入 (Step Into)、步過 (Step Over)、步出 (Step Out)。
- **變數檢查**：檢查當前作用域內的變數值。
- **呼叫堆棧**：查看當前執行點的呼叫堆棧。
- **熱重載偵錯**：支援在熱重載過程中保持偵錯會話。

## 用法

此套件通常由 [Flux VSCode 擴充功能](../flux_vscode) 內部呼叫。

手動啟動 DAP 伺服器：
```bash
dart run flux_dap:main
```

## 貢獻

歡迎提交 PR！詳情請參閱 [Flux 主專案](https://github.com/ImL1s/flux)。
