import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sanity Check: Can actually run widget tests', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Sanity Passed'),
        ),
      ),
    );
    expect(find.text('Sanity Passed'), findsOneWidget);
    print('✅ Sanity Check Passed');
  });
}
