# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-02

### Added
- **Core VM**: Stack-based bytecode virtual machine
- **Compiler**: Lexer, Parser, AST, Bytecode compiler
- **Language Features**:
  - Variables, functions, closures
  - Classes with fields and methods
  - Exception handling (try/catch/finally)
  - Async/await
  - Import system
- **Standard Library**:
  - Core: print, len, type, toString
  - Math: abs, min, max, floor, ceil, sqrt, pow, random
  - String: upper, lower, trim, split, contains, replace, substring
  - List: push, pop, insert, remove, indexOf, sort, reverse, join
  - JSON: parse, stringify
  - HTTP: get, post
  - Storage: get, set
  - Timer: delay
  - Crypto: sha256, randomBytes
  - Base64: encode, decode
  - Regex: test, match, matchAll, replace
  - Date: now, format, parse, year, month, day
- **Debugger**:
  - Breakpoints (set, remove, clear)
  - Stepping (into, over, out)
  - State inspection
  - Expression evaluation
- **Developer Tools**:
  - Hot-reload support
  - DevTools integration
  - Source maps (V3 format)
  - LSP (definitions, references)
- **Security**:
  - Ed25519 script signing
  - Signature verification
- **CLI** (`flux`):
  - `keygen` - Generate key pair
  - `sign` - Sign script
  - `verify` - Verify signature
  - `build` - Compile to .flx binary
- **Flutter Integration**:
  - FluxWidget for embedding scripts
  - Widget state management
  - Device and Dialog modules
- **VSCode Extension**:
  - Syntax highlighting
  - Go to definition
  - Find references

### Performance
- Bytecode optimizer with constant folding
- Peephole optimization
- Dead code elimination
