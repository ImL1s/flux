# Flux TODO

[漢文文檔](TODO_ZH.md)

This file tracks planned features and improvements. Each item should be implemented on a separate feature branch with a corresponding PR.

## ✅ Completed Features (v2.0.0)

### FluxUI Component Library
- [x] Core components (Button, Card, Input, Badge)
- [x] Layout components (Column, Row, Stack, Grid)
- [x] Design System support (Theme, Typography, Colors)

### CLI Enhancement
- [x] `flux create` - Project scaffolding
- [x] `flux run` - Enhanced execution with hot-reload
- [x] `flux analyze` - Static analysis integration

### BLE Integration
- [x] Real `flutter_blue_plus` integration
- [x] Connection state management
- [x] Permission handling (Android/iOS)
- [x] Unit tests with BLE mocks

### Camera Integration
- [x] Real `camera` package integration
- [x] Lifecycle management
- [x] Platform-specific configurations

### Infrastructure
- [x] DAP Debugger
- [x] LSP Intelligence
- [x] Compiler Optimizations
- [x] VM Inline Caching
- [x] CI/CD Pipeline
- [x] Pub.dev Publishing

---

## 🔵 Planned Features (v3.0)

### Feature: State Persistence ✅
- **Description**: Automatic state persistence and restoration
- **Status**: Completed in v2.0.1
- **Implemented**:
  - [x] `persistent` keyword in Flux language
  - [x] Hive CE integration for complex state
  - [x] PersistenceDelegate abstraction
  - [x] HivePersistenceDelegate implementation

### Feature: Network Layer
- **Description**: Built-in HTTP/WebSocket support in Flux scripts
- **Goals**:
  - [ ] HTTP client bindings (GET, POST, PUT, DELETE)
  - [ ] WebSocket real-time communication
  - [x] **Network Module Enhancement**
    - [x] Migrate to Dio client
    - [x] BaseUrl & Timeout configuration
    - [x] Response interceptors (Log, Error)
    - [x] Request cancellation support

### Feature: Animation System
- **Description**: Declarative animations in Flux scripts
- **Goals**:
  - [x] **Animation Module Enhancement**
    - [x] Spring physics simulation (`Animation.spring`)
    - [x] Staggered animations (`Animation.stagger`)
    - [x] Color & Size tweens
    - [x] Full curve synchronization
  - [ ] Hero transitions via script

### Feature: Multi-Platform Extensions
- **Description**: Platform-specific features
- **Goals**:
  - [ ] Web platform support
  - [ ] Desktop (Windows/macOS/Linux) support
  - [ ] Platform-specific bindings API

### Feature: Plugin System
- **Description**: Third-party plugin architecture
- **Goals**:
  - [ ] Plugin registry
  - [ ] Plugin lifecycle management
  - [ ] Plugin sandboxing
  - [ ] Community plugin marketplace

### Feature: Developer Experience
- **Description**: Enhanced DX tooling
- **Goals**:
  - [x] FluxDevTools browser extension
  - [x] Performance profiler (Memory leak detection)
  - [x] Visual widget inspector

---

## 📝 Notes

- Each feature branch should follow naming convention: `feature/<name>`
- All features require tests before merging
- Use web search for latest package versions and best practices
- PRs should target `dev` branch
