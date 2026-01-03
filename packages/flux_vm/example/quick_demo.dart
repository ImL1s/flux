/// Flux 快速示例
/// 運行: dart run example/quick_demo.dart


import 'package:flux_vm/flux_vm.dart';

void main() {
  print('=== Flux 腳本示例 ===\n');
  
  // 創建 VM
  final vm = VM();
  vm.onPrint = (msg) => print('  輸出: $msg');
  
  // 示例 1: 基本變量和計算
  print('【示例 1: 變量和計算】');
  vm.interpret('''
    var x = 10;
    var y = 20;
    print(x + y);
    print(x * y);
  ''');
  
  // 示例 2: 函數
  print('\n【示例 2: 函數】');
  vm.interpret('''
    fn greet(name) {
      return "Hello, " + name + "!";
    }
    print(greet("Flux"));
  ''');
  
  // 示例 3: 條件判斷
  print('\n【示例 3: 條件判斷】');
  vm.interpret('''
    var score = 85;
    if (score >= 90) {
      print("優秀");
    } else if (score >= 60) {
      print("及格");
    } else {
      print("不及格");
    }
  ''');
  
  // 示例 4: 迴圈
  print('\n【示例 4: 迴圈】');
  vm.interpret('''
    var sum = 0;
    for (var i = 1; i <= 5; i = i + 1) {
      sum = sum + i;
    }
    print("1+2+3+4+5 = " + sum);
  ''');
  
  // 示例 5: 列表操作
  print('\n【示例 5: 列表】');
  vm.interpret('''
    var fruits = ["蘋果", "香蕉", "橘子"];
    print("水果數量: " + len(fruits));
    push(fruits, "葡萄");
    print("添加後: " + len(fruits));
  ''');
  
  // 示例 6: 字典/映射
  print('\n【示例 6: 映射】');
  vm.interpret('''
    var person = {
      "name": "小明",
      "age": 25
    };
    print(person["name"]);
    print(person["age"]);
  ''');
  
  // 示例 7: 標準庫函數
  print('\n【示例 7: 標準庫】');
  vm.interpret('''
    // 數學
    print("sqrt(16) = " + Math.sqrt(16));
    print("abs(-5) = " + Math.abs(-5));
    
    // 字串
    print(upper("hello"));
    print(lower("WORLD"));
  ''');
  
  print('\n=== 示例結束 ===');
}
