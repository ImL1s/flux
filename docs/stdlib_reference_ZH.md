# 標準庫參考 (Standard Library Reference)

[English Documentation](stdlib_reference.md)

## 核心內建函式 (Built-in Functions)

### print(value)
將值輸出到控制台。
```flux
print("Hello");
print(42);
```

### len(collection)
獲取列表、字串或映射的長度。
```flux
len([1, 2, 3])     // 3
len("hello")       // 5
len({"a": 1})      // 1
```

### type(value)
獲取值的類型（以字串形式返回）。
```flux
type(42)           // "number"
type("hi")         // "string"
type([1,2])        // "list"
```

---

## 列表函式 (List Functions)

### push(list, value)
在列表末尾添加元素。
```flux
var l = [1, 2];
push(l, 3);  // l = [1, 2, 3]
```

### pop(list)
移除並返回最後一個元素。
```flux
var l = [1, 2, 3];
var x = pop(l);  // x = 3, l = [1, 2]
```

### insert(list, index, value)
在指定索引處插入元素。
```flux
var l = [1, 3];
insert(l, 1, 2);  // l = [1, 2, 3]
```

### remove(list, index)
移除指定索引處的元素。
```flux
var l = [1, 2, 3];
remove(l, 1);  // l = [1, 3]
```

### indexOf(list, value)
查找值的索引（如果未找到則返回 -1）。
```flux
indexOf([1, 2, 3], 2)  // 1
```

### sort(list)
原地排序列表。
```flux
var l = [3, 1, 2];
sort(l);  // l = [1, 2, 3]
```

### reverse(list)
原地翻轉列表。
```flux
var l = [1, 2, 3];
reverse(l);  // l = [3, 2, 1]
```

### join(list, separator)
將列表元素連接成字串。
```flux
join(["a", "b", "c"], "-")  // "a-b-c"
```

---

## 字串函式 (String Functions)

### upper(string)
轉換為大寫。
```flux
upper("hello")  // "HELLO"
```

### lower(string)
轉換為小寫。
```flux
lower("HELLO")  // "hello"
```

### trim(string)
移除兩端的空白字元。
```flux
trim("  hi  ")  // "hi"
```

### split(string, delimiter)
將字串分割成列表。
```flux
split("a,b,c", ",")  // ["a", "b", "c"]
```

### contains(string, substring)
檢查字串是否包含子字串。
```flux
contains("hello", "ell")  // true
```

### replace(string, old, new)
替換出現的子字串。
```flux
replace("hello", "l", "L")  // "heLLo"
```

### substring(string, start, end)
提取子字串。
```flux
substring("hello", 1, 4)  // "ell"
```

### toInt(string)
將字串解析為整數。
```flux
toInt("42")  // 42
```

### toDouble(string)
將字串解析為浮點數 (double)。
```flux
toDouble("3.14")  // 3.14
```

---

## 數學函式 (Math Functions)

### abs(number)
絕對值。
```flux
abs(-5)  // 5
```

### min(a, b)
兩個數字中的最小值。
```flux
min(3, 7)  // 3
```

### max(a, b)
兩個數字中的最大值。
```flux
max(3, 7)  // 7
```

### floor(number)
向下取整。
```flux
floor(3.7)  // 3
```

### ceil(number)
向上取整。
```flux
ceil(3.2)  // 4
```

### sqrt(number)
平方根。
```flux
sqrt(16)  // 4
```

### pow(base, exponent)
冪運算。
```flux
pow(2, 3)  // 8
```

### random()
返回 0 到 1 之間的隨機數。
```flux
random()  // 0.123...
```

### randomInt(min, max)
返回 [min, max] 範圍內的隨機整數。
```flux
randomInt(1, 10)  // 7
```

---

## JSON 模組 (JSON Module)

### json.parse(string)
將 JSON 字串解析為映射 (Map)。
```flux
var data = json.parse('{"name": "Flux"}');
print(data["name"]);  // "Flux"
```

### json.stringify(value)
將值轉換為 JSON 字串。
```flux
var s = json.stringify({"x": 1, "y": 2});
// '{"x":1,"y":2}'
```

---

## HTTP 模組 (HTTP Module)

### http.get(url)
HTTP GET 請求（非同步）。
```flux
var response = await http.get("https://api.example.com/data");
print(response);
```

### http.post(url, body)
HTTP POST 請求（非同步）。
```flux
var response = await http.post("https://api.example.com/data", {"key": "value"});
```

---

## 儲存模組 (Storage Module)

### storage.get(key)
獲取存儲的值（非同步）。
```flux
var value = await storage.get("username");
```

### storage.set(key, value)
存儲值（非同步）。
```flux
await storage.set("username", "john");
```

---

## 計時器模組 (Timer Module)

### timer.delay(ms)
延遲執行（非同步）。
```flux
await timer.delay(1000);  // 等待 1 秒
print("Done!");
```

---

## 設備模組 (Device Module - Flutter)

### device.os
獲取作業系統。
```flux
print(device.os);  // "android" 或 "ios"
```

### device.version
獲取作業系統版本。
```flux
print(device.version);  // "13"
```

### device.model
獲取設備型號。
```flux
print(device.model);  // "Pixel 7"
```

---

## 對話框模組 (Dialog Module - Flutter)

### dialog.alert(title, message)
顯示警報對話框（非同步）。
```flux
await dialog.alert("注意", "任務已完成！");
```

### dialog.confirm(title, message)
顯示確認對話框（非同步）。
```flux
var result = await dialog.confirm("刪除", "您確定嗎？");
if (result) { /* 執行刪除 */ }
```

### dialog.toast(message)
顯示 Toast 提示。
```flux
dialog.toast("已儲存！");
```
