import 'package:test/test.dart';
import 'package:flux_lsp/src/analysis.dart';
import 'package:flux_lsp/src/protocol.dart';

void main() {
  group('Advanced LSP Analysis', () {
    late FluxAnalyzer analyzer;
    const uri = 'file:///test.flux';

    setUp(() {
      analyzer = FluxAnalyzer();
    });

    // Helper to find position of a pattern in source
    Position posOf(String source, String pattern, {bool end = false}) {
      final index = source.indexOf(pattern);
      if (index == -1) throw 'Pattern not found: \$pattern';

      final prefix = source.substring(0, index + (end ? pattern.length : 0));
      final lines = prefix.split('\n');
      final line = lines.length - 1;
      final col = lines.last.length;

      return Position(line, col);
    }

    test('Go to Definition - Local Variable', () {
      final source = 'fn main() {\n  var x = 10;\n  print(x);\n}';
      analyzer.analyze(source, uri);

      // Cursor on 'x' in print(x)
      final pos = posOf(source, 'x);');
      final def = analyzer.getDefinition(source, uri, pos);

      expect(def, isNotNull, reason: 'Definition should be found for x');
      expect(def!.uri, uri);

      // Expected definition at 'var x'
      final expectedPos = posOf(source, 'x = 10;');
      expect(def.range.start.line, expectedPos.line);
      expect(def.range.start.character, expectedPos.character);
    });

    test('Go to Definition - Function Parameter', () {
      final source = 'fn greet(name) {\n  print(name);\n}';
      analyzer.analyze(source, uri);

      // Cursor on 'name' in print(name)
      final pos = posOf(source, 'name);');
      final def = analyzer.getDefinition(source, uri, pos);

      expect(def, isNotNull);

      // Expected definition at 'name) {'
      final expectedPos = posOf(source, 'name) {');
      expect(def!.range.start.line, expectedPos.line);
      expect(def.range.start.character, expectedPos.character);
    });

    test('Go to Definition - Shadowing', () {
      final source =
          'var x = 1;\nfn main() {\n  var x = 2; // Shadowing\n  print(x);\n}';
      analyzer.analyze(source, uri);

      // Cursor on 'x' in print(x)
      final pos = posOf(source, 'x);');
      final def = analyzer.getDefinition(source, uri, pos);

      expect(def, isNotNull);

      // Should point to inner x (x = 2)
      final innerDecl = posOf(source, 'x = 2;');
      expect(def!.range.start.line, innerDecl.line);
      expect(def.range.start.character, innerDecl.character);
    });

    test('Find References - Local Variable', () {
      final source =
          'fn main() {\n  var count = 0;\n  count = count + 1;\n  print(count);\n}';
      analyzer.analyze(source, uri);

      // Cursor on 'var count'
      final pos = posOf(source, 'count = 0;');
      final refs = analyzer.getReferences(source, uri, pos);

      expect(refs, isNotNull);
      // count = 0 (def), count = (assign), = count (val), print(count)
      expect(refs!.length, 4);

      // Verify definition (line 1, col 6)
      expect(refs[0].range.start.line, 1);
      expect(refs[0].range.start.character, 6);

      // 2. Assignment target (count =)
      final assignRef = posOf(source, 'count = count');
      expect(
          refs.any((l) =>
              l.range.start.line == assignRef.line &&
              l.range.start.character == assignRef.character),
          isTrue);
    });
  });
}
