import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_compiler/flux_compiler.dart';

void main() {
  test('MemoryManager tracks allocations', () {
    final vm = VM();
    final stats = vm.memoryManager.stats;

    expect(stats.aliveInstances, 0);
    expect(stats.totalAllocated, 0);

    // Track an instance
    final classObj = CompiledClass('TestClass', methods: {}, fields: []);
    final instance = FluxInstance(classObj);
    vm.memoryManager.trackInstance(instance);

    expect(stats.aliveInstances, 1);
    expect(stats.totalAllocated, 1);

    // Track a closure
    final function = CompiledFunction('test', Chunk());
    final closure = ObjClosure(function, []);
    vm.memoryManager.trackClosure(closure);

    expect(stats.aliveClosures, 1);
    expect(stats.totalAllocated, 2);

    // Track an upvalue
    final upvalue = ObjUpvalue(0);
    vm.memoryManager.trackUpvalue(upvalue);

    expect(stats.aliveUpvalues, 1);
    expect(stats.totalAllocated, 3);
  });
}
