# Flux Language Reference

[漢文文檔](language_reference_ZH.md)

## Variables

```flux
var name = "value";    // Mutable variable
var count = 42;        // Number
var active = true;     // Boolean
var nothing = nil;     // Null
```

## Data Types

| Type | Example |
|------|---------|
| Number | `42`, `3.14`, `-7` |
| String | `"hello"`, `'world'` |
| Boolean | `true`, `false` |
| Nil | `nil` |
| List | `[1, 2, 3]` |
| Map | `{"key": "value"}` |

## Operators

### Arithmetic
```flux
1 + 2    // 3
5 - 3    // 2
4 * 2    // 8
10 / 3   // 3.333...
10 % 3   // 1
-x       // Negate
```

### Comparison
```flux
a == b   // Equal
a != b   // Not equal
a < b    // Less than
a > b    // Greater than
a <= b   // Less or equal
a >= b   // Greater or equal
```

### Logical
```flux
!true    // false
a && b   // And (short-circuit)
a || b   // Or (short-circuit)
```

## Control Flow

### If Statement
```flux
if (condition) {
  // true branch
} else {
  // false branch
}
```

### While Loop
```flux
while (condition) {
  // loop body
}
```

### For Loop
```flux
for (var i = 0; i < 10; i = i + 1) {
  print(i);
}
```

## Functions

```flux
fn add(a, b) {
  return a + b;
}

var result = add(3, 4);  // 7
```

### Anonymous Functions (Lambdas)
```flux
var double = fn(x) { return x * 2; };
print(double(5));  // 10
```

### Closures
```flux
fn counter() {
  var count = 0;
  return fn() {
    count = count + 1;
    return count;
  };
}

var c = counter();
print(c());  // 1
print(c());  // 2
```

## Classes

```flux
class Point {
  field x = 0;
  field y = 0;
  
  init(px, py) {
    this.x = px;
    this.y = py;
  }
  
  distance() {
    return sqrt(this.x * this.x + this.y * this.y);
  }
}

var p = Point(3, 4);
print(p.distance());  // 5
```

### Inheritance
```flux
class Animal {
  speak() { print("..."); }
}

class Dog < Animal {
  speak() { print("Woof!"); }
}
```

## Exception Handling

```flux
try {
  // risky code
  throw "Something went wrong";
} catch (e) {
  print("Error: " + e);
} finally {
  // cleanup
}
```

## Async/Await

```flux
var data = await fetch("https://api.example.com");
print(data);
```

## Widgets (Flutter)

```flux
widget Counter {
  state count = 0;
  
  build {
    return Column(
      children: [
        Text(text: "Count: " + count),
        Button(
          text: "Increment",
          onTap: fn() { count = count + 1; }
        )
      ]
    );
  }
}
```

## Imports

```flux
import "utils.flux";
import "components/button.flux";
```
