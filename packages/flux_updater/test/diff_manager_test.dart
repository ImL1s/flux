import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_updater/src/chunk_serializer.dart';
import 'package:flux_updater/src/diff_manager.dart';
import 'package:test/test.dart';

void main() {
  group('FluxDiffManager', () {
    test('creates and applies patch for simple chunk changes', () async {
      // Create old chunk
      final oldChunk = Chunk();
      oldChunk.writeOp(OpCode.constant, 1);
      oldChunk.write(0, 1);
      oldChunk.addConstant('Hello');
      oldChunk.writeOp(OpCode.return_, 2);

      // Create new chunk with small change
      final newChunk = Chunk();
      newChunk.writeOp(OpCode.constant, 1);
      newChunk.write(0, 1);
      newChunk.addConstant('Hello World'); // Changed constant
      newChunk.writeOp(OpCode.return_, 2);

      // Create patch
      final patch = await FluxDiffManager.createPatch(oldChunk, newChunk);

      // Apply patch
      final restored = await FluxDiffManager.applyPatch(oldChunk, patch);

      // Verify
      expect(restored.code, equals(newChunk.code));
      expect(restored.constants[0], equals('Hello World'));
    });

    test('patch is smaller than full chunk for minor changes', () async {
      // Create a larger chunk
      final oldChunk = Chunk();
      for (int i = 0; i < 100; i++) {
        oldChunk.writeOp(OpCode.constant, i);
        oldChunk.write(i % 10, i);
        oldChunk.addConstant('constant_$i');
      }
      oldChunk.writeOp(OpCode.return_, 100);

      // Create new chunk with one small change
      final newChunk = Chunk();
      for (int i = 0; i < 100; i++) {
        newChunk.writeOp(OpCode.constant, i);
        newChunk.write(i % 10, i);
        if (i == 50) {
          newChunk.addConstant('CHANGED_constant_$i'); // One change
        } else {
          newChunk.addConstant('constant_$i');
        }
      }
      newChunk.writeOp(OpCode.return_, 100);

      final oldBytes = ChunkSerializer.serialize(oldChunk);
      final newBytes = ChunkSerializer.serialize(newChunk);
      final patch =
          await FluxDiffManager.createPatchFromBytes(oldBytes, newBytes);

      // Patch should be significantly smaller
      print('Full size: ${newBytes.length} bytes');
      print('Patch size: ${patch.length} bytes');
      print(
          'Compression: ${(patch.length / newBytes.length * 100).toStringAsFixed(1)}%');

      expect(patch.length, lessThan(newBytes.length));
    });

    test('calculateCompressionRatio returns correct value', () {
      final full = ChunkSerializer.serialize(Chunk()..addConstant('test'));
      final patch = full.sublist(0, full.length ~/ 2); // Half size

      final ratio = FluxDiffManager.calculateCompressionRatio(full, patch);
      expect(ratio, closeTo(0.5, 0.1));
    });

    test('shouldUseDiff returns true for small patches', () {
      final full = ChunkSerializer.serialize(Chunk()..addConstant('test'));
      final smallPatch = full.sublist(0, full.length ~/ 4); // 25% size
      final largePatch = full; // 100% size

      expect(FluxDiffManager.shouldUseDiff(full, smallPatch), isTrue);
      expect(FluxDiffManager.shouldUseDiff(full, largePatch), isFalse);
    });

    test('handles empty chunks', () async {
      final oldChunk = Chunk();
      final newChunk = Chunk();
      newChunk.addConstant('new');

      final patch = await FluxDiffManager.createPatch(oldChunk, newChunk);
      final restored = await FluxDiffManager.applyPatch(oldChunk, patch);

      expect(restored.constants.length, equals(1));
      expect(restored.constants[0], equals('new'));
    });
  });
}
