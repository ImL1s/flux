# Flux ⚡

## Project Overview

**Flux** is a dynamic, stack-based scripting language designed specifically for **Flutter Server-Driven UI**. It enables dynamic updates of both UI layout and business logic without requiring App Store resubmission.

### Key Capabilities
- **Dynamic Updates:** Decouples logic and UI from the app binary.
- **Server-Driven UI:** Render Flutter widgets (Text, Column, Button, etc.) defined in remote `.flux` scripts.
- **Reactive State:** Deep integration with **Riverpod** for state management.
- **Sandboxed Execution:** Runs in a controlled VM to prevent host app crashes.
- **Developer Experience:** Includes a custom CLI, LSP, and VSCode extension.

## Architecture & Structure

The project is a **monorepo** managed with Git, containing the following core packages in the `packages/` directory:

| Package | Path | Description |
| :--- | :--- | :--- |
| **flux_compiler** | `packages/flux_compiler` | Front-end (Lexer, Parser) and Code Generator. Compiles `.flux` source to bytecode. |
| **flux_vm** | `packages/flux_vm` | Stack-based Virtual Machine that executes Flux bytecode. |
| **flux_flutter** | `packages/flux_flutter` | Flutter bindings. Bridges the VM to Flutter widgets and Riverpod. |
| **flux_cli** | `packages/flux_cli` | Command-line interface for creating, running, and analyzing Flux projects. |
| **flux_lsp** | `packages/flux_lsp` | Language Server Protocol implementation for editor intelligence. |
| **flux_vscode** | `packages/flux_vscode` | VSCode Extension for syntax highlighting, snippets, and LSP integration. |
| **flux_devtools_extension** | `packages/flux_devtools_extension` | Custom DevTools extension for debugging Flux apps. |

### "HERO" Flow
1.  **Input:** `.flux` source code.
2.  **Compile:** `flux_compiler` transforms source into bytecode instructions.
3.  **Execute:** `flux_vm` runs the bytecode.
4.  **Bind:** `flux_flutter` maps VM instructions to native Flutter widgets.
5.  **Render:** Flutter renders the UI, with state managed by Riverpod.

## Building and Running

### Prerequisites
- **Flutter SDK:** Ensure `flutter` is in your PATH (or use the `.fvm` version if configured).
- **Dart SDK:** Required for running Dart-only packages.

### Common Commands

**Running Tests:**
To verify the entire ecosystem, you can run the provided PowerShell script or test packages individually.

```powershell
# Run full test suite (Windows)
./tools/full_test.ps1
```

**Individual Package Tests:**
```bash
# Core Logic (Compiler, VM, CLI, LSP)
dart test packages/flux_compiler
dart test packages/flux_vm
dart test packages/flux_cli
dart test packages/flux_lsp

# Integration Tests (Flutter bindings)
flutter test packages/flux_flutter
```

**CLI Usage:**
The CLI tool `flux` helps manage projects.
```bash
# Activate globally (from source)
dart pub global activate --source path packages/flux_cli

# Create a new project
flux create my_app --template flutter

# Run a script with hot-reload
flux run main.flux --watch
```

## Development Conventions

*   **Language:** The core is written in **Dart**.
*   **File Extension:** Flux scripts use the `.flux` extension.
*   **State Management:** The project relies heavily on **Riverpod** (v2/v3) for state synchronization between the Flux VM and the Flutter host.
*   **Testing:** Each package has its own `test/` directory. Integration tests are primarily in `flux_flutter`.
*   **Documentation:**
    *   `docs/` contains high-level guides (Language Guide, Architecture, Spec).
    *   `examples/` contains usage examples and demos (`flutter_demo`, `hot_update_demo`).

## Key Files & Directories

*   `README.md`: Main project entry point.
*   `docs/`: Comprehensive documentation.
*   `packages/`: Source code for all modules.
*   `examples/`: Sample applications and scripts.
*   `tools/`: Utility scripts for maintenance and testing.
