# Debugging Flux Applications

Flux supports full debugging capabilities in VSCode via the **Flux Extension**.

## Features
- **Breakpoints**: Click the gutter to pause execution.
- **Stepping**: Step Over (F10), Step Into (F11), Step Out (Shift+F11).
- **Variables**: Inspect local variables, lists, maps, and classes.
- **Call Stack**: View the current execution trace.
- **Deep Inspection**: Expand complex objects in the Variables view.

## How to Debug

1. Open `debug_example.flux` in VSCode.
2. Set a breakpoint by clicking on the left gutter (e.g., inside `calculateSum`).
3. Press **F5** or go to "Run and Debug" -> "Dart & Flux".
4. The debugger will launch and pause at your breakpoint.
5. Use the debug toolbar to step through code.

## REPL Evaluation
While paused, you can evaluate expressions in the **Debug Console**:
- Type `total` to see its current value.
- Type `i * 2` to test calculations.
- Type `config["mode"]` to check map values.
