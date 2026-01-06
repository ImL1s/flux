# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flux is a lightweight, stack-based scripting language designed for Flutter Server-Driven UI. It enables hot-pushable UI logic without app store submissions.

**Architecture**: Monorepo with 9 Dart/Flutter packages following this compilation pipeline:
```
.flux source → Lexer → Parser → AST → Compiler → Bytecode → VM → Flutter Widgets
```

## Build & Development Commands

### Dependencies
```bash
# Dart packages
dart pub get -C packages/flux_compiler
dart pub get -C packages/flux_vm
dart pub get -C packages/flux_cli
dart pub get -C packages/flux_lsp
dart pub get -C packages/flux_dap
dart pub get -C packages/flux_updater

# Flutter packages
flutter pub get -C packages/flux_flutter
flutter pub get -C packages/flux_devtools_extension
```

### Testing
```bash
# Run tests for a specific package
dart test packages/flux_compiler
dart test packages/flux_vm
dart test packages/flux_cli
dart test packages/flux_lsp
dart test packages/flux_dap
dart test packages/flux_updater

# Flutter packages use flutter test
flutter test packages/flux_flutter

# Run a single test file
dart test packages/flux_compiler/test/compiler_test.dart

# Verbose output
dart test packages/flux_compiler --reporter=expanded
```

### Static Analysis
```bash
# Dart packages
dart analyze --fatal-infos packages/flux_compiler
dart analyze --fatal-infos packages/flux_vm
dart analyze --fatal-infos packages/flux_lsp
dart analyze --fatal-infos packages/flux_dap
dart analyze --fatal-infos packages/flux_cli
dart analyze --fatal-infos packages/flux_updater

# Flutter packages
flutter analyze --fatal-infos packages/flux_flutter
flutter analyze --fatal-infos packages/flux_devtools_extension
```

### VSCode Extension
```bash
cd packages/flux_vscode
npm install
npm run build      # Compile TypeScript
npm run esbuild    # Bundle for distribution
vsce package       # Create VSIX
```

## Package Architecture

| Package | Purpose | pub.dev |
|---------|---------|---------|
| `flux_compiler` | Lexer, Parser, AST, Bytecode generation | [pub.dev/packages/flux_compiler](https://pub.dev/packages/flux_compiler) |
| `flux_vm` | Stack-based virtual machine, coroutines, stdlib | [pub.dev/packages/flux_vm](https://pub.dev/packages/flux_vm) |
| `flux_flutter` | Widget bindings, Riverpod integration, hot reload | [pub.dev/packages/flux_flutter](https://pub.dev/packages/flux_flutter) |
| `flux_lang_cli` | CLI tool, REPL, development server | [pub.dev/packages/flux_lang_cli](https://pub.dev/packages/flux_lang_cli) |
| `flux_lsp` | Language Server Protocol implementation | [pub.dev/packages/flux_lsp](https://pub.dev/packages/flux_lsp) |
| `flux_dap` | Debug Adapter Protocol implementation | - |
| `flux_vscode` | VSCode extension (TypeScript) | - |
| `flux_devtools_extension` | Flutter DevTools extension | - |
| `flux_updater` | OTA updates, bytecode diff, versioning | [pub.dev/packages/flux_updater](https://pub.dev/packages/flux_updater) |

## Key Entry Points

- **Compiler**: `packages/flux_compiler/lib/flux_compiler.dart`
- **VM**: `packages/flux_vm/lib/flux_vm.dart`
- **Flutter Integration**: `packages/flux_flutter/lib/flux_flutter.dart`
- **CLI**: `packages/flux_cli/bin/flux.dart`
- **LSP Server**: `packages/flux_lsp/bin/flux_lsp.dart`
- **DAP Server**: `packages/flux_dap/bin/flux_dap.dart`

## Core Source Files

**Compiler** (`packages/flux_compiler/lib/src/`):
- `lexer.dart` - Tokenization
- `parser.dart` - AST generation
- `compiler.dart` - Bytecode generation
- `optimizer.dart` - Peephole optimizations
- `serializer.dart`/`deserializer.dart` - Bytecode serialization

**VM** (`packages/flux_vm/lib/src/`):
- `vm.dart` - Stack-based execution engine
- `coroutine.dart` - Async/await support
- `stdlib.dart` - Built-in functions
- `debugger.dart` - Debug interface

**Flutter** (`packages/flux_flutter/lib/src/`):
- `flux_widget.dart` - Main FluxWidget component
- `bindings.dart` - Flutter widget bindings
- `riverpod_integration.dart` - State management adapter
- `hot_reload.dart` - WebSocket hot-reload client

## Environment Requirements

- Dart SDK: ^3.6.0
- Flutter SDK: ^3.27.0 (CI uses 3.38.5)
- Node.js: Required for VSCode extension

## Documentation

Detailed documentation lives in `/docs`:
- `ARCHITECTURE.md` - System design and data flow
- `LANGUAGE_GUIDE.md` - Syntax, control flow, widgets
- `language_reference.md` - Complete language reference
- `stdlib_reference.md` - Standard library functions
- `WIDGET_CATALOG.md` - Available Flutter widgets
- `flutter_integration.md` - Flutter app integration
- `security.md` - Signing, sandboxing, verification
- `lua_migration.md` - Lua to Flux migration guide
- `COMPARISON.md` - Flux vs Lua technical comparison
