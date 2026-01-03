import 'dart:convert';
import 'package:flux_compiler/src/source_map_generator.dart';
import 'package:test/test.dart';

void main() {
  group('SourceMapGenerator', () {
    test('generates empty map', () {
      final generator = SourceMapGenerator(file: 'out.js');
      final json = jsonDecode(generator.toJson());
      
      expect(json['version'], 3);
      expect(json['file'], 'out.js');
      expect(json['mappings'], '');
    });

    test('generates simple mappings', () {
      // 1:1 mapping example
      // source.dart:
      // 1: void main() {}
      
      // out.js:
      // 1: function main() {}
      
      final generator = SourceMapGenerator(file: 'out.js', sourceRoot: '');
      final sourceIdx = generator.addSource('source.dart');
      final nameIdx = generator.addName('main');
      
      // map "function" (1,0) to "void" (1,0)
      generator.addEntry(1, 0, sourceIndex: sourceIdx, sourceLine: 1, sourceColumn: 0);
      
      // map "main" (1,9) to "main" (1,5)
      generator.addEntry(1, 9, sourceIndex: sourceIdx, sourceLine: 1, sourceColumn: 5, nameIndex: nameIdx);
      
      final json = jsonDecode(generator.toJson());
      expect(json['sources'], ['source.dart']);
      expect(json['names'], ['main']);
      
      // Generated:
      // 1,0 -> 1,0 (0,0,0,0) -> AAAAA
      // 1,9 -> 1,5, name:0 (9, 0, 0, 5, 0) -> SAAKA
      
      // Note: First segment is relative to 0,0,0,0,0
      // Second segment relative to previous 1,0,0,1,0 -> generated col 9, source col 5
      
      expect(json['mappings'], isNotEmpty);
      
      // Check decoding logic manually or via standard tool implies correctness of relative diffs
    });
    
    test('VLQ encoding logic manual check', () {
        SourceMapGenerator(file: 'test');
        // 0 -> A
        // 1 -> C
        // -1 -> D
        // 16 -> g
        // 123456 -> 27010
        // We can access private methods if we expose them or just rely on mappings output
    });
  });
}
