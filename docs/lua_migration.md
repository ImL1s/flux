# Lua to Flux Migration Guide

本指南幫助有 Lua 熱更新經驗的開發者快速上手 Flux。Flux 的設計理念與 Lua 在遊戲產業的應用模式一致：**只熱更新腳本邏輯，不更新原生代碼**。

## 架構對比

```
Lua 模式 (Unity/Cocos2d-x)          Flux 模式 (Flutter)
┌─────────────────────────┐         ┌─────────────────────────┐
│    C++/C# 原生引擎       │         │    Dart 原生代碼         │
│    (不可更新)            │         │    (不可更新)            │
├─────────────────────────┤         ├─────────────────────────┤
│       Lua VM            │         │       Flux VM           │
│  ┌─────────────────┐    │         │  ┌─────────────────┐    │
│  │  .lua 腳本      │    │         │  │  .flux 腳本     │    │
│  │  (可熱更新)     │    │         │  │  (可熱更新)     │    │
│  └─────────────────┘    │         │  └─────────────────┘    │
└─────────────────────────┘         └─────────────────────────┘
```

## 語法對照表

### 變數宣告

```lua
-- Lua
local x = 10
local name = "Flux"
local isReady = true
local items = {1, 2, 3}
local config = {host = "localhost", port = 8080}
```

```javascript
// Flux
var x = 10;
var name = "Flux";
var isReady = true;
var items = [1, 2, 3];
var config = {"host": "localhost", "port": 8080};
```

### 函數定義

```lua
-- Lua
function add(a, b)
    return a + b
end

-- 或
local add = function(a, b)
    return a + b
end
```

```javascript
// Flux
fn add(a, b) {
  return a + b;
}

// 或匿名函數
var add = fn(a, b) {
  return a + b;
};
```

### 控制流

```lua
-- Lua
if x > 5 then
    print("Greater")
elseif x == 5 then
    print("Equal")
else
    print("Smaller")
end

for i = 1, 10 do
    print(i)
end

while x > 0 do
    x = x - 1
end

for i, v in ipairs(items) do
    print(v)
end
```

```javascript
// Flux
if (x > 5) {
  print("Greater");
} else if (x == 5) {
  print("Equal");
} else {
  print("Smaller");
}

for (var i = 0; i < 10; i = i + 1) {
  print(i);
}

while (x > 0) {
  x = x - 1;
}

for (var i = 0; i < len(items); i = i + 1) {
  print(items[i]);
}
```

### 閉包

```lua
-- Lua
function counter()
    local count = 0
    return function()
        count = count + 1
        return count
    end
end

local c = counter()
print(c())  -- 1
print(c())  -- 2
```

```javascript
// Flux
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

### 類別與物件

```lua
-- Lua (使用 metatable)
Point = {}
Point.__index = Point

function Point:new(x, y)
    local self = setmetatable({}, Point)
    self.x = x or 0
    self.y = y or 0
    return self
end

function Point:distance()
    return math.sqrt(self.x^2 + self.y^2)
end

local p = Point:new(3, 4)
print(p:distance())  -- 5
```

```javascript
// Flux (原生 class 語法)
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

### 繼承

```lua
-- Lua
Animal = {}
Animal.__index = Animal

function Animal:speak()
    print("...")
end

Dog = setmetatable({}, {__index = Animal})
Dog.__index = Dog

function Dog:speak()
    print("Woof!")
end
```

```javascript
// Flux
class Animal {
  speak() { print("..."); }
}

class Dog < Animal {
  speak() { print("Woof!"); }
}
```

### 錯誤處理

```lua
-- Lua
local status, err = pcall(function()
    error("Something went wrong")
end)

if not status then
    print("Error: " .. err)
end
```

```javascript
// Flux
try {
  throw "Something went wrong";
} catch (e) {
  print("Error: " + e);
} finally {
  print("Cleanup");
}
```

### 異步操作

