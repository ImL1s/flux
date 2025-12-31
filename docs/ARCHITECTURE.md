# Flux Architecture

Flux is a multi-component system designed to enable Server-Driven UI for Flutter with a reactive scripting capability.

## Repository Structure

The monorepo consists of several packages:

- `packages/flux_compiler`: The front-end of the Flux language.
  - **Lexer**: Tokenizes source code.
  - **Parser**: Generates specific AST nodes.
  - **Compiler**: Emits bytecode chunks and constants.
  
- `packages/flux_vm`: The runtime environment.
  - **VM**: Stack-based virtual machine executing bytecode.
  - **Memory**: Manages stack, globals, and upvalues.
  - **FluxClosure / FluxInstance**: Runtime object representations.
  - **Debugger**: Hooks for breakpoints and profiling.

- `packages/flux_flutter`: The Flutter integration layer.
  - **FluxWidget**: The bridge between Flutter's Widget tree and Flux VM.
  - **Bindings**: Maps core Flutter widgets (Text, Column, etc.) to Flux native functions.
  - **HotReload**: WebSocket client for instant code updates.

- `packages/flux_vscode`: VSCode extension.
  - syntax highlighting (`.tmLanguage.json`).
  - snippets.

## Compilation Flow

1. Source Code (`.fx`) -> **Compiler** -> `FluxCompileResult` (Bytecode + Symbol Table).
2. `FluxCompileResult` -> **VM** -> Execution.
3. `VM` calls `FluxWidget.build` -> Generates Flutter Widget Tree.

## State Management

Flux uses a `setState` mechanism similar to Flutter.
1. `FluxWidget` creates a `VM` instance.
2. `VM` executes `build` block.
3. When `state` variable changes inside Flux, `onStateChange` callback is triggered.
4. `FluxWidget` calls `setState()`, rebuilding the Flutter subtree.

## Security (Production)

- **Signing**: Scripts are signed with ED25519.
- **Sandboxing**: Execution time, memory, and call depth are limited via `FluxSandboxConfig`.
- **Versioning**: `FluxVersionManager` handles rollback and caching.
