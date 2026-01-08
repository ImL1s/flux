# Flux Updater

[漢文文檔](README_ZH.md)

[![pub package](https://img.shields.io/pub/v/flux_updater.svg)](https://pub.dev/packages/flux_updater)
[![Dart](https://img.shields.io/badge/Dart-3.6+-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Over-the-Air (OTA) update system for Flux applications. Enables efficient bytecode diff transmission, version control, and seamless updates for both development and production environments.

Part of the [Flux](https://github.com/ImL1s/flux) ecosystem - a dynamic scripting language for Flutter Server-Driven UI.

## Features

- **Bytecode Diffing** - XOR + GZip compression achieving ~5-10% patch sizes
- **Version Control** - Semantic versioning with rollback support
- **Code Signing** - HMAC-SHA256 signature verification
- **OTA Server** - Shelf-based REST API for release management
- **CLI Tools** - Compile, release, and push commands
- **Flutter Integration** - Seamless integration with Flutter apps

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flux_updater: ^1.0.0
```

Or install via command line:

```bash
dart pub add flux_updater
```

## Quick Start

### 1. Start the OTA Server

```bash
dart run packages/flux_updater/bin/ota_server.dart 8080
```

### 2. Compile and Release

```bash
# Compile Flux source to bytecode
dart run bin/flux_updater.dart compile app.flux -o app.fluxc

# Create signed release
dart run bin/flux_updater.dart release \
  --app-id com.example.myapp \
  --version 1.0.0 \
  --build 1 \
  app.fluxc

# Upload to OTA server
dart run bin/flux_updater.dart push --server http://localhost:8080 app.fluxc
```

### 3. Integrate in Flutter

```dart
import 'package:flux_updater/flux_updater.dart';

final updateManager = FluxUpdateManager(
  appId: 'com.example.myapp',
  serverUrl: 'https://ota.example.com',
  signingKey: 'your-signing-key',
  currentBuildNumber: 1,
  onChunkReady: (chunk) {
    // Apply via FluxRuntime.hotReload(chunk)
    runtime.hotReload(chunk);
  },
);

// Check for updates
final status = await updateManager.checkForUpdates();
if (status == UpdateStatus.updateAvailable) {
  await updateManager.downloadAndApply();
}
```

## API Reference

### FluxUpdateManager

| Method | Description |
|--------|-------------|
| `checkForUpdates()` | Check if update is available |
| `downloadAndApply()` | Download and apply latest update |
| `rollback(version)` | Rollback to specific version |
| `progressStream` | Stream of update progress |

### OTA Server Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/releases` | Upload new release |
| GET | `/releases/:appId/latest` | Get latest version |
| GET | `/patches/:appId/:from/:to` | Download patch |
| GET | `/chunks/:appId/:version` | Download full chunk |

### CLI Commands

```bash
flux_updater compile <source.flux> -o <output.fluxc>
flux_updater release --app-id <id> --version <ver> --build <num> <file>
flux_updater push --server <url> <file.fluxc>
flux_updater info <file.fluxc>
```

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Developer │────▶│  OTA Server │◀────│  Flutter App│
└─────────────┘     └─────────────┘     └─────────────┘
      │                    │                    │
      ▼                    ▼                    ▼
  ┌───────┐          ┌───────────┐        ┌─────────┐
  │ CLI   │          │ Releases  │        │ Update  │
  │ Tools │          │ Patches   │        │ Manager │
  └───────┘          └───────────┘        └─────────┘
```

## App Store Compliance

### iOS

Flux OTA updates comply with Apple App Store guidelines because:

1. **Interpreted Code Exception**: Flux uses a bytecode interpreter, not native code execution
2. **No Feature Changes**: Updates only modify UI/logic within the app's original scope
3. **Bundled Interpreter**: The Flux VM is bundled with the app, not downloaded

See [App Store Guidelines §3.3.2](https://developer.apple.com/app-store/review/guidelines/#software-requirements) for details.

### Android

Google Play allows OTA updates for interpreted scripts and bytecode. Ensure:

1. Updates don't change app functionality beyond original scope
2. User data privacy is maintained
3. All updates are signed and verified

## Testing

```bash
# Run all tests
dart test

# Run E2E tests only
dart test test/ota_e2e_test.dart
```

## License

MIT License - see [LICENSE](LICENSE) for details.
