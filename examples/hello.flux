// Hello World in Flux (Top-level script mode)

import "flux:core";

var greeting = "Hello, World!";
print(greeting);
  
var x = 10;
var y = 20;

if (x < y) {
  print("x is less than y");
} else {
  print("x is greater than or equal to y");
}
  
for (var i = 0; i < 5; i = i + 1) {
  print(i);
}

// Widgets are declaratively parsed but not executed// Widget 宣告 (DSL 語法測試)
widget MyCounter {
  state count = 0;
  
  build {
    Column {
      Text("Count: " + count)
      Button("Increment") { count = count + 1 }
    }
  }
}

// 嘗試引用 Widget (這會加載 CompiledWidget 常量)
print(MyCounter);
