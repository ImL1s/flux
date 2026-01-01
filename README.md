# Flux ⚡

> **A Dynamic Scripting Language for Flutter Server-Driven UI**

Flux is a lightweight, stack-based scripting language designed specifically to enable **dynamic updates** and **server-driven UI** logic within Flutter applications. It decouples business logic and UI layout from the app binary, allowing for instant updates without App Store submission.

---

## 🏗️ Architecture (The "HERO" Flow)

This diagram illustrates how Flux transforms raw script code into a reactive native Flutter UI interactively managed by Riverpod.

```mermaid
graph TD
    %% Styling
    classDef source fill:#e1f5fe,stroke:#01579b,stroke-width:2px;
    classDef core fill:#fff3e0,stroke:#ff6f00,stroke-width:2px;
    classDef flutter fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px;
    classDef state fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px;

    Input([📄 .flux Source Code]):::source -->|Parse & Compile| Compiler[⚙️ Flux Compiler]:::core
    
    Compiler -->|Bytecode| VM[🖥️ Flux VM]:::core
    
    subgraph "Flutter Runtime Environment"
        VM -->|Execute| ScriptLogic[🧠 Script Logic]:::core
        
        ScriptLogic -->|Call| Bindings[🔗 Flux Bindings]:::flutter
        Bindings -->|Build| UI[📱 Flutter Widgets]:::flutter
        
        ScriptLogic <-->|Read/Write| RP[🌊 Riverpod Providers]:::state
        RP -->|Notify| UI
    end

    UI -->|User Interaction| ScriptLogic
```

1.  **Compiler**: Translates human-readable `.flux` code into efficient bytecode instructions.
2.  **VM**: A stack-based virtual machine that executes the bytecode safely within the host app.
3.  **Bindings**: Bridges the gap between the dynamic VM and static Flutter widgets (Text, Column, etc.).
4.  **Riverpod**: Acts as the synchronized state layer, allowing Flux scripts to read/write native Flutter state seamlessly.

---

## 📦 Packages Overview

The project is organized as a monorepo containing the following core packages:

| Package | Description |
|---------|-------------|
| **[`flux_compiler`](packages/flux_compiler)** | Lexer, Parser, and Code Generator. Converts source to bytecode. |
| **[`flux_vm`](packages/flux_vm)** | The runtime engine. A stack machine that executes Flux bytecode. |
| **[`flux_flutter`](packages/flux_flutter)** | Flutter integration layer. Contains widget bindings and the Riverpod runtime adapter. |
| **[`flux_cli`](packages/flux_cli)** | Command-line tool for running `.flux` scripts directly in the terminal. |
| **[`flux_lsp`](packages/flux_lsp)** | Language Server Protocol (LSP) implementation for editor intelligence. |
| **[`flux_vscode`](packages/flux_vscode)** | VSCode Extension providing syntax highlighting, snippets, and LSP integration. |

---

## 🚀 Getting Started

### 1. Installation

Flux is currently in active development. To use it, add the packages locally to your `pubspec.yaml`:

```yaml
dependencies:
  flux_flutter:
    path: ../packages/flux_flutter
  flutter_riverpod: ^2.6.1
```

### 2. Writing a Flux Script

Create a file named `counter.flux`:

```javascript
// Define a widget component
widget Counter {
  build() {
    return Column(children: () => [
      Text("Count: " + getProvider("counter")),
      Button(
        text: "Increment",
        onPressed: () => {
          var current = getProvider("counter");
          setProvider("counter", current + 1);
        }
      )
    ]);
  }
}
```

### 3. Integrating in Flutter

```dart
// 1. Define your State
final counterProvider = NotifierProvider<FluxValueNotifier<int>, int>(
  () => FluxValueNotifier(0),
);

// 2. Use the FluxRiverpodWidget
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: FluxRiverpodWidget(
        source: fluxSourceCode, // Load your .flux file string here
        widgetName: 'Counter',  // The widget class implementation to use
        notifierProviders: {
          'counter': counterProvider, // Bind native providers to Flux
        },
      ),
    );
  }
}
```

---

## 🌟 Key Features

*   **Hot-Pushable Logic**: Update UI structure and business rules by simply downloading a new string.
*   **Sandboxed Execution**: Scripts run in a controlled VM environment, preventing crashes in the host app.
*   **Native Performance**: Uses lightweight bytecode interpretation, keeping the UI smooth (60fps).
*   **State Management**: First-class support for **Riverpod** 3.x/2.x via the Notifier API.

---

# Tooling & IDE Support

### VSCode Extension
The **Flux VSCode Extension** provides a premium development experience:
- **Intelligent Navigation**: Go to Definition and Find All References.
- **Code Intelligence**: Autocompletion for widgets, keywords, and providers.
- **Diagnostics**: Real-time error reporting as you type.
- **Snippets**: Rapidly scaffold widgets and logic blocks.

To install, see the [VSCode Extension README](packages/flux_vscode/README.md).

---

## 🛠️ Development

### Running Tests

To ensure the integrity of the ecosystem, run the test suite across all packages:

```bash
# Core Logic Tests
dart test packages/flux_compiler
dart test packages/flux_vm
dart test packages/flux_cli
dart test packages/flux_lsp

# Integration Tests
flutter test packages/flux_flutter
```
