# Flux VSCode Extension

> Syntax highlighting, snippets, and language support for [Flux](https://github.com/ImL1s/flux) - A dynamic scripting language for Flutter Server-Driven UI.

## Features

### Intelligence (LSP)
- **Go to Definition**: Jump to variable, function, and widget declarations.
- **Find All References**: Track symbol usage across the file.
- **Autocompletion**: Context-aware completions for keywords, widgets, and stdlib.
- **Hover Information**: Detailed documentation and signatures on hover.
- **Diagnostics**: Real-time syntax and semantic error reporting.

### Syntax Highlighting
- **Keywords**: `if`, `else`, `while`, `for`, `return`, `break`, `continue`
- **Async/Await**: `async`, `await`
- **Exception Handling**: `try`, `catch`, `finally`, `throw`
- **Declarations**: `widget`, `fn`, `var`, `class`
- **Modifiers**: `state`, `props`, `build`
- **Widgets**: PascalCase identifiers (e.g., `Column`, `Button`, `Scaffold`)
- **Strings**: Double and single quoted
- **Numbers**: Integer, float, hex colors
- **Comments**: Single-line (`//`) and block (`/* */`)

### Snippets

| Prefix | Description |
|--------|-------------|
| `widget` | Create a stateful widget |
| `swidget` | Create a stateless widget with props |
| `fn` | Function declaration |
| `afn` | Async function declaration |
| `if` / `ife` | If / If-else statement |
| `while` / `for` | Loop statements |
| `try` / `tryf` | Try-catch / Try-catch-finally |
| `btn` | Button with onPressed |
| `tf` | TextField with onChanged |
| `scaffold` | Scaffold with AppBar |
| `httpget` | HTTP GET request with await |
| `state` / `props` | State/Props declaration |
| `col` / `row` | Column/Row widget |
| `listtile` | ListTile with onTap |

## Installation

### From VSIX (Local)
```bash
cd packages/flux_vscode
npm install -g vsce
vsce package
code --install-extension flux-vscode-0.1.0.vsix
```

### From Marketplace (Coming Soon)
Search for "Flux" in VSCode Extensions.

## Requirements

- VSCode 1.75.0 or higher

## Extension Settings

This extension has no configuration settings yet.

## Known Issues

- Multi-file symbol resolution (WIP)
- No debugging support yet

## Release Notes

### 0.2.0
- Integrated Flux Language Server (LSP)
- Support for Go to Definition & Find All References
- Context-aware code completion
- Real-time error diagnostics and hover information

### 0.1.0
- Initial release
- Syntax highlighting for all Flux keywords
- 22 snippets for common patterns
- Language configuration (brackets, comments)

## Contributing

Contributions are welcome! Please visit [GitHub](https://github.com/ImL1s/flux) to report issues or submit pull requests.

## License

MIT
