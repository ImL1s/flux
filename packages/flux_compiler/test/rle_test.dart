import 'package:test/test.dart';
import 'package:flux_compiler/src/bytecode.dart';

void main() {
  group('Chunk RLE Line Mapping', () {
    test('Empty chunk returns -1', () {
      final chunk = Chunk();
      expect(chunk.getLine(0), -1);
    });

    test('Single instruction', () {
      final chunk = Chunk();
      chunk.write(1, 10);
      expect(chunk.getLine(0), 10);
      expect(chunk.getLine(1), -1);
    });

    test('Multiple instructions on same line', () {
      final chunk = Chunk();
      chunk.write(1, 10);
      chunk.write(2, 10);
      chunk.write(3, 10);
      
      expect(chunk.lines, [3, 10]); // Run of 3 on line 10
      expect(chunk.getLine(0), 10);
      expect(chunk.getLine(1), 10);
      expect(chunk.getLine(2), 10);
      expect(chunk.getLine(3), -1);
    });

    test('Line changes', () {
      final chunk = Chunk();
      chunk.write(1, 10); // offset 0
      chunk.write(2, 10); // offset 1
      chunk.write(3, 11); // offset 2
      chunk.write(4, 11); // offset 3
      chunk.write(5, 12); // offset 4
      
      expect(chunk.lines, [2, 10, 2, 11, 1, 12]);
      
      expect(chunk.getLine(0), 10);
      expect(chunk.getLine(1), 10);
      expect(chunk.getLine(2), 11);
      expect(chunk.getLine(3), 11);
      expect(chunk.getLine(4), 12);
      expect(chunk.getLine(5), -1);
    });

    test('Large run', () {
      final chunk = Chunk();
      for (int i = 0; i < 1000; i++) {
        chunk.write(1, 1);
      }
      expect(chunk.lines, [1000, 1]);
      expect(chunk.getLine(0), 1);
      expect(chunk.getLine(500), 1);
      expect(chunk.getLine(999), 1);
      expect(chunk.getLine(1000), -1);
    });

    test('Non-sequential line numbers (e.g. loops/jumps)', () {
      final chunk = Chunk();
      chunk.write(1, 10);
      chunk.write(2, 5); // Line jumps back
      chunk.write(3, 15);
      
      expect(chunk.lines, [1, 10, 1, 5, 1, 15]);
      expect(chunk.getLine(0), 10);
      expect(chunk.getLine(1), 5);
      expect(chunk.getLine(2), 15);
    });
  });
}
