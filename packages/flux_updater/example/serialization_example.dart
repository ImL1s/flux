/// Flux Compiler 序列化範例
/// 
/// 展示如何編譯、序列化、反序列化 Flux bytecode
/// 運行: dart run example/serialization_example.dart

import 'dart:io';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_updater/flux_updater.dart';

void main() async {
  print('╔════════════════════════════════════════╗');
  print('║   Flux Compiler 序列化範例              ║');
  print('╚════════════════════════════════════════╝\n');

  // 源代碼
  const source = '''
    widget Counter {
      state count = 0;
      build {
        Column {
          Text("Count: " + toString(count))
          Button("Increment", onPressed: fn() {
            count = count + 1;
          })
        }
      }
    }
  ''';

  // === Step 1: 編譯 ===
  print('📝 Step 1: 編譯源代碼...');
  final lexer = Lexer(source);
  final tokens = lexer.tokenize();
  final parser = Parser(tokens);
  final unit = parser.parse();
  
  if (parser.errors.isNotEmpty) {
    print('❌ 編譯錯誤: ${parser.errors}');
    return;
  }
  
  final compiler = Compiler(unit: unit);
  final chunk = compiler.endCompiler().chunk;
  print('   ✅ 編譯成功! Bytecode: ${chunk.code.length} bytes\n');

  // === Step 2: 序列化 ===
  print('💾 Step 2: 序列化 Chunk...');
  final bytes = ChunkSerializer.serialize(chunk);
  print('   ✅ 序列化完成: ${bytes.length} bytes');
  print('   Header: ${bytes.take(16).toList()}\n');

  // === Step 3: 保存到文件 (可選) ===
  print('📁 Step 3: 保存到文件...');
  final tempFile = File('${Directory.systemTemp.path}/counter.fluxc');
  await tempFile.writeAsBytes(bytes);
  print('   ✅ 已保存: ${tempFile.path}\n');

  // === Step 4: 從文件讀取 ===
  print('📖 Step 4: 從文件讀取...');
  final loadedBytes = await tempFile.readAsBytes();
  print('   ✅ 讀取: ${loadedBytes.length} bytes\n');

  // === Step 5: 反序列化 ===
  print('🔄 Step 5: 反序列化...');
  final loadedChunk = ChunkSerializer.deserialize(loadedBytes);
  print('   ✅ 反序列化完成!');
  print('   Bytecode: ${loadedChunk.code.length} bytes');
  print('   Constants: ${loadedChunk.constants.length} items\n');

  // === Step 6: 驗證 ===
  print('✅ Step 6: 驗證一致性...');
  final originalBytes = chunk.code;
  final loadedBytesFromChunk = loadedChunk.code;
  
  bool isEqual = originalBytes.length == loadedBytesFromChunk.length;
  if (isEqual) {
    for (int i = 0; i < originalBytes.length; i++) {
      if (originalBytes[i] != loadedBytesFromChunk[i]) {
        isEqual = false;
        break;
      }
    }
  }
  
  if (isEqual) {
    print('   ✅ Bytecode 完全一致!');
  } else {
    print('   ❌ Bytecode 不一致');
  }

  // 清理
  await tempFile.delete();
  
  print('\n═══════════════════════════════════════════');
  print('序列化流程: Source → Compile → Serialize → Save');
  print('反序列化流程: Load → Deserialize → Execute');
  print('═══════════════════════════════════════════');
}
