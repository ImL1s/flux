# Flux Standard Library

Flux supports a core set of built-in functions for manipulating data and interacting with the system.

## Generic

### `print(object)`
Prints a string representation of the object to the console (or log).
```dart
print("Hello");
```

### `toString(object)`
Converts any object to its string representation.
```dart
var s = toString(123); // "123"
```

### `now()`
Returns the current timestamp in milliseconds since epoch.
```dart
var ts = now();
```

## List Operations

### `len(list)`
Returns the number of elements in a list (or string).
```dart
var l = [1, 2, 3];
print(len(l)); // 3
```

### `push(list, item)`
Adds an item to the end of the list.
```dart
push(list, 4);
```

### `pop(list)`
Removes and returns the last item from the list.
```dart
var last = pop(list);
```

### `insert(list, index, item)`
Inserts an item at the specified index.
```dart
insert(list, 0, "first");
```

### `remove(list, item)`
Removes the first occurrence of `item` from the list. Returns `true` if found.
```dart
remove(list, "apple");
```

### `removeAt(list, index)`
Removes the item at the specified index and returns it.
```dart
removeAt(list, 0);
```

### `indexOf(list, item)`
Returns the index of the first occurrence of `item`, or -1 if not found.
```dart
var idx = indexOf(list, "b");
```

## Type Conversion

### `parseInt(value, [defaultValue])`
Parses a string or number to an integer. Returns `defaultValue` or null on failure.
```dart
var n = parseInt("42");
```

### `parseDouble(value, [defaultValue])`
Parses a string or number to a double.
```dart
var d = parseDouble("3.14");
```

## Math

Standard math operators `+`, `-`, `*`, `/`, `%` are supported natively.
Additional math functions (e.g., `sqrt`, `pow`) are planned for future updates.

## JSON

JSON parsing is currently handled via interop or implicit map conversions.
Dedicated `jsonDecode` / `jsonEncode` functions are planned.
