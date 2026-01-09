/// Flux VM Hot Swap 範例
///
/// 展示如何在運行中更新腳本而不丟失狀態
/// 運行: dart run example/hot_swap_example.dart

import 'package:flux_vm/flux_vm.dart';

void main() {
  print('╔════════════════════════════════════════╗');
  print('║   Flux VM Hot Swap (熱更新) 範例        ║');
  print('╚════════════════════════════════════════╝\n');

  // 創建 VM
  final vm = VM();
  vm.onPrint = (msg) => print('  輸出: $msg');

  // === 版本 1.0.0 ===
  print('📦 載入版本 1.0.0...');
  const v1Source = '''
    var counter = 0;
    
    fn increment() {
      counter = counter + 1;
      print("Counter: " + counter);
    }
    
    fn showVersion() {
      print("Version: 1.0.0");
    }
  ''';

  vm.interpret(v1Source);

  // 執行一些操作
  print('\n執行版本 1.0.0:');
  vm.interpret('showVersion();');
  vm.interpret('increment();');
  vm.interpret('increment();');
  vm.interpret('increment();');
  print('  當前 counter = 3\n');

  // === 熱更新到版本 1.1.0 ===
  print('🔥 熱更新到版本 1.1.0...');
  const v2Source = '''
    // counter 變量會被保留!
    
    fn increment() {
      counter = counter + 2;  // 現在每次增加 2
      print("Counter (x2): " + counter);
    }
    
    fn showVersion() {
      print("Version: 1.1.0 ✨");
    }
    
    fn newFeature() {
      print("這是新功能!");
    }
  ''';

  // 重新解釋腳本，但 counter 變量會被保留
  vm.interpret(v2Source);

  // 執行更新後的操作
  print('\n執行版本 1.1.0:');
  vm.interpret('showVersion();');
  vm.interpret('increment();'); // 現在增加 2，所以 counter = 5
  vm.interpret('increment();'); // counter = 7
  vm.interpret('newFeature();'); // 使用新功能

  print('\n');
  print('✅ 熱更新成功! counter 從 3 增加到 7 (每次 +2)');
  print('   狀態被保留，新功能可用');

  print('\n═══════════════════════════════════════════');
}
