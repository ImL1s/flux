import 'package:test/test.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  group('VM State Persistence', () {
    late VM vm;
    late InMemoryPersistenceDelegate delegate;

    setUp(() {
      vm = VM();
      delegate = InMemoryPersistenceDelegate();
      vm.persistenceDelegate = delegate;
    });

    test('initializeState loads persisted value', () async {
      // Create a widget with a persistent field 'count'
      // Create a widget with a persistent field 'count'

      // Mocking a widget with persistent fields.
      // In a real scenario, this would come from the compiler.
      final widget = CompiledWidget(
        'Counter',
        CompiledFunction('build', Chunk(), paramNames: []),
        stateFields: ['count'],
        stateInitializers: [
          CompiledFunction(
              'init',
              Chunk()
                ..writeOp(OpCode.constant, 0)
                ..write(0, 0)
                ..writeOp(OpCode.return_, 0)),
        ],
        persistentFields: {'count'},
      );

      // Pre-populate delegate
      await delegate.save('flux_state_Counter_count', 42);

      await vm.initializeState(widget);

      expect(vm.widgetState['count'], equals(42));
    });

    test('setState saves persistent value', () async {
      final widget = CompiledWidget(
        'Counter',
        CompiledFunction('build', Chunk(), paramNames: []),
        stateFields: ['count'],
        stateInitializers: [
          CompiledFunction(
              'init',
              Chunk()
                ..writeOp(OpCode.constant, 0)
                ..write(0, 0)
                ..writeOp(OpCode.return_, 0)),
        ],
        persistentFields: {'count'},
      );

      // Pre-add constant to chunk for the initializer
      widget.stateInitializers[0].chunk.addConstant(0);

      await vm.initializeState(widget);

      // Set state via VM
      // We need a chunk that does OpCode.setState
      final chunk = Chunk();
      final nameIdx = chunk.addConstant('count');
      final valIdx = chunk.addConstant(100);

      chunk.writeOp(OpCode.constant, 0);
      chunk.write(valIdx, 0);
      chunk.writeOp(OpCode.setState, 0);
      chunk.write(nameIdx, 0);
      chunk.writeOp(OpCode.return_, 0);

      vm.runChunk(chunk);

      expect(vm.widgetState['count'], equals(100));

      // Check if it was saved to delegate
      final persisted = await delegate.load('flux_state_Counter_count');
      expect(persisted, equals(100));
    });

    test('non-persistent state is not saved', () async {
      final widget = CompiledWidget(
        'Counter',
        CompiledFunction('build', Chunk(), paramNames: []),
        stateFields: ['count'],
        stateInitializers: [
          CompiledFunction(
              'init',
              Chunk()
                ..writeOp(OpCode.constant, 0)
                ..write(0, 0)
                ..writeOp(OpCode.return_, 0)),
        ],
        persistentFields: {}, // Not persistent
      );
      widget.stateInitializers[0].chunk.addConstant(0);

      await vm.initializeState(widget);

      final chunk = Chunk();
      final nameIdx = chunk.addConstant('count');
      final valIdx = chunk.addConstant(100);

      chunk.writeOp(OpCode.constant, 0);
      chunk.write(valIdx, 0);
      chunk.writeOp(OpCode.setState, 0);
      chunk.write(nameIdx, 0);
      chunk.writeOp(OpCode.return_, 0);

      vm.runChunk(chunk);

      expect(vm.widgetState['count'], equals(100));

      final persisted = await delegate.load('flux_state_Counter_count');
      expect(persisted, isNull);
    });
  });
}
