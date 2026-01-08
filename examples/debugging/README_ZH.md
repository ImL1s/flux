# 偵錯 Flux 應用程式 (Debugging Flux Applications)

[English Documentation](README.md)

Flux 支援透過 **Flux VSCode 擴充功能** 在 VSCode 中使用完整的偵錯功能。

## 特性
- **斷點 (Breakpoints)**：點擊側邊欄來暫停執行。
- **單步執行**：步過 (F10)、步入 (F11)、步出 (Shift+F11)。
- **變數檢查**：檢查區域變數、列表、映射 (Map) 和類別。
- **呼叫堆棧 (Call Stack)**：查看當前的執行追蹤。
- **深度檢查**：在變數視圖中展開複雜物件。

## 如何進行偵錯

1. 在 VSCode 中開啟 `debug_example.flux`。
2. 在左側欄點擊設定斷點（例如在 `calculateSum` 函式內）。
3. 按下 **F5** 或前往「執行與偵錯 (Run and Debug)」 -> 選擇 "Dart & Flux"。
4. 偵錯器將啟動並在您的斷點處暫停。
5. 使用偵錯工具欄單步執行程式碼。

## REPL 評估
在暫停狀態下，您可以在 **偵錯主控台 (Debug Console)** 中評估表達式：
- 輸入 `total` 查看其當前值。
- 輸入 `i * 2` 測試計算結果。
- 輸入 `config["mode"]` 檢查映射表的值。
