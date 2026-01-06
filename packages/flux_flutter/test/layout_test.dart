import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/bindings.dart';

void main() {
  setUpAll(() {
    FluxBindings.initDefaults();
  });

  group('Flux Layout Widgets', () {
    testWidgets('renders Stack with Alignment', (tester) async {
      final builder = FluxBindings.get('Stack')!;
      final stack = builder({'alignment': 'center'}, []) as Stack;
      expect(stack.alignment, Alignment.center);
    });

    testWidgets('renders Positioned with props', (tester) async {
      final builder = FluxBindings.get('Positioned')!;
      final positioned =
          builder({'left': 10, 'top': 20, 'width': 100, 'height': 50}, [])
              as Positioned;

      expect(positioned.left, 10.0);
      expect(positioned.top, 20.0);
      expect(positioned.width, 100.0);
      expect(positioned.height, 50.0);
    });

    testWidgets('renders Wrap with spacing and direction', (tester) async {
      final builder = FluxBindings.get('Wrap')!;
      final wrap = builder({
        'direction': 'vertical',
        'spacing': 16,
        'runSpacing': 8,
        'alignment': 'center',
      }, []) as Wrap;

      expect(wrap.direction, Axis.vertical);
      expect(wrap.spacing, 16.0);
      expect(wrap.runSpacing, 8.0);
      expect(wrap.alignment, WrapAlignment.center);
    });

    testWidgets('Wrap defaults', (tester) async {
      final builder = FluxBindings.get('Wrap')!;
      final wrap = builder({}, []) as Wrap;

      expect(wrap.direction, Axis.horizontal);
      expect(wrap.spacing, 0.0);
      expect(wrap.runSpacing, 0.0);
      expect(wrap.alignment, WrapAlignment.start);
    });
  });
}