```lua
-- Lua (coroutine)
local co = coroutine.create(function()
    local data = fetchData()  -- 需自行實現異步
    coroutine.yield(data)
end)

local status, result = coroutine.resume(co)
```

```javascript
// Flux (原生 async/await)
async fn loadData() {
  var data = await http.get("https://api.example.com/data");
  return data;
}

var result = await loadData();
```

## 標準庫對照

| 功能 | Lua | Flux |
|------|-----|------|
| 輸出 | `print(x)` | `print(x)` |
| 長度 | `#list` 或 `string.len(s)` | `len(list)` 或 `len(s)` |
| 類型 | `type(x)` | `type(x)` |
| 字串轉大寫 | `string.upper(s)` | `upper(s)` |
| 字串轉小寫 | `string.lower(s)` | `lower(s)` |
| 字串裁切 | `string.sub(s, i, j)` | `substring(s, i, j)` |
| 字串分割 | 需自行實現 | `split(s, delimiter)` |
| 字串替換 | `string.gsub(s, p, r)` | `replace(s, old, new)` |
| 數學函數 | `math.abs()`, `math.sqrt()` | `abs()`, `sqrt()` |
| 隨機數 | `math.random()` | `random()`, `randomInt(max)` |
| 陣列添加 | `table.insert(t, v)` | `push(list, value)` |
| 陣列移除 | `table.remove(t)` | `pop(list)` |
| JSON 解析 | 需第三方庫 | `json.parse(str)` |
| JSON 序列化 | 需第三方庫 | `json.stringify(obj)` |
| 延遲執行 | 需自行實現 | `await timer.delay(ms)` |
| 正則匹配 | `string.match(s, p)` | `regex.match(pattern, s)` |
| Base64 | 需第三方庫 | `base64.encode()`, `base64.decode()` |
| 日期時間 | `os.date()`, `os.time()` | `date.now()`, `date.format()` |

## 原生互操作對比

### Lua C API

```c
// C 側：註冊函數
static int l_showToast(lua_State *L) {
    const char *msg = luaL_checkstring(L, 1);
    // 調用原生 Toast...
    showNativeToast(msg);
    return 0;  // 返回值數量
}

// 註冊到 Lua
lua_register(L, "showToast", l_showToast);
```

```lua
-- Lua 側調用
showToast("Hello from Lua!")
```

### Flux Dart Bindings

```dart
// Dart 側：註冊函數
runtime.vm.registerFunction('showToast', (args) {
  final message = args[0] as String;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
  return null;
});
```

```javascript
// Flux 側調用
showToast("Hello from Flux!")
```

## 狀態管理對比

### Lua 方式（需手動實現）

```lua
-- Lua: 狀態管理需自行實現
local state = {
    count = 0,
    items = {}
}

function increment()
    state.count = state.count + 1
    updateUI()  -- 需手動調用 UI 更新
end

function addItem(item)
    table.insert(state.items, item)
    updateUI()  -- 需手動調用 UI 更新
end

-- UI 綁定需自行處理
function updateUI()
    -- 手動更新所有相關 UI 組件...
end
```

### Flux 方式（自動響應）

```javascript
// Flux: 內建響應式狀態
widget Counter {
  state count = 0;
  state items = [];

  build {
    Column(
      children: [
        Text(text: "Count: " + count),
        Button(
          text: "Increment",
          onPressed: fn() {
            count = count + 1;  // 自動觸發 UI 重建
          }
        ),
        Button(
          text: "Add Item",
          onPressed: fn() {
            push(items, "New Item");  // 自動觸發 UI 重建
          }
        )
      ]
    )
  }
}
```

## UI 綁定對比

### Lua + Unity/Cocos2d-x

```lua
-- Lua: 需手動橋接 UI
local button = cc.ui.UIPushButton.new("button.png")
button:onButtonPressed(function()
    print("Button pressed")
end)
button:addTo(scene)

-- 或使用 xLua 綁定
local go = CS.UnityEngine.GameObject("Button")
local btn = go:AddComponent(typeof(CS.UnityEngine.UI.Button))
btn.onClick:AddListener(function()
    print("Button pressed")
end)
```

