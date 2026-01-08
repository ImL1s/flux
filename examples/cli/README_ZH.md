# Flux CLI 指南 (Flux CLI Guide)

[English Documentation](README.md)

**Flux CLI** 是用於開發、編譯和執行 Flux 應用程式的核心工具。

## 安裝

假設您已經安裝了 Flux SDK：

```bash
# 將 flux 添加到您的路徑或透過 dart 執行
dart pub global activate flux_cli
```

## 常用命令

### 1. 執行指令碼 (Run)
直接從源碼執行 Flux 指令碼：

```bash
flux run script.flux
```

### 2. 編譯為字節碼 (Build)
將指令碼編譯為帶有源碼映射 (Source Maps) 的優化二進制 `.flx` 檔案：

```bash
flux build script.flux -o output.flx
```
這將生成：
- `output.flx`：可執行的字節碼
- `output.flx.map`：用於偵錯的源碼映射

### 3. 指令碼簽名 (Security)
使用 Ed25519 簽名保護您的指令碼：

```bash
# 生成新的金鑰對
flux keygen

# 簽名指令碼（建立簽名頁腳）
flux sign script.flux --private-key private.key

# 驗證指令碼的完整性
flux verify script.flux --public-key public.key
```

### 4. 開發伺服器 (Serve)
啟動具備熱重載能力的開發伺服器：

```bash
flux serve main.flux
```

## 目錄結構
- `signing_demo/`：加密簽名範例
- `build_demo/`：編譯與優化範例
