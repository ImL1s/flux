# 🔥 Flux Hot Update Demo

[漢文文檔](README_ZH.md)

This example demonstrates Flux's core capability: instantly updating UI and business logic by modifying external scripts without recompiling the App.

## 📁 Directory Structure

- `scripts/` - Stores Flux scripts (`.flux`).
- `server/` - A simple Dart HTTP server simulating a remote update server.
- `flutter_app/` - The Flutter application that loads and executes scripts.

## 🚀 Quick Start

> 📋 **Prerequisites**: Ensure you have [Flutter SDK](https://flutter.dev/docs/get-started/install) and [Dart SDK](https://dart.dev/get-dart) installed.

### 1. Start Hot Update Server (Optional)

If you want to test true "remote" updates, start the server first:

```bash
cd examples/hot_update_demo/server
dart pub get
dart server.dart
```
The server will run at `http://localhost:8081`.

### 2. Launch Flutter App

```bash
cd examples/hot_update_demo/flutter_app
flutter pub get
flutter run -d windows  # or -d chrome, -d macos, etc.
```

### 3. Test the Update

1. Toggle between **"Local File"** or **"Remote Server"** mode at the top of the App.
2. Open and modify `examples/hot_update_demo/scripts/home_banner.flux`.
3. Save the file.
4. Click the **Refresh button (🔄)** in the top right corner of the App.

## 💡 Technical Highlights

- **Dual-Mode Support**: Supports loading scripts from both the local file system and remote HTTP URLs.
- **Bytecode Execution**: Scripts are compiled to Bytecode immediately upon loading and executed by a dedicated VM.
- **Auto Path Discovery**: Built-in smart path searching to locate the `scripts` folder automatically.
- **Full Scripting Language**: Handles State and functional logic in addition to UI.

---

For more information, please refer to the [GitHub Repo](https://github.com/ImL1s/flux)
