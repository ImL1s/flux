# Flux 語言參考 (Language Reference)

[English Documentation](language_reference.md)

## 變數 (Variables)

```flux
var name = "值";        // 可變變數
var count = 42;        // 數字
var active = true;     // 布林值
var nothing = nil;     // 空值 (Null)
```

## 資料類型 (Data Types)

| 類型 | 範例 |
|------|---------|
| 數字 (Number) | `42`, `3.14`, `-7` |
| 字串 (String) | `"hello"`, `'world'` |
| 布林值 (Boolean) | `true`, `false` |
| 空值 (Nil) | `nil` |
| 列表 (List) | `[1, 2, 3]` |
| 映射 (Map) | `{"key": "value"}` |

## 運算符 (Operators)

### 算術運算 (Arithmetic)
```flux
1 + 2    // 3
5 - 3    // 2
4 * 2    // 8
10 / 3   // 3.333...
10 % 3   // 1
-x       // 取反 (Negate)
```

### 比較運算 (Comparison)
```flux
a == b   // 相等
a != b   // 不相等
a < b    // 小於
a > b    // 大於
a <= b   // 小於等於
a >= b   // 大於等於
```

### 邏輯運算 (Logical)
```flux
!true    // false
a && b   // 且 (短路運算)
a || b   // 或 (短路運算)
```

## 控制流 (Control Flow)

### If 語句
```flux
if (condition) {
  // true 分支
} else {
  // false 分支
}
```

### While 迴圈
```flux
while (condition) {
  // 迴圈體
}
```

### For 迴圈
```flux
for (var i = 0; i < 10; i = i + 1) {
  print(i);
}
```

## 函式 (Functions)

```flux
fn add(a, b) {
  return a + b;
}

var result = add(3, 4);  // 7
```

### 匿名函式 (Lambdas)
```flux
var double = fn(x) { return x * 2; };
print(double(5));  // 10
```

### 閉包 (Closures)
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

## 類別 (Classes)

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

### 繼承 (Inheritance)
```flux
class Animal {
  speak() { print("..."); }
}

class Dog < Animal {
  speak() { print("汪汪！"); }
}
```

## 例外處理 (Exception Handling)

```flux
try {
  // 可能出錯的程式碼
  throw "出了點問題";
} catch (e) {
  print("錯誤: " + e);
} finally {
  // 清理工作
}
```

## 非同步 (Async/Await)

```flux
var data = await fetch("https://api.example.com");
print(data);
```

## 組件 (Widgets - Flutter)

```flux
widget Counter {
  state count = 0;
  
  build {
    return Column(
      children: [
        Text(text: "計數: " + count),
        Button(
          text: "增加",
          onTap: fn() { count = count + 1; }
        )
      ]
    );
  }
}
```

## 導入 (Imports)

```flux
import "utils.flux";
import "components/button.flux";
```
