import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/bindings.dart';

void main() {
  setUpAll(() {
    FluxBindings.initDefaults();
  });

  group('Flux Decoration & EdgeInsets', () {
    testWidgets('renders Container with simple padding (numeric)',
        (tester) async {
      final builder = FluxBindings.get('Container')!;
      final container = builder({'padding': 20}, []) as Container;

      expect(container.padding, const EdgeInsets.all(20.0));
    });

    testWidgets('renders Container with complex padding (map)', (tester) async {
      final builder = FluxBindings.get('Container')!;
      final paddingMap = {
        'top': 10,
        'horizontal': 20,
      };
      // top: 10, bottom: 0 (default), left: 20, right: 20
      final container = builder({'padding': paddingMap}, []) as Container;

      final insets = container.padding as EdgeInsets;
      expect(insets.top, 10.0);
      expect(insets.bottom, 0.0);
      expect(insets.left, 20.0);
      expect(insets.right, 20.0);
    });

    testWidgets('renders Container with BoxDecoration (color)', (tester) async {
      final builder = FluxBindings.get('Container')!;
      final decoration = {
        'color': '#FF0000',
      };

      final container = builder({'decoration': decoration}, []) as Container;
      final boxDecoration = container.decoration as BoxDecoration;
      expect(boxDecoration.color, const Color(0xFFFF0000));
    });

    testWidgets('renders Container with BoxDecoration (border & radius)',
        (tester) async {
      final builder = FluxBindings.get('Container')!;
      final decoration = {
        'borderRadius': 8,
        'border': {
          'color': 'black',
          'width': 2,
        }
      };

      final container = builder({'decoration': decoration}, []) as Container;
      final boxDecoration = container.decoration as BoxDecoration;

      expect(boxDecoration.borderRadius, BorderRadius.circular(8.0));
      expect(boxDecoration.border, isA<Border>());
      final border = boxDecoration.border as Border;
      expect(border.top.width, 2.0);
      expect(border.top.color, Colors.black);
    });

    testWidgets('renders Container with Margin', (tester) async {
      final builder = FluxBindings.get('Container')!;
      final container = builder({'margin': 15}, []) as Container;
      expect(container.margin, const EdgeInsets.all(15.0));
    });
  });
}
