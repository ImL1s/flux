import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart'; // Ensure this points to the new main.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Flux Showcase Dashboard Navigation & Storage Test', (WidgetTester tester) async {
    // 1. Load the Showcase App
    await tester.pumpWidget(const ProviderScope(child: FluxShowcaseApp()));
    await tester.pumpAndSettle();

    // 3. Navigate to Language Demo
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    // 4. Verify Language View
    expect(find.text('Flux Language Benchmarks'), findsOneWidget);
    expect(find.textContaining('Ready to run.'), findsOneWidget);

    // 5. Interact
    await tester.tap(find.text('String Operations'));
    await tester.pumpAndSettle();
    
    // 6. Verify Update
    expect(find.textContaining('Concatenated 1000 dots'), findsOneWidget);
    
    // 7. Verify Back Navigation
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    
    expect(find.text('Flux Gallery'), findsOneWidget);
  });
}
