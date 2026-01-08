# Flux DAP

[漢文文檔](README_ZH.md)

Debug Adapter Protocol implementation for the Flux programming language.

Enables debugging of Flux scripts in VS Code, including breakpoints, stepping, and variable inspection.

## Architecture

This package implements the DAP server which communicates with the VS Code extension via stdin/stdout.

## Usage

This package is primarily used by the Flux VS Code extension.

To run the DAP server manually:

```dart
dart run flux_dap
```
