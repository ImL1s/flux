# Flux 更新器 (Flux Updater)

[English Documentation](README.md)

[![pub package](https://img.shields.io/pub/v/flux_updater.svg)](https://pub.dev/packages/flux_updater)
[![Dart](https://img.shields.io/badge/Dart-3.6+-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Flux 應用程式的無線 (Over-the-Air, OTA) 更新系統。支援高效的字節碼差異傳輸、版本控制，以及在開發和生產環境中的無縫更新。

此套件是 [Flux](https://github.com/ImL1s/flux) 生態系統的一部分 —— 一種用於 Flutter 服務端驅動 UI (Server-Driven UI) 的動態指令碼語言。

## 特性

- **字節碼差異更新 (Bytecode Diffing)**：採用 XOR + GZip 壓縮，補丁大小僅為原始大小的 ~5-10%
- **版本控制**：帶有回滾支援的語意化版本管理 (Semantic Versioning)
- **程式碼簽名**：HMAC-SHA256 簽名驗證
- **OTA 伺服器**：基於 Shelf 的 REST API，用於發布版本管理
- **CLI 工具**：編譯、發布和推送命令
- **Flutter 整合**：與 Flutter 應用程式無縫整合

## 安裝

在您的 `pubspec.yaml` 中添加以下內容：

```yaml
dependencies:
  flux_updater: ^1.0.0
```

或者透過命令行安裝：

```bash
dart pub add flux_updater
```

## 快速入門

### 1. 啟動 OTA 伺服器

```bash
dart run packages/flux_updater/bin/ota_server.dart 8080
```

### 2. 編譯與發布

```bash
# 將 Flux 源碼編譯為字節碼
dart run bin/flux_updater.dart compile app.flux -o app.fluxc

# 建立已簽名的發布版本
dart run bin/flux_updater.dart release \
  --app-id com.example.myapp \
  --version 1.0.0 \
  --build 1 \
  app.fluxc

# 上傳至 OTA 伺服器
dart run bin/flux_updater.dart push --server http://localhost:8080 app.fluxc
```

### 3. 在 Flutter 中整合

```dart
import 'package:flux_updater/flux_updater.dart';

final updateManager = FluxUpdateManager(
  appId: 'com.example.myapp',
  serverUrl: 'https://ota.example.com',
  signingKey: 'your-signing-key',
  currentBuildNumber: 1,
  onChunkReady: (chunk) {
    // 透過 FluxRuntime.hotReload(chunk) 應用更新
    runtime.hotReload(chunk);
  },
);

// 檢查更新
final status = await updateManager.checkForUpdates();
if (status == UpdateStatus.updateAvailable) {
  await updateManager.downloadAndApply();
}
```

## API 參考

### FluxUpdateManager

| 方法 | 說明 |
|--------|-------------|
| `checkForUpdates()` | 檢查是否有可用更新 |
| `downloadAndApply()` | 下載並應用最新更新 |
| `rollback(version)` | 回滾到特定版本 |
| `progressStream` | 更新進度的串流 (Stream) |

### OTA 伺服器端點 (Endpoints)

| 方法 | 端點 | 說明 |
|--------|----------|-------------|
| POST | `/releases` | 上傳新版本 |
| GET | `/releases/:appId/latest` | 獲取最新版本資訊 |
| GET | `/patches/:appId/:from/:to` | 下載補丁 (Patch) |
| GET | `/chunks/:appId/:version` | 下載完整字節碼塊 |

### CLI 命令

```bash
flux_updater compile <source.flux> -o <output.fluxc>
flux_updater release --app-id <id> --version <ver> --build <num> <file>
flux_updater push --server <url> <file.fluxc>
flux_updater info <file.fluxc>
```

## 架構設計

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   開發者    │────▶│  OTA 伺服器 │◀────│  Flutter App│
└─────────────┘     └─────────────┘     └─────────────┘
      │                    │                    │
      ▼                    ▼                    ▼
  ┌───────┐          ┌───────────┐        ┌─────────┐
  │ CLI   │          │ 發布/補丁 │        │ 更新    │
  │ 工具  │          │ (Releases)│        │ 管理器  │
  └───────┘          └───────────┘        └─────────┘
```

## App Store 合規性

### iOS

Flux OTA 更新符合 Apple App Store 的指南要求，原因如下：

1. **解釋型程式碼例外**：Flux 使用字節碼解釋器，而非直接執行原生程式碼。
2. **無功能變更**：更新僅限於應用程式原定範圍內的 UI 和邏輯修改。
3. **內置解釋器**：Flux VM 是隨應用程式打包發布的，而非下載安裝。

詳情請參閱 [App Store Guidelines §3.3.2](https://developer.apple.com/app-store/review/guidelines/#software-requirements)。

### Android

Google Play 允許對解釋型指令碼和字節碼進行 OTA 更新。請確保：

1. 更新不會超出應用程式原定的功能範圍。
2. 維護用戶資料私隱。
3. 所有更新均經過簽名與驗證。

## 測試

```bash
# 執行所有測試
dart test

# 僅執行端到端 (E2E) 測試
dart test test/ota_e2e_test.dart
```

## 授權協議

MIT 授權 —— 詳情請參閱 [LICENSE](LICENSE) 檔案。
