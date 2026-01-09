import 'package:test/test.dart';
import 'package:flux_lsp/flux_lsp.dart';

void main() {
  group('FluxAnalyzer', () {
    late FluxAnalyzer analyzer;

    setUp(() {
      analyzer = FluxAnalyzer();
    });

    group('analyze', () {
      test('returns empty diagnostics for valid code', () {
        final source = '''
          fn main() {
            var x = 1;
            print(x);
          }
        ''';

        final result = analyzer.analyze(source, 'file:///test.flux');

        expect(result.ast, isNotNull);
        expect(result.diagnostics, isEmpty);
      });

      test('returns diagnostics for syntax errors', () {
        final source = '''
          fn main() {
            var x = ;
          }
        ''';

        final result = analyzer.analyze(source, 'file:///test.flux');

        expect(result.diagnostics, isNotEmpty);
        expect(result.diagnostics.first.severity,
            equals(DiagnosticSeverity.error));
      });
    });

    group('getHover', () {
      test('returns documentation for widget keyword', () {
        final source = 'widget MyWidget {}';
        final hover = analyzer.getHover(source, Position(0, 0));

        expect(hover, isNotNull);
        expect(hover!.contents, contains('Widget Declaration'));
      });

      test('returns documentation for fn keyword', () {
        final source = 'fn main() {}';
        final hover = analyzer.getHover(source, Position(0, 0));

        expect(hover, isNotNull);
        expect(hover!.contents, contains('Function Declaration'));
      });

      test('returns documentation for built-in Widget', () {
        final source = 'Column {}';
        final hover = analyzer.getHover(source, Position(0, 0));

        expect(hover, isNotNull);
        expect(hover!.contents, contains('Vertical Layout'));
      });

      test('returns null for unknown identifier', () {
        final source = 'unknownIdentifier';
        final hover = analyzer.getHover(source, Position(0, 0));

        expect(hover, isNull);
      });
    });
  });

  group('Protocol Types', () {
    test('Position serialization', () {
      final pos = Position(5, 10);
      final json = pos.toJson();

      expect(json['line'], equals(5));
      expect(json['character'], equals(10));
    });

    test('Range serialization', () {
      final range = Range(Position(1, 0), Position(1, 5));
      final json = range.toJson();

      expect(json['start']['line'], equals(1));
      expect(json['end']['character'], equals(5));
    });

    test('Diagnostic serialization', () {
      final diag = Diagnostic(
        range: Range(Position(0, 0), Position(0, 1)),
        severity: DiagnosticSeverity.error,
        message: 'Test error',
        source: 'flux',
      );
      final json = diag.toJson();

      expect(json['severity'], equals(1));
      expect(json['message'], equals('Test error'));
      expect(json['source'], equals('flux'));
    });

    test('CompletionItem serialization', () {
      final item = CompletionItem(
        label: 'widget',
        kind: CompletionItemKind.keyword,
        detail: 'Flux keyword',
      );
      final json = item.toJson();

      expect(json['label'], equals('widget'));
      expect(json['kind'], equals(CompletionItemKind.keyword));
    });

    test('Hover serialization', () {
      final hover = Hover(contents: '**Test** documentation');
      final json = hover.toJson();

      expect(json['contents']['kind'], equals('markdown'));
      expect(json['contents']['value'], contains('Test'));
    });
  });
}