### Flux + Flutter

```javascript
// Flux: 內建 50+ Widget 綁定
widget MyPage {
  build {
    Scaffold(
      appBar: AppBar(title: "My App"),
      body: Column(
        children: [
          Text(text: "Hello"),
          Button(
            text: "Press Me",
            onPressed: fn() {
              print("Button pressed");
            }
          ),
          TextField(
            hint: "Enter text",
            onChanged: fn(value) {
              print("Input: " + value);
            }
          ),
          Image(src: "https://example.com/image.png"),
          ListView(
            children: [
              ListTile(title: "Item 1"),
              ListTile(title: "Item 2")
            ]
          )
        ]
      )
    )
  }
}
```

## 熱更新流程對比

### Lua 熱更新（典型流程）

```lua
-- 1. 檢查版本
local serverVersion = http.get(VERSION_URL)
if serverVersion > LOCAL_VERSION then
    -- 2. 下載新腳本
    local newScript = http.get(SCRIPT_URL)
    -- 3. 保存到本地
    io.write(LOCAL_PATH, newScript)
    -- 4. 重新載入
    package.loaded["game_logic"] = nil
    require("game_logic")
end
```

### Flux 熱更新

```dart
// Flutter 側
final updateManager = FluxUpdateManager(
  appId: 'com.example.app',
  serverUrl: 'https://ota.example.com',
  signingKey: 'your-key',
);

// 檢查並應用更新
final status = await updateManager.checkForUpdates();
if (status == UpdateStatus.updateAvailable) {
  await updateManager.downloadAndApply();
  // UI 自動重建
}
```

## 常見遷移問題

### 1. Lua 的 `nil` vs Flux 的 `null`

```lua
-- Lua
if value == nil then
    print("No value")
end
```

```javascript
// Flux
if (value == null) {
  print("No value");
}
```

### 2. 字串連接

```lua
-- Lua 使用 ..
local msg = "Hello, " .. name .. "!"
```

```javascript
// Flux 使用 +
var msg = "Hello, " + name + "!";
```

### 3. 陣列索引

```lua
-- Lua 陣列從 1 開始
local items = {"a", "b", "c"}
print(items[1])  -- "a"
```

```javascript
// Flux 陣列從 0 開始
var items = ["a", "b", "c"];
print(items[0]);  // "a"
```

### 4. 表/物件語法

```lua
-- Lua table
local config = {
    host = "localhost",
    port = 8080
}
print(config.host)
print(config["port"])
```

```javascript
// Flux map
var config = {
  "host": "localhost",
  "port": 8080
};
print(config["host"]);
print(config["port"]);
```

### 5. 不支援的 Lua 功能

以下 Lua 功能在 Flux 中**不支援**（但在 UI 腳本場景下通常不需要）：

- `setmetatable()` / `getmetatable()` - 使用 class 替代
- `rawget()` / `rawset()` - 不需要
- `coroutine.yield()` - 使用 async/await 替代
- 弱引用表 - 不需要
- `debug` 庫 - Flux 有專用 DAP 調試器

## 遷移檢查清單

- [ ] 將 `function` 改為 `fn`
- [ ] 將 `local` 改為 `var`
- [ ] 將字串連接 `..` 改為 `+`
- [ ] 將 `nil` 改為 `null`
- [ ] 將陣列索引從 1-based 改為 0-based
- [ ] 將 `then`/`do`/`end` 改為 `{}`
- [ ] 將 metatable 類別改為 `class` 語法
- [ ] 將 `pcall` 改為 `try/catch`
- [ ] 將 coroutine 改為 `async/await`
- [ ] 使用內建 Widget 綁定替代手動 UI 橋接

---

📚 [返回主文檔](../README.md) | [語言參考](./language_reference.md) | [標準庫](./stdlib_reference.md)
