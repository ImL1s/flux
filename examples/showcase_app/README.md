# Flux Showcase App

[漢文文檔](README_ZH.md)

This is a full-featured example application demonstrating the power of Flux scripts in real-world scenarios.

## 📱 Included Pages

| Page | Description | Technologies Demonstrated | Script Path |
|------|------|----------|----------|
| **🛒 E-commerce** | Product details and interaction | Image carousel, State management, Toast notifications | `scripts/product_page.flux` |
| **✅ Todo List** | Simple CRUD | List operations, conditional rendering | `scripts/todo_page.flux` |
| **⚙️ Settings** | System preferences | Switches, sliders, native storage access | `scripts/settings_page.flux` |
| **📊 Dashboard** | Async data display | **Async/Await**, **Dio API requests** | `scripts/dashboard_page.flux` |

## 🚀 How to Run

### 1. Start Backend Server (Provides API & Scripts)

```bash
cd examples/showcase_app/server
dart pub get
dart server.dart
```
> Server runs at `http://localhost:8082`

### 2. Launch App

```bash
cd examples/showcase_app/flutter_app
flutter pub get
flutter run -d windows
```

## 🔥 Try Hot Update

1. Keep the App running on the "Dashboard" page.
2. Open `scripts/dashboard_page.flux`.
3. Modify the title text, for example, change "Operations Overview" to "Real-time War Room".
4. Save the file and click the refresh button in the top right corner of the App.
5. **Witness the UI update instantly!**

## 🏗️ System Architecture

- **Flutter (Dart)**: Handles the App skeleton, navigation (`BottomNavigationBar`), and native features (Dio, Storage).
- **Flux**: Responsible for all page UI layouts and business logic.
- **Riverpod**: Acts as a state mediator. While this example primarily uses Flux's internal State, the architecture supports two-way binding.
