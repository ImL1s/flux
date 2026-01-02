# Standard Library Reference

## Built-in Functions

### print(value)
Output a value to the console.
```flux
print("Hello");
print(42);
```

### len(collection)
Get length of a list, string, or map.
```flux
len([1, 2, 3])     // 3
len("hello")       // 5
len({"a": 1})      // 1
```

### type(value)
Get the type of a value as a string.
```flux
type(42)           // "number"
type("hi")         // "string"
type([1,2])        // "list"
```

---

## List Functions

### push(list, value)
Add element to end of list.
```flux
var l = [1, 2];
push(l, 3);  // l = [1, 2, 3]
```

### pop(list)
Remove and return last element.
```flux
var l = [1, 2, 3];
var x = pop(l);  // x = 3, l = [1, 2]
```

### insert(list, index, value)
Insert element at index.
```flux
var l = [1, 3];
insert(l, 1, 2);  // l = [1, 2, 3]
```

### remove(list, index)
Remove element at index.
```flux
var l = [1, 2, 3];
remove(l, 1);  // l = [1, 3]
```

### indexOf(list, value)
Find index of value (-1 if not found).
```flux
indexOf([1, 2, 3], 2)  // 1
```

### sort(list)
Sort list in place.
```flux
var l = [3, 1, 2];
sort(l);  // l = [1, 2, 3]
```

### reverse(list)
Reverse list in place.
```flux
var l = [1, 2, 3];
reverse(l);  // l = [3, 2, 1]
```

### join(list, separator)
Join list elements into string.
```flux
join(["a", "b", "c"], "-")  // "a-b-c"
```

---

## String Functions

### upper(string)
Convert to uppercase.
```flux
upper("hello")  // "HELLO"
```

### lower(string)
Convert to lowercase.
```flux
lower("HELLO")  // "hello"
```

### trim(string)
Remove whitespace from both ends.
```flux
trim("  hi  ")  // "hi"
```

### split(string, delimiter)
Split string into list.
```flux
split("a,b,c", ",")  // ["a", "b", "c"]
```

### contains(string, substring)
Check if string contains substring.
```flux
contains("hello", "ell")  // true
```

### replace(string, old, new)
Replace occurrences.
```flux
replace("hello", "l", "L")  // "heLLo"
```

### substring(string, start, end)
Extract substring.
```flux
substring("hello", 1, 4)  // "ell"
```

### toInt(string)
Parse string to integer.
```flux
toInt("42")  // 42
```

### toDouble(string)
Parse string to double.
```flux
toDouble("3.14")  // 3.14
```

---

## Math Functions

### abs(number)
Absolute value.
```flux
abs(-5)  // 5
```

### min(a, b)
Minimum of two numbers.
```flux
min(3, 7)  // 3
```

### max(a, b)
Maximum of two numbers.
```flux
max(3, 7)  // 7
```

### floor(number)
Round down.
```flux
floor(3.7)  // 3
```

### ceil(number)
Round up.
```flux
ceil(3.2)  // 4
```

### sqrt(number)
Square root.
```flux
sqrt(16)  // 4
```

### pow(base, exponent)
Power.
```flux
pow(2, 3)  // 8
```

### random()
Random number between 0 and 1.
```flux
random()  // 0.123...
```

### randomInt(min, max)
Random integer in range [min, max].
```flux
randomInt(1, 10)  // 7
```

---

## JSON Module

### json.parse(string)
Parse JSON string to map.
```flux
var data = json.parse('{"name": "Flux"}');
print(data["name"]);  // "Flux"
```

### json.stringify(value)
Convert value to JSON string.
```flux
var s = json.stringify({"x": 1, "y": 2});
// '{"x":1,"y":2}'
```

---

## HTTP Module

### http.get(url)
HTTP GET request (async).
```flux
var response = await http.get("https://api.example.com/data");
print(response);
```

### http.post(url, body)
HTTP POST request (async).
```flux
var response = await http.post("https://api.example.com/data", {"key": "value"});
```

---

## Storage Module

### storage.get(key)
Get stored value (async).
```flux
var value = await storage.get("username");
```

### storage.set(key, value)
Store value (async).
```flux
await storage.set("username", "john");
```

---

## Timer Module

### timer.delay(ms)
Delay execution (async).
```flux
await timer.delay(1000);  // Wait 1 second
print("Done!");
```

---

## Device Module (Flutter)

### device.os
Get operating system.
```flux
print(device.os);  // "android" or "ios"
```

### device.version
Get OS version.
```flux
print(device.version);  // "13"
```

### device.model
Get device model.
```flux
print(device.model);  // "Pixel 7"
```

---

## Dialog Module (Flutter)

### dialog.alert(title, message)
Show alert dialog (async).
```flux
await dialog.alert("Notice", "Task completed!");
```

### dialog.confirm(title, message)
Show confirm dialog (async).
```flux
var result = await dialog.confirm("Delete", "Are you sure?");
if (result) { /* delete */ }
```

### dialog.toast(message)
Show toast notification.
```flux
dialog.toast("Saved!");
```
