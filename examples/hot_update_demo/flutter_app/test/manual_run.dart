import 'dart:io';
import 'package:flux_vm/flux_vm.dart';

void main() {
  print('🚀 Starting Manual VM Hot Update Check');
  
  try {
    // 1. Initialize VM
    final vm = VM();
    print('✅ VM Initialized');

    // 2. Run Version A (Update Global State)
    print('👉 Executing Version A...');
    // We use a global variable 'status' to verify execution side effects
    
    // First run: Declare and set
    // Note: Flux VM treats top level assignments as global sets if not local.
    // If 'var' is required, we use it. 
    // Let's rely on standard implicit global or var decl.
    // Given the stdlib test experience, we can use globals access directly via map 
    // OR script execution.
    // Let's try script based global setting.
    vm.interpret('var status = "Version A";');
    
    if (vm.globals['status'] != "Version A") {
       throw "Expected global 'status' to be 'Version A', got '${vm.globals['status']}'";
    }
    print('✅ Version A executed. Global status: ${vm.globals['status']}');

    // 3. Hot Update: Run Version B (Change State)
    print('👉 Executing Version B (Hot Update)...');
    
    // Changing the "File" (simulated by running new code on same VM)
    vm.interpret('status = "Version B";');

    if (vm.globals['status'] != "Version B") {
       throw "Expected global 'status' to be 'Version B', got '${vm.globals['status']}'";
    }
    print('✅ Version B executed. Global status: ${vm.globals['status']}');
    print('🎉 HOT UPDATE LOGIC VERIFIED!');
    
  } catch (e, stack) {
    print('❌ FAILED: $e');
    print(stack);
    exit(1);
  }
}
