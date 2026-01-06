# Flux Language Server (LSP)

[![pub package](https://img.shields.io/pub/v/flux_lsp.svg)](https://pub.dev/packages/flux_lsp)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

> A Language Server Protocol implementation for the Flux scripting language.

This package provides the core intelligence for Flux editor support, including syntax validation, autocompletion, hover documentation, and symbol navigation.

## Features

- **Diagnostics**: Real-time error reporting (syntax errors, basic semantic checks).
- **Completion**: Smart suggestions for keywords, widgets, and standard library functions.
- **Hover**: Documentation and type signatures for symbols.
- **Go to Definition**: Jump to variable declarations, function definitions, and widget components.
- **Find References**: Locate all usages of a symbol within a file.

## Usage

The LSP is typically used via the [Flux VSCode Extension](../flux_vscode).

To run the server manually:
```bash
dart bin/main.dart
```

The server communicates via JSON-RPC over standard input/output.

## Architecture

- **`FluxAnalyzer`**: Interfaces with the `flux_compiler` to parse code and generate high-level analysis results.
- **`ScopeAnalyzer`**: Performs name resolution and scope tracking to support navigation and references.
- **`FluxLanguageServer`**: Implements the LSP protocol handlers and manages the JSON-RPC communication.

## Testing

Run unit tests for the analyzer and LSP logic:
```bash
dart test
```
