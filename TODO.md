# Flux TODO

This file tracks planned features and improvements. Each item should be implemented on a separate feature branch with a corresponding PR.

## 🔴 Pending Features (v2.0+)

### Feature: Camera Integration
- **Branch**: `feature/camera-integration`
- **Description**: Integrate real `camera` package for production camera functionality
- **Dependencies**: `camera: ^0.11.0` (or latest)
- **Tasks**:
  - [ ] Research latest `camera` package best practices
  - [ ] Update `camera_module.dart` to use real `CameraController`
  - [ ] Update `camera_preview.dart` with proper lifecycle management
  - [ ] Add platform-specific configurations (Android/iOS permissions)
  - [ ] Write integration tests with mock camera
  - [ ] Write widget tests for `FluxCameraPreview`
  - [ ] Update documentation

### Feature: BLE Integration
- **Branch**: `feature/ble-integration`
- **Description**: Integrate real `flutter_blue_plus` for production BLE functionality
- **Dependencies**: `flutter_blue_plus: ^1.34.0` (or latest)
- **Tasks**:
  - [ ] Research latest `flutter_blue_plus` best practices
  - [ ] Update `ble_module.dart` to use real BLE scanning
  - [ ] Implement proper permission handling (Android/iOS)
  - [ ] Add connection state management
  - [ ] Write integration tests with BLE mocks
  - [ ] Write unit tests for BLE module
  - [ ] Update documentation

---

## ✅ Completed Features

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
