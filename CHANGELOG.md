# Changelog

All notable changes to this project will be documented in this file.

## [2.0.1] - 2026-01-07

### Added
- **State Persistence**: `persistent` keyword for automatic state persistence via Hive CE
- **PersistenceDelegate**: Abstract interface for custom persistence backends
- **HivePersistenceDelegate**: Default implementation using Hive CE

### Fixed
- CI/CD pipeline dependency conflicts (`flux_updater` path dependencies)
- Static analysis warnings (`flux_vm` unnecessary type checks)
- Missing explicit dependency (`flux_flutter` Hive CE import)

## [2.0.0] - 2026-01-04

### Added
- **FluxUI Component Library**: Complete set of UI components (Button, Card, Input, Badge, Row, Column, Grid, Stack)
- **BLE Integration**: Full Bluetooth Low Energy support via `flutter_blue_plus`
- **Camera Integration**: Real camera functionality via `camera` package
- **Design System**: Theme, Typography, and Colors support
- **CLI Enhancement**: `flux create`, `flux run`, `flux analyze` commands

### Changed
- Upgraded all packages to stable v2.0.0 release
- Improved documentation and API references
- Enhanced CI/CD pipeline

### Fixed
- Camera bindings restoration
- Duplicate `_initFormWidgets()` call
- Test import issues

## [1.0.0] - 2025-12-01

### Added
- Initial stable release
- Flux compiler with lexer, parser, and bytecode generation
- Flux VM with debugger support
- LSP server for IDE integration
- DAP debugger for VS Code
- Flutter bindings for UI development
