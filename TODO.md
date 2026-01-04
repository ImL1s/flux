# Flux TODO

This file tracks planned features and improvements. Each item should be implemented on a separate feature branch with a corresponding PR.

## 🔴 Pending Features (v2.0+)

### Feature: FluxUI (Component Library) - COMPLETED
- **Branch**: `feature/flux-ui`
- **Description**: Standard library of UI components for Flux
- **Goals**: 
  - [x] Implement core components (Button, Card, Input, Badge)
  - [x] Implement layout components (Column, Row, Stack, Grid)
  - [x] Design System support (Theme, Typography, Colors)

### Feature: CLI Enhancement (Phase 10) - COMPLETED
- **Branch**: `feature/cli-enhancement`
- **Description**: Enhance developer experience with improved CLI tools
- **Goals**:
  - [x] `flux create` - Project scaffolding
  - [x] `flux run` - Enhanced execution with hot-reload
  - [x] `flux analyze` - Static analysis integration

---

## ✅ Completed Features

### Feature: BLE Integration (v2.0)
- **Description**: Integrated real `flutter_blue_plus` for production BLE functionality
- **Tasks**:
  - [x] Research latest `flutter_blue_plus` best practices
  - [x] Update `ble_module.dart` to use real BLE scanning
  - [x] Implement proper permission handling (Android/iOS)
  - [x] Add connection state management
  - [x] Write integration tests with BLE mocks
  - [x] Write unit tests for BLE module
  - [x] Update documentation

### Feature: Camera Integration (v2.0)
- **Description**: Integrated real `camera` package for production camera functionality
- **Tasks**:
  - [x] Research latest `camera` package best practices
  - [x] Update `camera_module.dart` to use real `CameraController`
  - [x] Update `camera_preview.dart` with proper lifecycle management
  - [x] Add platform-specific configurations (Android/iOS permissions)
  - [x] Write integration tests with mock camera
  - [x] Write widget tests for `FluxCameraPreview`
  - [x] Update documentation

- [x] DAP Debugger (v2.2)
- [x] LSP Intelligence (v2.1)
- [x] Compiler Optimizations (v2.1)
- [x] VM Inline Caching (v2.1)
- [x] CI/CD Pipeline
- [x] Pub.dev Publishing

---

## 📝 Notes

- Each feature branch should follow naming convention: `feature/<name>`
- All features require tests before merging
- Use web search for latest package versions and best practices
- PRs should target `dev` branch
