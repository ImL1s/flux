import 'dart:typed_data';

import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_updater/src/chunk_serializer.dart';
import 'package:test/test.dart';

void main() {
  group('ChunkSerializer', () {
    test('serializes and deserializes empty chunk', () {
      final chunk = Chunk();
      final bytes = ChunkSerializer.serialize(chunk);
      final restored = ChunkSerializer.deserialize(bytes);

      expect(restored.code, isEmpty);
      expect(restored.lines, isEmpty);
      expect(restored.constants, isEmpty);
    });

    test('serializes and deserializes chunk with code', () {
      final chunk = Chunk();
      chunk.writeOp(OpCode.constant, 1);
      chunk.write(0, 1); // constant index
      chunk.writeOp(OpCode.add, 2);
      chunk.writeOp(OpCode.return_, 3);

      final bytes = ChunkSerializer.serialize(chunk);
      final restored = ChunkSerializer.deserialize(bytes);

      expect(restored.code, equals(chunk.code));
      expect(restored.lines, equals(chunk.lines));
    });

    test('serializes and deserializes chunk with various constants', () {
      final chunk = Chunk();
      chunk.addConstant(null);
      chunk.addConstant(42);
      chunk.addConstant(3.14159);
      chunk.addConstant('Hello, World!');
      chunk.addConstant(true);
      chunk.addConstant(false);
      chunk.addConstant([1, 2, 3]);
      chunk.addConstant({'key': 'value', 'count': 10});

      final bytes = ChunkSerializer.serialize(chunk);
      final restored = ChunkSerializer.deserialize(bytes);

      expect(restored.constants.length, equals(chunk.constants.length));
      expect(restored.constants[0], isNull);
      expect(restored.constants[1], equals(42));
      expect(restored.constants[2], closeTo(3.14159, 0.00001));
      expect(restored.constants[3], equals('Hello, World!'));
      expect(restored.constants[4], isTrue);
      expect(restored.constants[5], isFalse);
      expect(restored.constants[6], equals([1, 2, 3]));
      expect(restored.constants[7], equals({'key': 'value', 'count': 10}));
    });

    test('serializes and deserializes CompiledFunction', () {
      final innerChunk = Chunk();
      innerChunk.writeOp(OpCode.constant, 1);
      innerChunk.write(0, 1);
      innerChunk.writeOp(OpCode.return_, 2);
      innerChunk.addConstant('inner value');

      final func = CompiledFunction(
        'testFunction',
        innerChunk,
        arity: 2,
        paramNames: ['a', 'b'],
      );

      final chunk = Chunk();
      chunk.addConstant(func);

      final bytes = ChunkSerializer.serialize(chunk);
      final restored = ChunkSerializer.deserialize(bytes);

      expect(restored.constants.length, equals(1));
      final restoredFunc = restored.constants[0] as CompiledFunction;
      expect(restoredFunc.name, equals('testFunction'));
      expect(restoredFunc.arity, equals(2));
      expect(restoredFunc.paramNames, equals(['a', 'b']));
      expect(restoredFunc.chunk.code, equals(innerChunk.code));
      expect(restoredFunc.chunk.constants[0], equals('inner value'));
    });

    test('handles script function', () {
      final func = CompiledFunction('script', Chunk());
      final chunk = Chunk();
      chunk.addConstant(func);

      final bytes = ChunkSerializer.serialize(chunk);
      final restored = ChunkSerializer.deserialize(bytes);

      final restoredFunc = restored.constants[0] as CompiledFunction;
      expect(restoredFunc.name, equals('script'));
    });

    test('throws on invalid magic header', () {
      final invalidBytes = Uint8List.fromList([0, 0, 0, 0, 1]);
      expect(
        () => ChunkSerializer.deserialize(invalidBytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on unsupported version', () {
      final invalidBytes =
          Uint8List.fromList([0x46, 0x4C, 0x55, 0x58, 99]); // version 99
      expect(
        () => ChunkSerializer.deserialize(invalidBytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('round-trip preserves line information', () {
      final chunk = Chunk();
      chunk.writeOp(OpCode.constant, 10);
      chunk.writeOp(OpCode.constant, 10); // same line
      chunk.writeOp(OpCode.add, 11);
      chunk.writeOp(OpCode.add, 11); // same line
      chunk.writeOp(OpCode.return_, 12);

      final bytes = ChunkSerializer.serialize(chunk);
      final restored = ChunkSerializer.deserialize(bytes);

      expect(restored.getLine(0), equals(10));
      expect(restored.getLine(1), equals(10));
      expect(restored.getLine(2), equals(11));
      expect(restored.getLine(3), equals(11));
      expect(restored.getLine(4), equals(12));
    });
  });
}
