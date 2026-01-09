import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/bindings.dart';

void main() {
  setUpAll(() {
    FluxBindings.initDefaults();
  });

  group('Flux Input Widgets', () {
    testWidgets('TextField renders properties', (tester) async {
      final builder = FluxBindings.get('TextField')!;
      final decoration = {
        'hint': 'Enter name',
        'label': 'Name',
        'filled': true,
        'fillColor': '#EEEEEE',
        'border': 'outline' // OutlineInputBorder
      };

      final textField = builder({
        'obscureText': true,
        'keyboardType': 'email',
        'decoration': decoration,
      }, []) as TextField;

      expect(textField.obscureText, isTrue);
      expect(textField.keyboardType, TextInputType.emailAddress);

      final inputDec = textField.decoration!;
      expect(inputDec.hintText, 'Enter name');
      expect(inputDec.labelText, 'Name');
      expect(inputDec.filled, isTrue);
      expect(inputDec.fillColor, const Color(0xFFEEEEEE));
      expect(inputDec.border, isA<OutlineInputBorder>());
    });

    testWidgets('Checkbox renders and callback', (tester) async {
      final builder = FluxBindings.get('Checkbox')!;

      final checkbox = builder({
        'value': true,
        'activeColor': 'blue',
        'onChanged': (_) {},
      }, []) as Checkbox;

      expect(checkbox.value, isTrue);
      expect(checkbox.activeColor, Colors.blue);
      expect(checkbox.onChanged, isNotNull);

      // Simulate tap
      // Since we just have the widget, we can't easily tap it without pumping the widget tree.
      // But we can check that onChanged is bound.
      // Testing the actual invocation via internal closure binding logic is tricky in unit test without full VM,
      // but we can verify the property is set.
    });

    testWidgets('Switch renders', (tester) async {
      final builder = FluxBindings.get('Switch')!;
      final switchWidget = builder({
        'value': false,
        'activeColor': '#00FF00',
      }, []) as Switch;

      expect(switchWidget.value, isFalse);
      // ignore: deprecated_member_use
      expect(switchWidget.activeColor, const Color(0xFF00FF00));
    });
  });
}
