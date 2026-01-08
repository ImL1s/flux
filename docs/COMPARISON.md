# Flux vs Lua Hot Updates: Technical Comparison

[漢文文檔](COMPARISON_ZH.md)

Flux draws inspiration from the mature Lua hot update pattern used in the game industry and optimizes it specifically for the Flutter ecosystem.

## Core Concept Comparison

| Feature | Lua Hot Update | Flux Hot Update |
|------|----------|------------|
| **Scripted Logic** | Game logic written in `.lua` scripts | UI and logic written in `.flux` scripts |
| **Embedded VM** | App embeds Lua VM to run scripts | App embeds Flux VM to run Bytecode |
| **Dynamic Loading** | Download new scripts from server and reload | Download new scripts from server and reload |
| **Review Bypass** | Updates bypass App Store review | Similarly bypasses review (logic only) |
| **Sandbox Execution** | Runs in isolated environment | Designed as sandboxed execution |

## Technical Differences

| Feature | Lua Solutions | Flux Solution |
|------|---------|----------|
| **Primary Use** | Game Logic (Unity/Cocos2d-x) | Flutter UI + Business Logic |
| **Flutter Integration** | Requires 3rd-party libs like `LuaDardo` | Native design specifically for Flutter |
| **Syntax Style** | Lua Syntax (Higher learning curve) | Dart/JS-like syntax (Low learning cost) |
| **Widget Support** | Requires manual bridging | Built-in Flutter widget bindings |
| **State Management** | Manual implementation | Built-in `state` keyword + Riverpod |

## Industry Solutions

### 🎮 Gaming
- **xLua (Tencent)**: Used for Unity hot updates, widely in mobile games.
- **Cocos2d-x + Lua**: Many 2D games use Lua for scripting logic.
- **ToLua / SLua**: Other Lua integrations for Unity.

### 📱 Flutter
- **LuaDardo**: Pure Dart implementation of Lua 5.3 VM.
- **flutter_embed_lua**: Embedded Lua interpreter lacking UI integration.
- **Shorebird**: Dart Code Push solution for Flutter (pushes Dart code).

## Unique Advantages of Flux

1. **Designed for Flutter**
   - No extra bridging layer; native support for Flutter Widgets.
   - Perfectly fits the reactive UI model of Flutter.

2. **Dart-like Syntax**
   - Almost zero learning curve for Flutter developers.
   - Uses familiar keywords like `widget`, `state`, and `build`.

3. **Complete Toolchain**
   - LSP Support (Intelligent completion, Go to definition).
   - VS Code Extension (Syntax highlighting, snippets).
   - CLI Tool (Script execution and debugging).

4. **Lightweight Integration**
   - No complex setup required.
   - A single `FluxWidget` can embed any Flutter page.

## Language Interop Mechanisms

### How Lua Connects to Host

Lua's success in gaming is due to its **embedded design** and **bidirectional binding**:

```
┌─────────────────────────────────────────────────────┐
│                    Host Application                  │
│  ┌───────────┐        ┌───────────────────────────┐ │
│  │  C/C++    │◄──────►│     Lua VM               │ │
│  │  Code     │ Stack  │  ┌─────────────────────┐  │ │
│  │           │ API    │  │   Lua Script        │  │ │
│  └───────────┘        │  └─────────────────────┘  │ │
│                       └───────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

**Lua C API Features:**
1. **Stack-based Communication**: Pass data via a virtual stack.
2. **C Function Registration**: Expose C functions to Lua scripts.
3. **Lua Function Call**: C code can execute Lua functions.
4. **Type Conversion**: Automatic Lua table ↔ C struct conversion.

### How Flux Connects to Dart/Flutter

Flux adopts similar principles but optimized for Dart:

```
┌─────────────────────────────────────────────────────┐
│                   Flutter Application                │
│  ┌───────────┐        ┌───────────────────────────┐ │
│  │   Dart    │◄──────►│     Flux VM              │ │
│  │   Code    │Bindings│  ┌─────────────────────┐  │ │
│  │  (Widget) │        │  │   .flux Script      │  │ │
│  └───────────┘        │  └─────────────────────┘  │ │
│                       └───────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

**Flux Binding System:**

| Capability | Lua (C API) | Flux (Dart Bindings) |
|------|-------------|---------------------|
| Call host from script | `lua_register()` | `registerFunction()` |
| Call script from host | `lua_pcall()` | `vm.callFunction()` |
| Pass complex data | Stack push/pop | Direct Dart object mapping |
| UI Component Integration | Manual bridge | Built-in Widget Bindings |

### Interop Examples

**1. Calling Dart from Flux:**

```dart
// Dart side
final vm = VM();
vm.registerFunction('showToast', (args) {
  final message = args[0] as String;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
  return null;
});
```

```javascript
// Flux side
showToast("Hello from Flux!")
```

**2. Built-in Widget Bindings:**

Flux includes bindings for 50+ Flutter Widgets natively:

```javascript
Container(
  color: "blue",
  child: Column(
    children: [
      Text(text: "Hello"),
      Button(text: "Click", onPressed: fn() { ... })
    ]
  )
)
```

## Conclusion

Flux is not a reinvention but a redesign of the **Lua hot update pattern** specifically for the **Flutter ecosystem**. It combines the maturity of Lua patterns with the convenience of Flutter development.

---

📚 [Back to README](../README.md) | [Lua Migration Guide](./lua_migration.md)
