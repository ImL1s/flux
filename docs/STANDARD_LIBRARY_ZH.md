# Flux 標準庫 (Standard Library)

[English Documentation](STANDARD_LIBRARY.md)

Flux 支援一組核心內建函式，用於處理資料以及與系統進行互動。

## 通用函式 (Generic)

### `print(object)`
在控制台（或日誌）中列印物件的字串表示形式。
```dart
print("Hello");
```

### `toString(object)`
將任何物件轉換為其字串表示形式。
```dart
var s = toString(123); // "123"
```

### `now()`
返回自 Unix 紀元以來的當前時間戳（以毫秒為單位）。
```dart
var ts = now();
```

## 列表操作 (List Operations)

### `len(list)`
返回列表（或字串）中的元素數量。
```dart
var l = [1, 2, 3];
print(len(l)); // 3
```

### `push(list, item)`
在列表末尾添加一個項目。
```dart
push(list, 4);
```

### `pop(list)`
從列表中移除並返回最後一個項目。
```dart
var last = pop(list);
```

### `insert(list, index, item)`
在指定索引處插入一個項目。
```dart
insert(list, 0, "first");
```

### `remove(list, item)`
從列表中移除第一次出現的 `item`。如果找到則返回 `true`。
```dart
remove(list, "apple");
```

### `removeAt(list, index)`
移除指定索引處的項目並將其返回。
```dart
removeAt(list, 0);
```

### `indexOf(list, item)`
返回第一次出現 `item` 的索引，如果未找到則返回 -1。
```dart
var idx = indexOf(list, "b");
```

## 類型轉換 (Type Conversion)

### `parseInt(value, [defaultValue])`
將字串或數字解析為整數。失敗時返回 `defaultValue` 或 null。
```dart
var n = parseInt("42");
```

### `parseDouble(value, [defaultValue])`
將字串或數字解析為浮點數 (double)。
```dart
var d = parseDouble("3.14");
```

## 數學運算 (Math)

原生支援標準數學運算符 `+`, `-`, `*`, `/`, `%`。
更多的數學函式（例如 `sqrt`, `pow`）計劃在未來的更新中加入。

## JSON

JSON 解析目前透過互操作 (interop) 或隱式 Map 轉換處理。
計劃加入專用的 `jsonDecode` / `jsonEncode` 函式。
