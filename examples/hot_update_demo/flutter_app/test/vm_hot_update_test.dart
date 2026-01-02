import 'dart:io';
import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';

void main() {
  test('VM Hot Update Logic Verification', () async {
    print('🚀 Starting VM Hot Update Test');
    
    // 1. Setup Temp File
    final tempDir = Directory.systemTemp.createTempSync('flux_vm_test');
    final scriptFile = File('${tempDir.path}/logic.flux');
    
    // Initial Script: Returns "Version A"
    scriptFile.writeAsStringSync('''
      return "Version A";
    ''');
    print('📝 Created script: Version A');

    // 2. Initial Run
    final vm = FluxVM();
    final compiler = FluxCompiler();
    
    // Compile and Run Version A
    var code = scriptFile.readAsStringSync();
    var chunk = compiler.compile(code);
    var result = vm.run(chunk);
    
    expect(result, equals("Version A"));
    print('✅ Version A executed successfully');

    // 3. Hot Update: Change File
    scriptFile.writeAsStringSync('''
      return "Version B";
    ''');
    print('📝 Updated script: Version B');

    // 4. Reload and Run
    // In a real app, we would use HotReloadService, but here we test the fundamental
    // ability to re-read and re-execute logic.
    code = scriptFile.readAsStringSync();
    chunk = compiler.compile(code);
    result = vm.run(chunk); // State would be preserved if we used runChunk() on same VM

    expect(result, equals("Version B"));
    print('✅ Version B executed successfully');
    
    // Cleanup
    tempDir.deleteSync(recursive: true);
    print('🏁 VM Hot Update Test Passed');
  });
}
