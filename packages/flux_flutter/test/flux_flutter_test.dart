import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/flux_flutter.dart';

void main() {
  group('FluxBindings', () {
    setUp(() {
      FluxBindings.initDefaults();
    });

    test('registers default bindings', () {
      expect(FluxBindings.get('Text'), isNotNull);
      expect(FluxBindings.get('Column'), isNotNull);
      expect(FluxBindings.get('Row'), isNotNull);
      expect(FluxBindings.get('Button'), isNotNull);
    });

    test('returns null for unknown widget', () {
      expect(FluxBindings.get('UnknownWidget'), isNull);
    });
  });
}
