import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/bindings.dart';

void main() {
  setUpAll(() {
    FluxBindings.initDefaults();
  });

  group('Flux Text Style', () {
    testWidgets('renders primitive Text without style', (tester) async {
      final builder = FluxBindings.get('Text')!;
      final textWidget = builder({'text': 'Hello'}, []) as Text;
      
      expect(textWidget.data, 'Hello');
      expect(textWidget.style, isNull);
    });

    testWidgets('renders Text with full style', (tester) async {
      final builder = FluxBindings.get('Text')!;
      final style = {
        'color': 'red',
        'fontSize': 24,
        'fontWeight': 'bold',
        'fontStyle': 'italic',
      };
      
      final textWidget = builder({'text': 'Styled', 'style': style}, []) as Text;
      
      expect(textWidget.data, 'Styled');
      expect(textWidget.style, isNotNull);
      expect(textWidget.style!.color, Colors.red);
      expect(textWidget.style!.fontSize, 24.0);
      expect(textWidget.style!.fontWeight, FontWeight.bold);
      expect(textWidget.style!.fontStyle, FontStyle.italic);
    });

    testWidgets('renders Text with numeric fontWeight', (tester) async {
      final builder = FluxBindings.get('Text')!;
      final style = {
        'fontWeight': 100,
      };
      
      final textWidget = builder({'text': 'Thin', 'style': style}, []) as Text;
      expect(textWidget.style!.fontWeight, FontWeight.w100);
    });

    testWidgets('handles nested hex color in style', (tester) async {
      final builder = FluxBindings.get('Text')!;
      final style = {
        'color': '#00FF00',
      };
      
      final textWidget = builder({'text': 'Green', 'style': style}, []) as Text;
      expect(textWidget.style!.color, const Color(0xFF00FF00));
    });

    testWidgets('gracefully handles invalid style', (tester) async {
       final builder = FluxBindings.get('Text')!;
       // Non-map style should be ignored or result in null
       final textWidget = builder({'text': 'Bad Style', 'style': 'not-a-map'}, []) as Text;
       expect(textWidget.style, isNull);
    });
  });
}
