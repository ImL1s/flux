# Flux Language Guide

[漢文文檔](LANGUAGE_GUIDE_ZH.md)

Flux is a dynamic scripting language designed for Flutter Server-Driven UI. It combines a Dart-like syntax with a reactive execution model similar to React or Flutter.

## Basics

### Variables

```dart
var x = 10;
var name = "Flux";
var isReady = true;
```

### Control Flow

```dart
if (x > 5) {
  print("Greater");
} else {
  print("Smaller");
}

while (x > 0) {
  x = x - 1;
}

for (var i = 0; i < 10; i = i + 1) {
  print(i);
}
```

### Functions

```dart
fn add(a, b) {
  return a + b;
}

print(add(5, 3)); // 8
```

## Widgets & State

Flux's core feature is its widget system.

### Stateful Widgets

A `widget` block defines a UI component. Use `state` for mutable data.

```dart
widget Counter {
  state count = 0;

  build {
    Column(
      children: [
        Text(text: "Count: " + toString(count)),
        SizedBox(height: 16.0),
        Button(
          text: "Increment", 
          onPressed: fn() {
            count = count + 1; // UI automatically rebuilds
          }
        )
      ]
    )
  }
}
```

### Stateless Widgets (Props)

Use `props` to accept parameters from parent widgets.

```dart
widget Greeting {
  props name;
  props color;

  build {
    Container(
      color: color,
      child: Text(text: "Hello, " + name + "!")
    )
  }
}

// Usage
Greeting(name: "Alice", color: "blue");
```

## Asynchronous Programming

Flux supports `async` / `await` for non-blocking operations.

```dart
async fn fetchData() {
  var data = await http.get("https://api.example.com/data");
  return data;
}

widget DataLoader {
  state data = "Loading...";

  build {
    Column(
      children: [
        Text(text: data),
        Button(
          text: "Load", 
          onPressed: async fn() {
            data = await fetchData();
          }
        )
      ]
    )
  }
}
```

## Exception Handling

```dart
try {
  throw "Something went wrong";
} catch (e) {
  print("Caught error: " + e);
} finally {
  print("Cleanup");
}
```

## Standard Library

- `print(obj)`: Print to console
- `toString(obj)`: Convert to string
- `len(list)`: Get length
- `push(list, item)`: Add to list
- `pop(list)`: Remove last item
- `now()`: Current timestamp
- `toDouble(x)`, `toInt(x)`: Type conversion

## Native Interop

Flux allows seamless communication between the script and the host (Dart/Flutter).

### Registering Native Functions (Dart Side)

You can register native Dart functions to be called from Flux scripts:

```dart
// In your Flutter code
runtime.vm.registerFunction('showNativeDialog', (args) {
  final message = args[0] as String;
  // Implement native logic...
  return null;
});
```

### Calling Native Functions (Flux Side)

Once registered, you can call them like any other function:

```dart
// In your Flux script
build {
  Button(
    text: "Show Native Dialog",
    onPressed: fn() {
      showNativeDialog("Hello from Flux!");
    }
  )
}
```

