# Flux CLI (flux_lang_cli)

[English Documentation](README.md)

[![pub package](https://img.shields.io/pub/v/flux_lang_cli.svg)](https://pub.dev/packages/flux_lang_cli)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Flux 腳本語言的命令行介面。

## 安裝

### 全域啟用（推薦）

```bash
# 從 flux_cli 套件目錄下
cd packages/flux_cli
dart pub global activate --source path .

# 現在您可以全域使用 'flux' 命令了
flux --help
```

### 本地執行

```bash
# 從 flux_cli 目錄下
dart run flux_cli:flux <command>
```

## 命令列表

### `flux create` - 專案腳手架 (Project Scaffolding)

從模板建立一個新的 Flux 專案。

```bash
flux create <project-name> [options]
```

**選項：**
| 選項 | 描述 | 預設值 |
|--------|-------------|---------|
| `-t, --template` | 使用的模板：`basic`, `flutter`, `server` | `basic` |
| `-f, --force` | 強制覆蓋現有目錄 | `false` |

**範例：**
```bash
# 建立一個基礎 Flux 專案
flux create my_app

# 建立一個 Flutter UI 專案
flux create my_flutter_app --template flutter

# 建立一個服務端專案
flux create my_server --template server

# 強制覆蓋現有目錄
flux create my_app --force
```

**生成的檔案：**
- `main.flux` - 入口指令碼
- `flux.yaml` - 專案配置
- `README.md` - 專案說明文檔

---

### `flux run` - 執行指令碼

執行 Flux 指令碼，支援熱重載選項。

```bash
flux run <file.flux> [options]
```

**選項：**
| 選項 | 描述 |
|--------|-------------|
| `-w, --watch` | 監視檔案更改並自動重新執行 |
| `-v, --verbose` | 顯示詳細輸出 |

**範例：**
```bash
# 單次執行指令碼
flux run main.flux

# 開啟熱重載執行（檔案更改時自動重新執行）
flux run main.flux --watch

# 以詳細模式執行
flux run main.flux --verbose
```

---

### `flux analyze` - 靜態分析

分析 Flux 指令碼中的錯誤和警告。

```bash
flux analyze <file-or-directory> [options]
```

**選項：**
| 選項 | 描述 |
|--------|-------------|
| `-v, --verbose` | 顯示資訊訊息 |
| `--fatal-warnings` | 將警告視為錯誤處理 |

**範例：**
```bash
# 分析單個檔案
flux analyze main.flux

# 分析目錄下的所有 .flux 檔案
flux analyze ./src/

# 嚴格模式（警告等同錯誤）
flux analyze . --fatal-warnings
```

---

### `flux build` - 編譯為字節碼

將 Flux 指令碼編譯為字節碼檔案 (.flx)。

```bash
flux build <file.flux> [options]
```

**選項：**
| 選項 | 描述 |
|--------|-------------|
| `-o, --output` | 輸出檔案路徑 |

**範例：**
```bash
flux build main.flux
flux build main.flux -o dist/app.flx
```

---

### `flux serve` - 開發伺服器

為 Flutter 客戶端提供 Flux 指令碼服務。

```bash
flux serve <file.flux> [options]
```

**選項：**
| 選項 | 描述 | 預設值 |
|--------|-------------|---------|
| `-p, --port` | 伺服器埠號 | `8765` |
| `-w, --watch` | 監視更改 | `false` |

**範例：**
```bash
flux serve app.flux
flux serve app.flux --port 3000 --watch
```

---

### `flux dev` - 開發模式

啟動帶有檔案監視功能的開發伺服器。

```bash
flux dev [directory] [port]
```

**範例：**
```bash
flux dev
flux dev ./scripts 8080
```

---

### 安全相關命令

#### `flux keygen` - 生成金鑰對
生成用於指令碼簽名的 Ed25519 金鑰對。

```bash
flux keygen
```

#### `flux sign` - 簽名指令碼
使用私鑰對 Flux 指令碼進行簽名。

```bash
flux sign <file.flux> --key <private.pem>
```

#### `flux verify` - 驗證簽名
驗證已簽名的 Flux 指令碼。

```bash
flux verify <file.flux> --key <public.pem>
```

---

## 專案模板

### 基礎模板 (Basic Template)
簡單的控制台應用程式：
```
my_app/
├── main.flux      # 進入點
├── flux.yaml      # 配置檔案
└── README.md
```

### Flutter 模板
帶有 FluxUI 元件的 Flutter UI 應用程式：
```
my_flutter_app/
├── main.flux      # 使用 FluxButton, FluxColumn 等的 UI
├── flux.yaml      # 類型：flutter
└── README.md
```

### 服務端模板 (Server Template)
服務端請求處理程式：
```
my_server/
├── main.flux      # HTTP 請求處理程式
├── flux.yaml      # 類型：server, 埠號：8080
└── README.md
```

---

## 配置檔案 (flux.yaml)

```yaml
name: my_project
version: 1.0.0
description: A Flux project

entry: main.flux
type: basic  # basic, flutter, 或 server

# 僅限伺服器選項
port: 8080
```

---

## 版本資訊

```bash
flux --version
# Flux CLI v2.0.0
```
