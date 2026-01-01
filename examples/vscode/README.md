# Flux for VSCode

The **Flux VSCode Extension** provides a rich development experience for the Flux language.

## Features

- **Syntax Highlighting**: Colorization for keywords, types, strings, and comments.
- **IntelliSense**: Code completion for StdLib functions and user variables.
- **Go to Definition**: F12 to jump to function/variable declarations.
- **Find References**: Shift+F12 to see usages.
- **Hover Info**: Hover over symbols to see type info and documentation.
- **Diagnostics**: Real-time syntax error reporting.
- **Debugging**: Full support for breakpoints and stepping.

## Setup

1. Open the project root in VSCode.
2. If building from source, install the extension:
   ```bash
   cd packages/flux_vscode
   npm install
   code --install-extension flux-vscode-0.0.1.vsix
   ```
3. Open any `.flux` file to activate the extension.

## Extensions

The extension communicates with the **Flux Language Server** (`flux_lsp`) to provide analysis features. Ensure you have the `flux_lsp` package available.
