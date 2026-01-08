# Lua to Flux Migration Guide

[漢文文檔](lua_migration_ZH.md)

This guide helps developers with Lua hot update experience quickly get started with Flux. Flux's design philosophy aligns with Lua's application pattern in the game industry: **hot update only script logic, not native code**.

## Architecture Comparison

```
Lua Pattern (Unity/Cocos2d-x)          Flux Pattern (Flutter)
┌─────────────────────────┐         ┌─────────────────────────┐
│     Native Engine       │         │    Native Dart Code     │
│    (Immutable)          │         │    (Immutable)          │
├─────────────────────────┤         ├─────────────────────────┤
│       Lua VM            │         │       Flux VM           │
│  ┌─────────────────┐    │         │  ┌─────────────────┐    │
│  │  .lua scripts   │    │         │  │  .flux scripts  │    │
│  │  (Hot Update)   │    │         │  │  (Hot Update)   │    │
│  └─────────────────┘    │         │  └─────────────────┘    │
└─────────────────────────┘         └─────────────────────────┘
```

## Syntax Comparison

### Variable Declaration

```lua
-- Lua
local x = 10
local name = "Flux"
```

```javascript
// Flux
var x = 10;
var name = "Flux";
```

### Function Definition

```lua
-- Lua
function add(a, b)
    return a + b
end
```

```javascript
// Flux
fn add(a, b) {
  return a + b;
}
```

### Control Flow

```lua
-- Lua
if x > 5 then
    print("Greater")
else
    print("Smaller")
end

for i = 1, 10 do
    print(i)
end
```

```javascript
// Flux
if (x > 5) {
  print("Greater");
} else {
  print("Smaller");
}

for (var i = 0; i < 10; i = i + 1) {
  print(i);
}
```

### Classes & Objects

```lua
-- Lua (using metatables)
Point = {}
Point.__index = Point
function Point:new(x, y)
    return setmetatable({x=x, y=y}, Point)
end
```

```javascript
// Flux (Native class syntax)
class Point {
  field x = 0;
  field y = 0;
  init(px, py) {
    this.x = px;
    this.y = py;
  }
}
```

## Standard Library Mapping

| Feature | Lua | Flux |
|------|-----|------|
| Output | `print(x)` | `print(x)` |
| Length | `#list` | `len(list)` |
| Type | `type(x)` | `type(x)` |
| Uppercase | `string.upper(s)` | `upper(s)` |
| Concatenate | `..` | `+` |
| Delay | N/A | `await timer.delay(ms)` |

## Native Interoperability

### Lua C API
Registering a C function to be called from Lua.

### Flux Dart Bindings
Registering a Dart function to be called from Flux.

```dart
runtime.vm.registerFunction('myFunc', (args) => ...);
```

## Why Choose Flux over Lua in Flutter?

1. **Native Integration**: Flux is built in Dart for Dart, no NDK/C-bridge overhead.
2. **UI First**: Built-in 50+ Flutter Widget bindings.
3. **Reactive Binding**: Built-in `state` management that triggers `setState()` automatically.
4. **Tooling**: LSP and VS Code support specifically for Flux-Flutter development.

---

📚 [Back to README](../README.md) | [Language Reference](./language_reference.md)
